module Lich
  module Gemstone
    # Represents a spellsong in the Lich5 project.
    # This class manages the duration and effects of bard spells.
    # @example Creating a spellsong
    #   Lich::Gemstone::Spellsong.sync
    class Spellsong
      # The last renewed time for the spellsong.
      @@renewed ||= 0.to_f
      # The default duration of the spellsong in seconds.
      @@song_duration ||= 120.to_f
      # Stores the last calculated duration parameters.
      @@duration_calcs ||= []

      # Synchronizes the spellsong duration based on active bard spells.
      # @return [String] A message indicating the status of the synchronization.
      # @raise [StandardError] If no active bard spells are found.
      # @example
      #   Lich::Gemstone::Spellsong.sync
      def self.sync
        timed_spell = Effects::Spells.to_h.keys.find { |k| k.to_s.match(/10[0-9][0-9]/) }
        return 'No active bard spells' if timed_spell.nil?
        @@renewed = Time.at(Time.now.to_f - self.timeleft.to_f + (Effects::Spells.time_left(timed_spell) * 60.to_f)) # duration
      end

      # Updates the renewed time to the current time.
      # @return [Time] The updated renewed time.
      # @example
      #   Lich::Gemstone::Spellsong.renewed
      def self.renewed
        @@renewed = Time.now
      end

      # Sets the renewed time to a specified value.
      # @param val [Time] The new renewed time.
      # @return [Time] The updated renewed time.
      # @example
      #   Lich::Gemstone::Spellsong.renewed = Time.now
      def self.renewed=(val)
        @@renewed = val
      end

      # Returns the last renewed time.
      # @return [Time] The last renewed time.
      # @example
      #   Lich::Gemstone::Spellsong.renewed_at
      def self.renewed_at
        @@renewed
      end

      # Calculates the remaining time left for the spellsong.
      # @return [Float] The time left in minutes.
      # @raise [StandardError] If the profession is not Bard.
      # @example
      #   Lich::Gemstone::Spellsong.timeleft
      def self.timeleft
        return 0.0 if Stats.prof != 'Bard'
        (self.duration - ((Time.now.to_f - @@renewed.to_f) % self.duration)) / 60.to_f
      end

      # Serializes the current state of the spellsong.
      # @return [Float] The time left for the spellsong.
      # @example
      #   Lich::Gemstone::Spellsong.serialize
      def self.serialize
        self.timeleft
      end

      # Calculates the duration of the spellsong based on various stats.
      # @return [Float] The duration of the spellsong in seconds.
      # @example
      #   Lich::Gemstone::Spellsong.duration
      def self.duration
        return @@song_duration if @@duration_calcs == [Stats.level, Stats.log[1], Stats.inf[1], Skills.mltelepathy]
        return @@song_duration if [Stats.level, Stats.log[1], Stats.inf[1], Skills.mltelepathy].include?(nil)
        @@duration_calcs = [Stats.level, Stats.log[1], Stats.inf[1], Skills.mltelepathy]
        total = self.duration_base_level(Stats.level)
        return (@@song_duration = total + Stats.log[1] + (Stats.inf[1] * 3) + (Skills.mltelepathy * 2))
      end

      # Calculates the base duration of the spellsong based on the level.
      # @param level [Integer] The level of the bard.
      # @return [Integer] The base duration in seconds.
      # @example
      #   Lich::Gemstone::Spellsong.duration_base_level(50)
      def self.duration_base_level(level = Stats.level)
        total = 120
        case level
        when (0..25)
          total += level * 4
        when (26..50)
          total += 100 + (level - 25) * 3
        when (51..75)
          total += 175 + (level - 50) * 2
        when (76..100)
          total += 225 + (level - 75)
        else
          Lich.log("unhandled case in Spellsong.duration level=#{level}")
        end
        return total
      end

      # Calculates the total renewal cost for active spellsongs.
      # @return [Integer] The total renewal cost.
      # @example
      #   Lich::Gemstone::Spellsong.renew_cost
      def self.renew_cost
        # fixme: multi-spell penalty?
        total = num_active = 0
        [1003, 1006, 1009, 1010, 1012, 1014, 1018, 1019, 1025].each { |song_num|
          if (song = Spell[song_num])
            if song.active?
              total += song.renew_cost
              num_active += 1
            end
          else
            echo "self.renew_cost: warning: can't find song number #{song_num}"
          end
        }
        return total
      end

      # Calculates the durability of the sonic armor.
      # @return [Integer] The durability value.
      # @example
      #   Lich::Gemstone::Spellsong.sonicarmordurability
      def self.sonicarmordurability
        210 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
      end

      # Calculates the durability of the sonic blade.
      # @return [Integer] The durability value.
      # @example
      #   Lich::Gemstone::Spellsong.sonicbladedurability
      def self.sonicbladedurability
        160 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
      end

      # Returns the durability of the sonic weapon.
      # @return [Integer] The durability value.
      # @example
      #   Lich::Gemstone::Spellsong.sonicweapondurability
      def self.sonicweapondurability
        self.sonicbladedurability
      end

      # Calculates the durability of the sonic shield.
      # @return [Integer] The durability value.
      # @example
      #   Lich::Gemstone::Spellsong.sonicshielddurability
      def self.sonicshielddurability
        125 + (Stats.level / 2).round + Skills.to_bonus(Skills.elair)
      end

      # Calculates the haste bonus for the tonis spell.
      # @return [Integer] The haste bonus value.
      # @example
      #   Lich::Gemstone::Spellsong.tonishastebonus
      def self.tonishastebonus
        bonus = -1
        thresholds = [30, 75]
        thresholds.each { |val| if Skills.elair >= val then bonus -= 1 end }
        bonus
      end

      # Calculates the push down value for depression.
      # @return [Integer] The push down value.
      # @example
      #   Lich::Gemstone::Spellsong.depressionpushdown
      def self.depressionpushdown
        20 + Skills.mltelepathy
      end

      # Calculates the slow value for depression.
      # @return [Integer] The slow value.
      # @example
      #   Lich::Gemstone::Spellsong.depressionslow
      def self.depressionslow
        thresholds = [10, 25, 45, 70, 100]
        bonus = -2
        thresholds.each { |val| if Skills.mltelepathy >= val then bonus -= 1 end }
        bonus
      end

      # Calculates the number of targets that can be held.
      # @return [Integer] The number of holding targets.
      # @example
      #   Lich::Gemstone::Spellsong.holdingtargets
      def self.holdingtargets
        1 + ((Spells.bard - 1) / 7).truncate
      end

      # Returns the cost of renewing the spellsong.
      # @return [Integer] The renewal cost.
      # @example
      #   Lich::Gemstone::Spellsong.cost
      def self.cost
        self.renew_cost
      end

      # Calculates the dodge bonus for the tonis spell.
      # @return [Integer] The dodge bonus value.
      # @example
      #   Lich::Gemstone::Spellsong.tonisdodgebonus
      def self.tonisdodgebonus
        thresholds = [1, 2, 3, 5, 8, 10, 14, 17, 21, 26, 31, 36, 42, 49, 55, 63, 70, 78, 87, 96]
        bonus = 20
        thresholds.each { |val| if Skills.elair >= val then bonus += 1 end }
        bonus
      end

      # Calculates the dodge bonus for the mirrors spell.
      # @return [Integer] The dodge bonus value.
      # @example
      #   Lich::Gemstone::Spellsong.mirrorsdodgebonus
      def self.mirrorsdodgebonus
        20 + ((Spells.bard - 19) / 2).round
      end

      # Calculates the cost for the mirrors spell.
      # @return [Array<Integer>] The cost values.
      # @example
      #   Lich::Gemstone::Spellsong.mirrorscost
      def self.mirrorscost
        [19 + ((Spells.bard - 19) / 5).truncate, 8 + ((Spells.bard - 19) / 10).truncate]
      end

      # Calculates the sonic bonus based on bard level.
      # @return [Integer] The sonic bonus value.
      # @example
      #   Lich::Gemstone::Spellsong.sonicbonus
      def self.sonicbonus
        (Spells.bard / 2).round
      end

      # Calculates the sonic armor bonus.
      # @return [Integer] The sonic armor bonus value.
      # @example
      #   Lich::Gemstone::Spellsong.sonicarmorbonus
      def self.sonicarmorbonus
        self.sonicbonus + 15
      end

      # Calculates the sonic blade bonus.
      # @return [Integer] The sonic blade bonus value.
      # @example
      #   Lich::Gemstone::Spellsong.sonicbladebonus
      def self.sonicbladebonus
        self.sonicbonus + 10
      end

      # Returns the sonic weapon bonus.
      # @return [Integer] The sonic weapon bonus value.
      # @example
      #   Lich::Gemstone::Spellsong.sonicweaponbonus
      def self.sonicweaponbonus
        self.sonicbladebonus
      end

      # Calculates the sonic shield bonus.
      # @return [Integer] The sonic shield bonus value.
      # @example
      #   Lich::Gemstone::Spellsong.sonicshieldbonus
      def self.sonicshieldbonus
        self.sonicbonus + 10
      end

      # Calculates the valor bonus based on bard level.
      # @return [Integer] The valor bonus value.
      # @example
      #   Lich::Gemstone::Spellsong.valorbonus
      def self.valorbonus
        10 + (([Spells.bard, Stats.level].min - 10) / 2).round
      end

      # Calculates the cost for the valor spell.
      # @return [Array<Integer>] The cost values.
      # @example
      #   Lich::Gemstone::Spellsong.valorcost
      def self.valorcost
        [10 + (self.valorbonus / 2), 3 + (self.valorbonus / 5)]
      end

      # Calculates the cost for the luck spell.
      # @return [Array<Integer>] The cost values.
      # @example
      #   Lich::Gemstone::Spellsong.luckcost
      def self.luckcost
        [6 + ((Spells.bard - 6) / 4), (6 + ((Spells.bard - 6) / 4) / 2).round]
      end

      # Returns the mana cost for spells.
      # @return [Array<Integer>] The mana cost values.
      # @example
      #   Lich::Gemstone::Spellsong.manacost
      def self.manacost
        [18, 15]
      end

      # Returns the fortitude cost for spells.
      # @return [Array<Integer>] The fortitude cost values.
      # @example
      #   Lich::Gemstone::Spellsong.fortcost
      def self.fortcost
        [3, 1]
      end

      # Returns the shield cost for spells.
      # @return [Array<Integer>] The shield cost values.
      # @example
      #   Lich::Gemstone::Spellsong.shieldcost
      def self.shieldcost
        [9, 4]
      end

      # Returns the weapon cost for spells.
      # @return [Array<Integer>] The weapon cost values.
      # @example
      #   Lich::Gemstone::Spellsong.weaponcost
      def self.weaponcost
        [12, 4]
      end

      # Returns the armor cost for spells.
      # @return [Array<Integer>] The armor cost values.
      # @example
      #   Lich::Gemstone::Spellsong.armorcost
      def self.armorcost
        [14, 5]
      end

      # Returns the sword cost for spells.
      # @return [Array<Integer>] The sword cost values.
      # @example
      #   Lich::Gemstone::Spellsong.swordcost
      def self.swordcost
        [25, 15]
      end
    end
  end
end
