# break out module UserVars
# 2024-06-13

module Lich
  module Common
    # Provides methods to manage user variables
    # This module allows for listing, changing, adding, and deleting user variables.
    # @example Using UserVars
    #   Lich::Common::UserVars.change("username", "player1")
    module UserVars
      # Lists all user variables
      # @return [Array] An array of user variable names
      def UserVars.list
        Vars.list
      end

      # Handles missing methods for user variables
      # This method delegates calls to the Vars object.
      # @param args [Array] The arguments passed to the missing method
      # @return [Object] The result of the Vars method call
      def UserVars.method_missing(*args)
        Vars.method_missing(*args)
      end

      # Changes the value of a user variable
      # @param var_name [String] The name of the variable to change
      # @param value [Object] The new value to assign to the variable
      # @param _t [nil] Optional parameter (not used)
      # @return [void]
      def UserVars.change(var_name, value, _t = nil)
        Vars[var_name] = value
      end

      # Adds a value to a user variable
      # If the variable already contains values, the new value is appended.
      # @param var_name [String] The name of the variable to add a value to
      # @param value [Object] The value to add
      # @param _t [nil] Optional parameter (not used)
      # @return [void]
      # @example Adding a value to a variable
      #   Lich::Common::UserVars.add("items", "sword")
      def UserVars.add(var_name, value, _t = nil)
        Vars[var_name] = Vars[var_name].split(', ').push(value).join(', ')
      end

      # Deletes a user variable
      # Sets the variable to nil.
      # @param var_name [String] The name of the variable to delete
      # @param _t [nil] Optional parameter (not used)
      # @return [void]
      def UserVars.delete(var_name, _t = nil)
        Vars[var_name] = nil
      end

      # Lists global user variables
      # @return [Array] An empty array (no global variables implemented)
      def UserVars.list_global
        Array.new
      end

      # Lists character-specific user variables
      # @return [Array] An array of character-specific user variable names
      def UserVars.list_char
        Vars.list
      end
    end
  end
end
