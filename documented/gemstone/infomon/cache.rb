module Lich
  module Gemstone
    module Infomon
      # in-memory cache with db read fallbacks
      # In-memory cache with database read fallbacks
      # This class provides a simple in-memory cache that can store key-value pairs.
      # If a key is not found in the cache, a block can be provided to fetch the value from a database or other source.
      # @example Creating a cache and using it
      #   cache = Lich::Gemstone::Infomon::Cache.new
      #   cache.put(:key, "value")
      class Cache
        attr_reader :records

        # Initializes a new Cache instance
        # @return [Cache] A new instance of Cache
        def initialize()
          @records = {}
        end

        # Stores a value in the cache with the given key
        # @param key [Object] The key to store the value under
        # @param value [Object] The value to store
        # @return [Cache] The current instance of Cache
        # @example Putting a value in the cache
        #   cache.put(:key, "value")
        def put(key, value)
          @records[key] = value
          self
        end

        # Checks if the cache includes the given key
        # @param key [Object] The key to check for
        # @return [Boolean] True if the key exists in the cache, false otherwise
        # @example Checking for a key in the cache
        #   cache.include?(:key)
        def include?(key)
          @records.include?(key)
        end

        # Clears all records from the cache
        # @return [void]
        # @example Flushing the cache
        #   cache.flush!
        def flush!
          @records.clear
        end

        # Deletes a value from the cache by its key
        # @param key [Object] The key of the value to delete
        # @return [Object, nil] The deleted value, or nil if the key was not found
        # @example Deleting a key from the cache
        #   cache.delete(:key)
        def delete(key)
          @records.delete(key)
        end

        # Retrieves a value from the cache by its key
        # If the key is not found, it can yield to a block to fetch the value.
        # @param key [Object] The key of the value to retrieve
        # @return [Object, nil] The value associated with the key, or nil if not found
        # @example Getting a value from the cache
        #   value = cache.get(:key) { fetch_from_db(:key) }
        def get(key)
          return @records[key] if self.include?(key)
          miss = nil
          miss = yield(key) if block_given?
          # don't cache nils
          return miss if miss.nil?
          @records[key] = miss
        end

        # Merges another hash into the cache
        # @param h [Hash] The hash to merge into the cache
        # @return [Hash] The updated records in the cache
        # @example Merging a hash into the cache
        #   cache.merge!({:key1 => "value1", :key2 => "value2"})
        def merge!(h)
          @records.merge!(h)
        end

        # Converts the cache records to an array of key-value pairs
        # @return [Array] An array representation of the cache records
        # @example Converting cache records to an array
        #   array = cache.to_a
        def to_a()
          @records.to_a
        end

        # Returns the cache records as a hash
        # @return [Hash] The hash representation of the cache records
        # @example Getting the cache records as a hash
        #   hash = cache.to_h
        def to_h()
          @records
        end

        alias :clear :flush!
        alias :key? :include?
      end
    end
  end
end
