# Carve out from lich.rbw
# extension to class Nilclass 2024-06-13

# Extends the NilClass to provide additional methods.
# This class overrides several methods to return nil or empty values.
# @example Using NilClass methods
#   nil.dup # => nil
#   nil.split # => []
class NilClass
  # Returns a duplicate of nil.
  # @return [NilClass] Always returns nil.
  # @example
  #   nil.dup # => nil
  def dup
    nil
  end

  # Handles calls to methods that do not exist on nil.
  # @param _args [Array] The arguments passed to the missing method.
  # @return [NilClass] Always returns nil.
  # @example
  #   nil.some_method # => nil
  def method_missing(*_args)
    nil
  end

  # Splits nil into an array.
  # @param _val [Array] The delimiter(s) to split by (ignored).
  # @return [Array] Returns an empty array.
  # @example
  #   nil.split # => []
  def split(*_val)
    Array.new
  end

  # Converts nil to a string.
  # @return [String] Returns an empty string.
  # @example
  #   nil.to_s # => ""
  def to_s
    ""
  end

  # Strips whitespace from nil.
  # @return [String] Returns an empty string.
  # @example
  #   nil.strip # => ""
  def strip
    ""
  end

  # Adds a value to nil.
  # @param val [Object] The value to add to nil.
  # @return [Object] Returns the value passed in.
  # @example
  #   nil + 5 # => 5
  def +(val)
    val
  end

  # Checks if nil is closed.
  # @return [Boolean] Always returns true.
  # @example
  #   nil.closed? # => true
  def closed?
    true
  end
end
