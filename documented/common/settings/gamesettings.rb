# Carve out from Lich 5 for module GameSettings
# 2024-06-13

module Lich
  module Common
    # Module for managing game settings in Lich 5
    # Provides methods to access and modify game settings.
    # @example Accessing a game setting
    #   setting_value = GameSettings["setting_name"]
    module GameSettings
      # Helper to get the active scope for GameSettings
      # Assumes XMLData.game is available and provides the correct scope string.
      # Retrieves the active scope for GameSettings.
      # Assumes XMLData.game is available and provides the correct scope string.
      # @return [String] The active game settings scope.
      # @example Getting the active scope
      #   scope = GameSettings.active_scope
      def self.active_scope
        XMLData.game
      end

      # Retrieves a scoped setting by name.
      # @param name [String] The name of the setting to retrieve.
      # @return [Object] The value of the specified setting.
      # @example Getting a setting value
      #   value = GameSettings["setting_name"]
      def self.[](name)
        Settings.get_scoped_setting(active_scope, name)
      end

      # Sets a scoped setting by name.
      # @param name [String] The name of the setting to set.
      # @param value [Object] The value to assign to the setting.
      # @return [void]
      # @example Setting a value
      #   GameSettings["setting_name"] = "new_value"
      def self.[]=(name, value)
        Settings.set_script_settings(active_scope, name, value)
      end

      # Converts the current game settings to a hash-like structure.
      # This method does not behave like a standard Ruby hash request.
      # It returns a root proxy for the game settings scope, allowing persistent
      # modifications on the returned object for legacy support.
      # @return [Object] A proxy object representing the game settings.
      # @example Converting settings to hash
      #   settings_hash = GameSettings.to_hash
      def self.to_hash
        # NB:  This method does not behave like a standard Ruby hash request.
        # It returns a root proxy for the game settings scope, allowing persistent
        # modifications on the returned object for legacy support.
        Settings.wrap_value_if_container(Settings.current_script_settings(active_scope), active_scope, [])
      end

      # deprecated
      # Loads game settings (deprecated).
      # @return [nil]
      # @deprecated This method is not applicable and will log a deprecation warning.
      # @example Loading settings
      #   GameSettings.load
      def GameSettings.load
        Lich.deprecated("GameSettings.load", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Saves game settings (deprecated).
      # @return [nil]
      # @deprecated This method is not applicable and will log a deprecation warning.
      # @example Saving settings
      #   GameSettings.save
      def GameSettings.save
        Lich.deprecated("GameSettings.save", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Saves all game settings (deprecated).
      # @return [nil]
      # @deprecated This method is not applicable and will log a deprecation warning.
      # @example Saving all settings
      #   GameSettings.save_all
      def GameSettings.save_all
        Lich.deprecated("GameSettings.save_all", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Clears game settings (deprecated).
      # @return [nil]
      # @deprecated This method is not applicable and will log a deprecation warning.
      # @example Clearing settings
      #   GameSettings.clear
      def GameSettings.clear
        Lich.deprecated("GameSettings.clear", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Sets the auto setting (deprecated).
      # @param _val [Object] The value to set for the auto setting.
      # @return [void]
      # @deprecated This method is not applicable and will log a deprecation warning.
      def GameSettings.auto=(_val)
        Lich.deprecated("GameSettings.auto=(val)", "not using, not applicable,", caller[0], fe_log: true)
      end

      # Retrieves the auto setting (deprecated).
      # @return [nil]
      # @deprecated This method is not applicable and will log a deprecation warning.
      def GameSettings.auto
        Lich.deprecated("GameSettings.auto", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Retrieves the autoload setting (deprecated).
      # @return [nil]
      # @deprecated This method is not applicable and will log a deprecation warning.
      def GameSettings.autoload
        Lich.deprecated("GameSettings.autoload", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end
    end
  end
end
