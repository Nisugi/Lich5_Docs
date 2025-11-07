# Carve out from lich.rbw
# extension to Numeric class 2024-06-13

# Extends the Numeric class to provide additional time and formatting methods.
# This class adds methods to convert numeric values into time formats and to format numbers with commas.
# @example Using the Numeric extensions
#   120.as_time # => "2:00:00"
#   123456.with_commas # => "123,456"
class Numeric
  # Converts the numeric value to a time string in "HH:MM:SS" format.
  # @return [String] The time representation of the numeric value.
  # @example
  #   3661.as_time # => "1:01:01"
  def as_time
    sprintf("%d:%02d:%02d", (self / 60).truncate, self.truncate % 60, ((self % 1) * 60).truncate)
  end

  # Formats the numeric value as a string with commas separating thousands.
  # @return [String] The formatted string with commas.
  # @example
  #   1234567.with_commas # => "1,234,567"
  def with_commas
    self.to_s.reverse.scan(/(?:\d*\.)?\d{1,3}-?/).join(',').reverse
  end

  # Returns the numeric value as seconds.
  # @return [Numeric] The original numeric value, representing seconds.
  # @example
  #   5.seconds # => 5
  def seconds
    return self
  end
  alias :second :seconds

  # Converts the numeric value to minutes.
  # @return [Numeric] The numeric value multiplied by 60, representing minutes.
  # @example
  #   2.minutes # => 120
  def minutes
    return self * 60
  end
  alias :minute :minutes

  # Converts the numeric value to hours.
  # @return [Numeric] The numeric value multiplied by 3600, representing hours.
  # @example
  #   1.5.hours # => 5400
  def hours
    return self * 3600
  end
  alias :hour :hours

  # Converts the numeric value to days.
  # @return [Numeric] The numeric value multiplied by 86400, representing days.
  # @example
  #   1.days # => 86400
  def days
    return self * 86400
  end
  alias :day :days
end
