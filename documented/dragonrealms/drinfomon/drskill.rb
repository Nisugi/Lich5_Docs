module Lich
  module DragonRealms
    # Represents a skill in the DragonRealms game.
    # This class manages skill data, including experience and rank.
    # @example Creating a new skill
    #   skill = Lich::DragonRealms::DRSkill.new("Evasion", 10, 100, 50)
    class DRSkill
      @@skills_data ||= DR_SKILLS_DATA
      @@gained_skills ||= []
      @@start_time ||= Time.now
      @@list ||= []
      @@exp_modifiers ||= {}

      attr_reader :name, :skillset
      attr_accessor :rank, :exp, :percent, :current, :baseline

      # Initializes a new DRSkill instance.
      # @param name [String] The name of the skill.
      # @param rank [Integer] The earned ranks in the skill.
      # @param exp [Integer] The experience points for the skill.
      # @param percent [Integer] The percentage to the next rank (0 to 100).
      # @return [DRSkill]
      # @note Skills are capped at 34 ranks.
      def initialize(name, rank, exp, percent)
        @name = name # skill name like 'Evasion'
        @rank = rank.to_i # earned ranks in the skill
        # Skill mindstate x/34
        # Hardcode caped skills to 34/34
        @exp = rank.to_i >= 1750 ? 34 : exp.to_i
        @percent = percent.to_i # percent to next rank from 0 to 100
        @baseline = rank.to_i + (percent.to_i / 100.0)
        @current = rank.to_i + (percent.to_i / 100.0)
        @skillset = lookup_skillset(@name)
        @@list.push(self) unless @@list.find { |skill| skill.name == @name }
      end

      # Resets the gained skills and start time.
      # This method is used to clear the current session's skill data.
      def self.reset
        @@gained_skills = []
        @@start_time = Time.now
        @@list.each { |skill| skill.baseline = skill.current }
      end

      # Primarily used by `learned` script to track how long it's
      # been tracking your experience gains this session.
      # Returns the start time of the current session.
      # @return [Time] The time when tracking started.
      def self.start_time
        @@start_time
      end

      # List of skills that have increased their learning rates.
      # Primarily used by `exp-monitor` script to echo which skills
      # gained experience after you performed an action.
      # Returns the list of skills that have increased their learning rates.
      # @return [Array<Hash>] An array of hashes containing skill names and their experience changes.
      def self.gained_skills
        @@gained_skills
      end

      # Returns the amount of ranks that have been gained since
      # the baseline was last reset. This allows you to track
      # rank gain for a given play session.
      #
      # Note, don't confuse the 'exp' in this method name with DRSkill.getxp(..)
      # which returns the current learning rate of the skill.
      # Returns the amount of ranks gained since the last reset.
      # @param val [String] The name of the skill.
      # @return [Float] The amount of ranks gained.
      # @note This method should not be confused with DRSkill.getxp(..) which returns the current learning rate.
      def self.gained_exp(val)
        skill = self.find_skill(val)
        if skill
          return skill.current ? (skill.current - skill.baseline).round(2) : 0.00
        end
      end

      # Updates DRStats.gained_skills if the learning rate increased.
      # The original consumer of this data is the `exp-monitor` script.
      # Updates gained skills if the learning rate increased.
      # @param name [String] The name of the skill.
      # @param new_exp [Integer] The new experience value.
      # @return [void]
      def self.handle_exp_change(name, new_exp)
        return unless UserVars.echo_exp

        old_exp = DRSkill.getxp(name)
        change = new_exp.to_i - old_exp.to_i
        if change > 0
          DRSkill.gained_skills << { skill: name, change: change }
        end
      end

      # Checks if a skill exists in the list.
      # @param val [String] The name of the skill.
      # @return [Boolean] True if the skill exists, false otherwise.
      def self.include?(val)
        !self.find_skill(val).nil?
      end

      # Updates the skill's rank, experience, and percentage.
      # @param name [String] The name of the skill.
      # @param rank [Integer] The new rank of the skill.
      # @param exp [Integer] The new experience points.
      # @param percent [Integer] The new percentage to the next rank.
      # @return [void]
      def self.update(name, rank, exp, percent)
        self.handle_exp_change(name, exp)
        skill = self.find_skill(name)
        if skill
          skill.rank = rank.to_i
          skill.exp = skill.rank.to_i >= 1750 ? 34 : exp.to_i
          skill.percent = percent.to_i
          skill.current = rank.to_i + (percent.to_i / 100.0)
        else
          DRSkill.new(name, rank, exp, percent)
        end
      end

      # Updates the experience modifiers for a skill.
      # @param name [String] The name of the skill.
      # @param rank [Integer] The new rank to set as a modifier.
      # @return [void]
      def self.update_mods(name, rank)
        self.exp_modifiers[self.lookup_alias(name)] = rank.to_i
      end

      # Returns the current experience modifiers.
      # @return [Hash] A hash of skill names and their corresponding modifiers.
      def self.exp_modifiers
        @@exp_modifiers
      end

      # Resets the experience of a skill to zero.
      # @param val [String] The name of the skill.
      # @return [void]
      def self.clear_mind(val)
        self.find_skill(val).exp = 0
      end

      # Returns the rank of a specified skill.
      # @param val [String] The name of the skill.
      # @return [Integer] The rank of the skill.
      def self.getrank(val)
        self.find_skill(val).rank.to_i
      end

      # Returns the modified rank of a specified skill, including any modifiers.
      # @param val [String] The name of the skill.
      # @return [Integer] The modified rank of the skill.
      def self.getmodrank(val)
        skill = self.find_skill(val)
        if skill
          rank = skill.rank.to_i
          modifier = self.exp_modifiers[skill.name].to_i
          rank + modifier
        end
      end

      # Returns the experience points of a specified skill.
      # @param val [String] The name of the skill.
      # @return [Integer] The experience points of the skill.
      def self.getxp(val)
        skill = self.find_skill(val)
        skill.exp.to_i
      end

      # Returns the percentage to the next rank for a specified skill.
      # @param val [String] The name of the skill.
      # @return [Integer] The percentage to the next rank.
      def self.getpercent(val)
        self.find_skill(val).percent.to_i
      end

      # Returns the skillset associated with a specified skill.
      # @param val [String] The name of the skill.
      # @return [String] The skillset of the skill.
      def self.getskillset(val)
        self.find_skill(val).skillset
      end

      # Lists all skills with their ranks and experience.
      # @return [void]
      def self.listall
        @@list.each do |i|
          echo "#{i.name}: #{i.rank}.#{i.percent}% [#{i.exp}/34]"
        end
      end

      # Returns the list of all skills.
      # @return [Array<DRSkill>] An array of all DRSkill instances.
      def self.list
        @@list
      end

      # Finds a skill by its name.
      # @param val [String] The name of the skill.
      # @return [DRSkill, nil] The DRSkill instance if found, nil otherwise.
      def self.find_skill(val)
        @@list.find { |data| data.name == self.lookup_alias(val) }
      end

      # Some guilds rename skills, like Barbarians call "Primary Magic" as "Inner Fire".
      # Given the canonical or colloquial name, this method returns the value
      # that's usable with the other methods like `getxp(skill)` and `getrank(skill)`.
      # Looks up the alias for a skill based on the guild.
      # @param skill [String] The name of the skill.
      # @return [String] The canonical name of the skill.
      def self.lookup_alias(skill)
        @@skills_data[:guild_skill_aliases][DRStats.guild][skill] || skill
      end

      # This is an instance method, do not prefix with `self`.
      # It is called from the initialize method (constructor).
      # When it was defined as a class method then the initialize method
      # complained that this method didn't yet exist.
      # Looks up the skillset for an instance's skill.
      # @param skill [String] The name of the skill.
      # @return [String] The skillset associated with the skill.
      def lookup_skillset(skill)
        @@skills_data[:skillsets].find { |_skillset, skills| skills.include?(skill) }.first
      end
    end
  end
end
