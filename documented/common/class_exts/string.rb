# Carve out from lich.rbw
# extension to String class

# Extends the String class with additional functionality.
# This class adds methods to enhance string manipulation.
# @example Extending String functionality
#   my_string = "Hello"
#   my_string.stream = "stream_value"
class String
  # Returns a duplicate of the string.
  # @return [String] A duplicate of the original string.
  # @example Duplicating a string
  #   original = "Hello"
  #   duplicate = original.to_s
  #   puts duplicate # => "Hello"
  def to_s
    self.dup
  end

  # Retrieves the stream value associated with the string.
  # @return [Object, nil] The stream value or nil if not set.
  # @example Accessing the stream
  #   my_string = "Hello"
  #   my_string.stream # => nil
  def stream
    @stream
  end

  # Sets the stream value for the string if not already set.
  # @param val [Object] The value to set as the stream.
  # @return [Object] The value that was set as the stream.
  # @example Setting the stream
  #   my_string = "Hello"
  #   my_string.stream = "stream_value"
  #   puts my_string.stream # => "stream_value"
  def stream=(val)
    @stream ||= val
  end

  #  def to_a # for compatibility with Ruby 1.8
  #    [self]
  #  end

  #  def silent
  #    false
  #  end

  #  def split_as_list
  #    string = self
  #    string.sub!(/^You (?:also see|notice) |^In the .+ you see /, ',')
  #    string.sub('.', '').sub(/ and (an?|some|the)/, ', \1').split(',').reject { |str| str.strip.empty? }.collect { |str| str.lstrip }
  #  end
end
