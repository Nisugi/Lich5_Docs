# extension to class MatchData 2025-03-14

# Extension to the MatchData class
# This class adds additional functionality to the MatchData class, allowing
# conversion to a structured format.
# @example Converting MatchData to OpenStruct
#   match_data = /(?<name>\w+)/.match("John")
#   struct = match_data.to_struct
class MatchData
  # Converts the MatchData object to an OpenStruct.
  # @return [OpenStruct] An OpenStruct representation of the MatchData.
  def to_struct
    OpenStruct.new to_hash
  end

  # Converts the MatchData object to a hash.
  # @return [Hash] A hash representation of the MatchData, with names as keys and
  # captures as values.
  # @example Converting MatchData to a hash
  #   match_data = /(?<name>\w+)/.match("John")
  #   hash = match_data.to_hash
  def to_hash
    Hash[self.names.zip(self.captures.map(&:strip).map do |capture|
      if capture.is_i? then capture.to_i else capture end
    end)]
  end
end
