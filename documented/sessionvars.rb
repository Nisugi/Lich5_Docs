# New module SessionVars for variables needed by more than one script but do not need to be saved to the sqlite db
#   (should this be in settings path?)
# 2024-09-05

# New module for managing session variables
# This module provides a way to store variables needed by more than one script without saving them to the sqlite database.
# @example Setting a session variable
#   SessionVars["user_id"] = 42
# @example Retrieving a session variable
#   user_id = SessionVars["user_id"]
module SessionVars
  @@svars = Hash.new

  # Retrieves the value of a session variable by name.
  # @param name [String] The name of the session variable to retrieve.
  # @return [Object, nil] The value of the session variable, or nil if it does not exist.
  # @example Retrieving a session variable
  #   value = SessionVars["key"]
  def SessionVars.[](name)
    @@svars[name]
  end

  # Sets the value of a session variable by name.
  # @param name [String] The name of the session variable to set.
  # @param val [Object, nil] The value to set for the session variable. If nil, the variable will be deleted.
  # @return [Object] The value that was set.
  # @example Setting a session variable
  #   SessionVars["key"] = "value"
  def SessionVars.[]=(name, val)
    if val.nil?
      @@svars.delete(name)
    else
      @@svars[name] = val
    end
  end

  # Returns a duplicate of the current session variables.
  # @return [Hash] A hash containing all session variables.
  # @example Listing all session variables
  #   all_vars = SessionVars.list
  def SessionVars.list
    @@svars.dup
  end

  # Handles dynamic method calls for setting and getting session variables.
  # @param arg1 [Symbol, String] The name of the session variable or the method being called.
  # @param arg2 [Object, String] The value to set if the method is a setter (ends with '='), otherwise ignored.
  # @return [Object, nil] The value of the session variable, or nil if it does not exist.
  # @example Using dynamic methods
  #   SessionVars.some_var = "value"
  #   value = SessionVars.some_var
  def SessionVars.method_missing(arg1, arg2 = '')
    if arg1[-1, 1] == '='
      if arg2.nil?
        @@svars.delete(arg1.to_s.chop)
      else
        @@svars[arg1.to_s.chop] = arg2
      end
    else
      @@svars[arg1.to_s]
    end
  end
end
