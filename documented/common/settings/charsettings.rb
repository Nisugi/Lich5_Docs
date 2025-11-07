# Carve out from Lich5 for module CharSettings
# 2024-06-13

module Lich
  module Common
    # Provides character settings management for the Lich5 project.
    # This module allows for dynamic access and modification of character settings.
    # @example Accessing a character setting
    #   setting_value = CharSettings["setting_name"]
    module CharSettings
      # CHAR_SCOPE_PREFIX = XMLData.game # Not strictly needed if active_scope is always dynamic

      # Returns the active scope for character settings.
      # This scope is a combination of the game and character name.
      # @return [String] The active scope in the format "game:name"
      def self.active_scope
        # Ensure XMLData.game and XMLData.name are available and up-to-date when scope is needed
        "#{XMLData.game}:#{XMLData.name}"
      end

      # Retrieves a character setting by name.
      # @param name [String] The name of the setting to retrieve.
      # @return [Object] The value of the specified setting.
      # @example
      #   value = CharSettings["setting_name"]
      def self.[](name)
        Settings.get_scoped_setting(active_scope, name)
      end

      # Sets a character setting by name.
      # @param name [String] The name of the setting to set.
      # @param value [Object] The value to assign to the setting.
      # @return [Object] The value that was set.
      # @example
      #   CharSettings["setting_name"] = "new_value"
      def self.[]=(name, value)
        Settings.set_script_settings(active_scope, name, value)
      end

      # Converts the character settings to a hash-like structure.
      # This method returns a proxy for the character settings scope, allowing for persistent modifications.
      # @return [Object] A proxy object representing the character settings.
      # @note This method does not behave like a standard Ruby hash request.
      def self.to_hash
        # NB:  This method does not behave like a standard Ruby hash request.
        # It returns a root proxy for the character settings scope, allowing persistent
        # modifications on the returned object for legacy support.
        Settings.wrap_value_if_container(Settings.current_script_settings(active_scope), active_scope, [])
      end

      # deprecated
      # Loads character settings (deprecated).
      # This method is no longer applicable and will log a deprecation warning.
      # @return [nil] Always returns nil.
      # @deprecated This method is not in use.
      def CharSettings.load
        Lich.deprecated("CharSettings.load", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Saves character settings (deprecated).
      # This method is no longer applicable and will log a deprecation warning.
      # @return [nil] Always returns nil.
      # @deprecated This method is not in use.
      def CharSettings.save
        Lich.deprecated("CharSettings.save", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Saves all character settings (deprecated).
      # This method is no longer applicable and will log a deprecation warning.
      # @return [nil] Always returns nil.
      # @deprecated This method is not in use.
      def CharSettings.save_all
        Lich.deprecated("CharSettings.save_all", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Clears character settings (deprecated).
      # This method is no longer applicable and will log a deprecation warning.
      # @return [nil] Always returns nil.
      # @deprecated This method is not in use.
      def CharSettings.clear
        Lich.deprecated("CharSettings.clear", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Sets the auto setting (deprecated).
      # This method is no longer applicable and will log a deprecation warning.
      # @param _val [Object] The value to set for auto.
      # @return [nil] Always returns nil.
      # @deprecated This method is not in use.
      def CharSettings.auto=(_val)
        Lich.deprecated("CharSettings.auto=(val)", "not using, not applicable,", caller[0], fe_log: true)
      end

      # Retrieves the auto setting (deprecated).
      # This method is no longer applicable and will log a deprecation warning.
      # @return [nil] Always returns nil.
      # @deprecated This method is not in use.
      def CharSettings.auto
        Lich.deprecated("CharSettings.auto", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end

      # Retrieves the autoload setting (deprecated).
      # This method is no longer applicable and will log a deprecation warning.
      # @return [nil] Always returns nil.
      # @deprecated This method is not in use.
      def CharSettings.autoload
        Lich.deprecated("CharSettings.autoload", "not using, not applicable,", caller[0], fe_log: true)
        nil
      end
    end
  end
end
