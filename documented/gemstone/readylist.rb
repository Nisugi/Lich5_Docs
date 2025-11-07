module Lich
  module Gemstone
    # Represents a ready list for managing equipped items in the Lich game.
    # This class provides methods to check, reset, and validate the items in the ready list.
    # @example Creating a ready list
    #   ready_list = Lich::Gemstone::ReadyList
    class ReadyList
      @checked = false

      # The original list of ready items.
      # This constant defines the default items that can be included in the ready list.
      ORIGINAL_READY_LIST = [:shield, :weapon, :secondary_weapon, :ranged_weapon, :ammo_bundle, :ammo2_bundle, :sheath, :secondary_sheath, :wand]
      # The original list of store items.
      # This constant defines the default items that can be included in the store list.
      ORIGINAL_STORE_LIST = [:shield, :weapon, :secondary_weapon, :ranged_weapon, :ammo_bundle, :wand]

      @ready_list = {
        shield: nil,
        weapon: nil,
        secondary_weapon: nil,
        ranged_weapon: nil,
        ammo_bundle: nil,
        ammo2_bundle: nil,
        sheath: nil,
        secondary_sheath: nil,
        wand: nil,
      }
      @store_list = {
        shield: nil,
        weapon: nil,
        secondary_weapon: nil,
        ranged_weapon: nil,
        ammo_bundle: nil,
        wand: nil,
      }

      # Define class-level accessors for ready list entries
      @ready_list.each_key do |type|
        define_singleton_method("#{type}") { @ready_list[type] }
        define_singleton_method("#{type}=") { |value| @ready_list[type] = value }
      end

      # Define class-level accessors for store list entries
      @store_list.each_key do |type|
        define_singleton_method("store_#{type}") { @store_list[type] }
        define_singleton_method("store_#{type}=") { |value| @store_list[type] = value }
      end

      class << self
        # Returns the current ready list.
        # @return [Hash] The hash representing the ready list with item types as keys and their values.
        def ready_list
          @ready_list
        end

        # Returns the current store list.
        # @return [Hash] The hash representing the store list with item types as keys and their values.
        def store_list
          @store_list
        end

        # Checks if the ready list has been validated.
        # @return [Boolean] True if the ready list has been checked, false otherwise.
        def checked?
          @checked
        end

        # Sets the checked status of the ready list.
        # @param value [Boolean] The new checked status.
        # @return [Boolean] The updated checked status.
        def checked=(value)
          @checked = value
        end

        # Validates the items in the ready list.
        # @param all [Boolean] If true, validates all items, otherwise only validates original ready items.
        # @return [Boolean] True if all relevant items are valid, false otherwise.
        # @note This method requires that the ready list has been checked before validation.
        # @example Validating the ready list
        #   is_valid = ready_list.valid?(all: true)
        def valid?(all: false)
          # check if existing ready items are valid or not
          return false unless checked?
          @ready_list.each do |key, value|
            next unless all || ORIGINAL_READY_LIST.include?(key)
            unless key.eql?(:wand) || value.nil? || GameObj.inv.map(&:id).include?(value.id) || GameObj.containers.values.flatten.map(&:id).include?(value.id) || GameObj.right_hand.id.include?(value.id) || GameObj.left_hand.id.include?(value.id)
              @checked = false
              return false
            end
          end
          return true
        end

        # Resets the ready and store lists.
        # @param all [Boolean] If true, resets all items, otherwise only resets original items.
        # @return [void]
        # @example Resetting the ready list
        #   ready_list.reset(all: true)
        def reset(all: false)
          @checked = false
          @ready_list.each do |key, _value|
            next unless all || ORIGINAL_READY_LIST.include?(key)
            @ready_list[key] = nil
          end
          @store_list.each do |key, _value|
            next unless all || ORIGINAL_STORE_LIST.include?(key)
            @store_list[key] = nil
          end
        end

        # Checks the current settings of the ready list.
        # @param silent [Boolean] If true, suppresses output.
        # @param quiet [Boolean] If true, uses a quiet output pattern.
        # @return [void]
        # @example Checking the ready list
        #   ready_list.check(silent: true)
        def check(silent: false, quiet: false)
          if quiet
            start_pattern = /<output class="mono"\/>/
          else
            start_pattern = /Your current settings are:/
          end
          waitrt?
          Lich::Util.issue_command("ready list", start_pattern, silent: silent, quiet: quiet)
          @checked = true
        end
      end
    end
  end
end
