module Lich
  module Gemstone
    # Represents a list of items to stow in the Lich game.
    # This class manages the stow list and provides methods to check,
    # reset, and validate the stow targets.
    # @example
    #   Lich::Gemstone::StowList.checked = true
    #   Lich::Gemstone::StowList.check
    class StowList
      @checked = false

      # The original list of stowable item types.
      ORIGINAL_STOW_LIST = [:box, :gem, :herb, :skin, :wand, :scroll, :potion, :trinket, :reagent, :lockpick, :treasure, :forageable, :collectible, :default]

      @stow_list = {
        box: nil,
        gem: nil,
        herb: nil,
        skin: nil,
        wand: nil,
        scroll: nil,
        potion: nil,
        trinket: nil,
        reagent: nil,
        lockpick: nil,
        treasure: nil,
        forageable: nil,
        collectible: nil,
        default: nil
      }

      # Define class-level accessors for stow list entries
      @stow_list.each_key do |type|
        define_singleton_method(type) { @stow_list[type] }
        define_singleton_method("#{type}=") { |value| @stow_list[type] = value }
      end

      class << self
        # Returns the current stow list.
        # @return [Hash] The stow list with item types as keys and their values.
        def stow_list
          @stow_list
        end

        # Checks if the stow list has been validated.
        # @return [Boolean] True if the stow list has been checked, false otherwise.
        def checked?
          @checked
        end

        # Sets the checked status of the stow list.
        # @param value [Boolean] The new checked status.
        # @return [Boolean] The updated checked status.
        def checked=(value)
          @checked = value
        end

        # Validates the stow list entries.
        # @param all [Boolean] If true, checks all entries; otherwise, only checks original stow list.
        # @return [Boolean] True if all checked entries are valid, false otherwise.
        # @note This method requires that the stow list has been checked.
        def valid?(all: false)
          # check if existing containers are valid or not
          return false unless checked?
          @stow_list.each do |key, value|
            next unless all || ORIGINAL_STOW_LIST.include?(key)
            unless value.nil? || GameObj.inv.map(&:id).include?(value.id)
              @checked = false
              return false
            end
          end
          return true
        end

        # Resets the stow list entries to nil.
        # @param all [Boolean] If true, resets all entries; otherwise, only resets original stow list.
        def reset(all: false)
          @checked = false
          @stow_list.each do |key, _value|
            next unless all || ORIGINAL_STOW_LIST.include?(key)
            @stow_list[key] = nil
          end
        end

        # Checks the stow list and updates the checked status.
        # @param silent [Boolean] If true, suppresses output.
        # @param quiet [Boolean] If true, uses a quiet output pattern.
        # @return [void]
        # @example
        #   Lich::Gemstone::StowList.check(silent: true)
        # @note This method will set the checked status to true after execution.
        def check(silent: false, quiet: false)
          if quiet
            start_pattern = /<output class="mono"\/>/
          else
            start_pattern = /You have the following containers set as stow targets:/
          end
          waitrt?
          Lich::Util.issue_command("stow list", start_pattern, silent: silent, quiet: quiet)
          @checked = true
        end
      end
    end
  end
end
