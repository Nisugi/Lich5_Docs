# frozen_string_literal: true

# Replacement for the venerable infomon.lic script used in Lich4 and Lich5 (03/01/23)
# Supports Ruby 3.X builds
#
#     maintainer: elanthia-online
#   contributors: Tillmen, Shaelun, Athias
#           game: Gemstone
#           tags: core
#       required: Lich > 5.6.2
#        version: 2.0
#         Source: https://github.com/elanthia-online/scripts

require 'sequel'
require 'tmpdir'
require 'logger'
require_relative 'infomon/cache'

module Lich
  module Gemstone
    # Replacement for the venerable infomon.lic script used in Lich4 and Lich5 (03/01/23)
    # Supports Ruby 3.X builds
    # @example Usage
    #   Lich::Gemstone::Infomon.set("key", "value")
    module Infomon
      $infomon_debug = ENV["DEBUG"]
      # use temp dir in ci context
      @root = defined?(DATA_DIR) ? DATA_DIR : Dir.tmpdir
      @file = File.join(@root, "infomon.db")
      @db   = Sequel.sqlite(@file)
      @cache ||= Infomon::Cache.new
      @cache_loaded = false
      @db.loggers << Logger.new($stdout) if ENV["DEBUG"]
      @sql_queue ||= Queue.new
      @sql_mutex ||= Mutex.new

      # Returns the cache instance used by Infomon
      # @return [Cache] The cache instance
      def self.cache
        @cache
      end

      # Returns the file path for the Infomon database
      # @return [String] The database file path
      def self.file
        @file
      end

      # Returns the Sequel database instance
      # @return [Sequel::Database] The database instance
      def self.db
        @db
      end

      # Returns the mutex used for thread safety
      # @return [Mutex] The mutex instance
      def self.mutex
        @sql_mutex
      end

      # Locks the mutex to ensure thread safety
      # @raise [StandardError] If an error occurs while locking
      def self.mutex_lock
        begin
          self.mutex.lock unless self.mutex.owned?
        rescue StandardError
          respond "--- Lich: error: Infomon.mutex_lock: #{$!}"
          Lich.log "error: Infomon.mutex_lock: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        end
      end

      # Unlocks the mutex to allow other threads access
      # @raise [StandardError] If an error occurs while unlocking
      def self.mutex_unlock
        begin
          self.mutex.unlock if self.mutex.owned?
        rescue StandardError
          respond "--- Lich: error: Infomon.mutex_unlock: #{$!}"
          Lich.log "error: Infomon.mutex_unlock: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
        end
      end

      # Returns the SQL queue for database operations
      # @return [Queue] The SQL queue instance
      def self.queue
        @sql_queue
      end

      # Checks if the context is valid before accessing Infomon
      # @raise [RuntimeError] If XMLData.name is not loaded
      def self.context!
        return unless XMLData.name.empty? or XMLData.name.nil?
        puts Exception.new.backtrace
        fail "cannot access Infomon before XMLData.name is loaded"
      end

      # Generates the table name based on game and XMLData
      # @return [Symbol] The generated table name
      def self.table_name
        self.context!
        ("%s_%s" % [XMLData.game, XMLData.name]).to_sym
      end

      # Resets the Infomon state, clearing the cache and database table
      # @return [void]
      def self.reset!
        self.mutex_lock
        Infomon.db.drop_table?(self.table_name)
        self.cache.clear
        @cache_loaded = false
        Infomon.setup!
      end

      # Returns the database table for Infomon
      # @return [Sequel::Dataset] The dataset for the table
      def self.table
        @_table ||= self.setup!
      end

      # Sets up the database table for Infomon
      # @return [Sequel::Dataset] The dataset for the created table
      def self.setup!
        self.mutex_lock
        @db.create_table?(self.table_name) do
          text :key, primary_key: true
          any :value
        end
        self.mutex_unlock
        @_table = @db[self.table_name]
      end

      # Loads the cache from the database
      # @return [void]
      def self.cache_load
        sleep(0.01) if XMLData.name.empty?
        dataset = Infomon.table
        h = Hash[dataset.map(:key).zip(dataset.map(:value))]
        self.cache.merge!(h)
        @cache_loaded = true
      end

      # Normalizes the key for storage
      # @param key [String, Symbol] The key to normalize
      # @return [String] The normalized key
      def self._key(key)
        key = key.to_s.downcase
        key.tr!(' ', '_').gsub!('_-_', '_').tr!('-', '_') if /\s|-/.match?(key)
        return key
      end

      # Normalizes the value for storage
      # @param val [Object] The value to normalize
      # @return [Object] The normalized value
      def self._value(val)
        return true if val.to_s == "true"
        return false if val.to_s == "false"
        return val
      end

      # Allowed types for values in Infomon
      AllowedTypes = [Integer, String, NilClass, FalseClass, TrueClass]
      # Validates the key and value types
      # @param key [String] The key to validate
      # @param value [Object] The value to validate
      # @return [Object] The validated value
      # @raise [RuntimeError] If the value type is not allowed
      def self._validate!(key, value)
        return self._value(value) if AllowedTypes.include?(value.class)
        raise "infomon:insert(%s) was called with %s\nmust be %s\nvalue=%s" % [key, value.class, AllowedTypes.map(&:name).join("|"), value]
      end

      # Retrieves a value from the cache or database
      # @param key [String] The key to retrieve
      # @return [Object] The value associated with the key
      # @raise [StandardError] If an error occurs during retrieval
      # @example
      #   value = Infomon.get("key")
      def self.get(key)
        self.cache_load if !@cache_loaded
        key = self._key(key)
        val = self.cache.get(key) {
          sleep 0.01 until self.queue.empty?
          begin
            self.mutex.synchronize do
              begin
                db_result = self.table[key: key]
                if db_result
                  db_result[:value]
                else
                  nil
                end
              rescue => exception
                pp(exception)
                nil
              end
            end
          rescue StandardError
            respond "--- Lich: error: Infomon.get(#{key}): #{$!}"
            Lich.log "error: Infomon.get(#{key}): #{$!}\n\t#{$!.backtrace.join("\n\t")}"
          end
        }
        return self._value(val)
      end

      # Retrieves a boolean value from the cache or database
      # @param key [String] The key to retrieve
      # @return [Boolean] The boolean value associated with the key
      def self.get_bool(key)
        value = Infomon.get(key)
        if value.is_a?(TrueClass) || value.is_a?(FalseClass)
          return value
        elsif value == 1
          return true
        else
          return false
        end
      end

      # Inserts or replaces a key-value pair in the database
      # @param args [Array] The key-value pairs to insert
      # @return [void]
      def self.upsert(*args)
        self.table
            .insert_conflict(:replace)
            .insert(*args)
      end

      # Sets a key-value pair in the cache and database
      # @param key [String] The key to set
      # @param value [Object] The value to set
      # @return [Symbol] :noop if the value is unchanged, otherwise performs the operation
      def self.set(key, value)
        key = self._key(key)
        value = self._validate!(key, value)
        return :noop if self.cache.get(key) == value
        self.cache.put(key, value)
        self.queue << "INSERT OR REPLACE INTO %s (`key`, `value`) VALUES (%s, %s)
      on conflict(`key`) do update set value = excluded.value;" % [self.db.literal(self.table_name), self.db.literal(key), self.db.literal(value)]
      end

      # Deletes a key from the cache and database
      # @param key [String] The key to delete
      # @return [void]
      def self.delete!(key)
        key = self._key(key)
        self.cache.delete(key)
        self.queue << "DELETE FROM %s WHERE key = (%s);" % [self.db.literal(self.table_name), self.db.literal(key)]
      end

      # Inserts or replaces multiple key-value pairs in the database
      # @param blob [Array] An array of key-value pairs to insert
      # @return [void]
      def self.upsert_batch(*blob)
        updated = (blob.first.map { |k, v| [self._key(k), self._validate!(k, v)] } - self.cache.to_a)
        return :noop if updated.empty?
        pairs = updated.map { |key, value|
          (value.is_a?(Integer) or value.is_a?(String)) or fail "upsert_batch only works with Integer or String types"
          # add the value to the cache
          self.cache.put(key, value)
          %[(%s, %s)] % [self.db.literal(key), self.db.literal(value)]
        }.join(", ")
        # queue sql statement to run async
        self.queue << "INSERT OR REPLACE INTO %s (`key`, `value`) VALUES %s
      on conflict(`key`) do update set value = excluded.value;" % [self.db.literal(self.table_name), pairs]
      end

      # @!method Background SQL Queue Processor
      # Background thread for processing SQL statements from the queue.
      # This thread continuously processes queued SQL statements asynchronously.
      # @return [void]
      Thread.new do
        loop do
          sql_statement = Infomon.queue.pop
          begin
            Infomon.mutex.synchronize do
              begin
                Infomon.db.run(sql_statement)
              rescue StandardError => e
                pp(e)
              end
            end
          rescue StandardError
            respond "--- Lich: error: Infomon ThreadQueue: #{$!}"
            Lich.log "error: Infomon ThreadQueue: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
          end
        end
      end

      require_relative 'infomon/parser'
      require_relative 'infomon/xmlparser'
      require_relative 'infomon/cli'
    end
  end
end
