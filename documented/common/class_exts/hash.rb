# extension to class Hash 2025-03-14

# Extension to the Hash class
# This class adds additional methods to the built-in Hash class.
# @example Using the extended Hash methods
#   my_hash = Hash.new
#   Hash.put(my_hash, "key1.key2", "value")
class Hash
  # Puts a value into a nested hash structure at the specified path.
  # @param target [Hash] The target hash to modify.
  # @param path [Array,String] The path where the value should be placed.
  # @param val [Object] The value to be inserted at the specified path.
  # @return [Hash] The original target hash.
  # @raise [ArgumentError] If the path is empty.
  # @example Inserting a value into a nested hash
  #   my_hash = {}
  #   Hash.put(my_hash, "key1.key2", "value")
  #   # my_hash now is { "key1" => { "key2" => "value" } }
  def self.put(target, path, val)
    path = [path] unless path.is_a?(Array)
    fail ArgumentError, "path cannot be empty" if path.empty?
    root = target
    path.slice(0..-2).each { |key| target = target[key] ||= {} }
    target[path.last] = val
    root
  end

  # Converts the hash to an OpenStruct object.
  # @return [OpenStruct] An OpenStruct representation of the hash.
  # @example Converting a hash to OpenStruct
  #   my_hash = { "name" => "John", "age" => 30 }
  #   struct = my_hash.to_struct
  #   # struct.name returns "John"
  def to_struct
    OpenStruct.new self
  end
end
