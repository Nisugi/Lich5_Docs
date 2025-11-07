# Carve out from lich.rbw
# extension to StringProc class 2024-06-13

module Lich
  module Common
    # Represents a String processing utility that evaluates a string as Ruby code.
    # This class allows for the creation of callable objects that can execute Ruby code contained in a string.
    # @example Creating a StringProc and calling it
    #   proc = StringProc.new("1 + 1")
    #   result = proc.call() # => 2
    class StringProc
      # Initializes a new StringProc instance.
      # @param string [String] The string to be processed and evaluated.
      # @return [StringProc] The new StringProc instance.
      def initialize(string)
        @string = string
      end

      # Checks if the object is of a certain type.
      # @param type [Class] The class to check against.
      # @return [Boolean] Returns true if the object is of the specified type.
      # @example Checking the type
      #   proc.kind_of?(Proc) # => true
      def kind_of?(type)
        Proc.new {}.kind_of? type
      end

      # Returns the class of the object.
      # @return [Class] The class of the object, which is Proc.
      def class
        Proc
      end

      # Executes the Ruby code contained in the string.
      # @return [Object] The result of the evaluated string.
      # @example Calling the StringProc
      #   result = proc.call() # => evaluates the string and returns the result
      def call(*_a)
        proc { eval(@string) }.call
      end

      # Dumps the string representation of the object.
      # @param _d [nil] Optional parameter, not used.
      # @return [String] The string representation of the StringProc.
      def _dump(_d = nil)
        @string
      end

      # Returns a string representation of the StringProc object.
      # @return [String] A string that describes the StringProc instance.
      # @example Inspecting the StringProc
      #   proc.inspect # => "StringProc.new(\"1 + 1\")"
      def inspect
        "StringProc.new(#{@string.inspect})"
      end

      # Converts the StringProc object to JSON format.
      # @param args [Array] Additional arguments for JSON conversion.
      # @return [String] The JSON representation of the StringProc.
      # @example Converting to JSON
      #   json = proc.to_json()
      def to_json(*args)
        ";e #{_dump}".to_json(args)
      end

      # Loads a StringProc object from a string representation.
      # @param string [String] The string to load into a StringProc.
      # @return [StringProc] The newly created StringProc instance from the string.
      def StringProc._load(string)
        StringProc.new(string)
      end
    end
  end
end
