module Lich
  module Common
    class Map
      include Enumerable
      @@loaded                   = false
      @@load_mutex               = Mutex.new
      @@list                   ||= Array.new
      @@tags                   ||= Array.new
      @@current_room_mutex       = Mutex.new
      @@current_room_id        ||= -1
      @@current_room_count     ||= -1
      @@fuzzy_room_mutex         = Mutex.new
      @@fuzzy_room_count       ||= -1
      @@current_location       ||= nil
      @@current_location_count ||= -1
      @@current_room_uid       ||= -1
      @@previous_room_id       ||= -1
      @@uids                     = {}

      # The unique identifier for the map room.
      attr_reader :id
      # The title of the map room.
      attr_accessor :title, :description, :paths, :location, :climate, :terrain, :wayto, :timeto, :image, :image_coords, :tags, :check_location, :unique_loot, :uid, :room_objects

      # Initializes a new map room.
      # @param id [Integer] The unique identifier for the room.
      # @param title [String] The title of the room.
      # @param description [String] A description of the room.
      # @param paths [Array<String>] Possible paths from this room.
      # @param uid [Array<Integer>] Unique identifiers for the room (default: []).
      # @param location [String, nil] The location of the room (default: nil).
      # @param climate [String, nil] The climate of the room (default: nil).
      # @param terrain [String, nil] The terrain of the room (default: nil).
      # @param wayto [Hash<String, String>] Connections to other rooms (default: {}).
      # @param timeto [Hash<String, Float>] Time to reach other rooms (default: {}).
      # @param image [String, nil] Image associated with the room (default: nil).
      # @param image_coords [Array<Integer>, nil] Coordinates for the image (default: nil).
      # @param tags [Array<String>] Tags associated with the room (default: []).
      # @param check_location [String, nil] Location check (default: nil).
      # @param unique_loot [String, nil] Unique loot for the room (default: nil).
      # @param _room_objects [Object, nil] Room objects (default: nil).
      def initialize(id, title, description, paths, uid = [], location = nil, climate = nil, terrain = nil, wayto = {}, timeto = {}, image = nil, image_coords = nil, tags = [], check_location = nil, unique_loot = nil, _room_objects = nil)
        @id, @title, @description, @paths, @uid, @location, @climate, @terrain, @wayto, @timeto, @image, @image_coords, @tags, @check_location, @unique_loot = id, title, description, paths, uid, location, climate, terrain, wayto, timeto, image, image_coords, tags, check_location, unique_loot
        @@list[@id] = self
      end

      # Returns the ID of the map room.
      # @return [Integer] The unique identifier of the room.
      def to_i
        @id
      end

      # Returns a string representation of the map room.
      # @return [String] A formatted string containing the room's ID, title, description, and paths.
      def to_s
        "##{@id} (#{@uid[-1]}):\n#{@title[-1]}\n#{@description[-1]}\n#{@paths[-1]}"
      end

      # Returns a string representation of the map room's instance variables.
      # @return [String] A string detailing the instance variables and their values.
      def inspect
        self.instance_variables.collect { |var| var.to_s + "=" + self.instance_variable_get(var).inspect }.join("\n")
      end

      # Retrieves a free ID for a new map room.
      # @return [Integer] A unique ID that can be assigned to a new room.
      def Map.get_free_id
        Map.load unless @@loaded
        return @@list.compact.max_by { |r| r.id }.id + 1
      end

      # Returns a list of all map rooms.
      # @return [Array<Map>] An array of all map room instances.
      def Map.list
        Map.load unless @@loaded
        @@list
      end

      # Retrieves a map room by its ID or UID.
      # @param val [Integer, String] The ID or UID of the room.
      # @return [Map, nil] The corresponding map room or nil if not found.
      def Map.[](val)
        Map.load unless @@loaded
        if (val.is_a?(Integer)) or val =~ /^[0-9]+$/
          @@list[val.to_i]
        elsif val =~ /^u(-?\d+)$/i
          uid_request = $1.dup.to_i
          @@list[(Map.ids_from_uid(uid_request)[0]).to_i]
        else
          chkre = /#{val.strip.sub(/\.$/, '').gsub(/\.(?:\.\.)?/, '|')}/i
          chk = /#{Regexp.escape(val.strip)}/i
          @@list.find { |room| room.title.find { |title| title =~ chk } } || @@list.find { |room| room.description.find { |desc| desc =~ chk } } || @@list.find { |room| room.description.find { |desc| desc =~ chkre } }
        end
      end

      # Returns the previously visited map room.
      # @return [Map, nil] The previous map room or nil if none exists.
      def Map.previous
        return @@list[@@previous_room_id]
      end

      # Returns the UID of the previously visited room.
      # @return [Integer, nil] The UID of the previous room or nil if none exists.
      def Map.previous_uid
        return XMLData.previous_nav_rm
      end

      # Returns the current map room based on the game state.
      # @return [Map, nil] The current map room or nil if none exists.
      def Map.current # returns Map/Room
        Map.load unless @@loaded
        if Script.current
          return @@list[@@current_room_id] if XMLData.room_count == @@current_room_count and !@@current_room_id.nil?;
        else
          return @@list[@@current_room_id] if XMLData.room_count == @@fuzzy_room_count and !@@current_room_id.nil?;
        end
        ids = (XMLData.room_id.zero? ? [] : Map.ids_from_uid(XMLData.room_id))
        return Map.set_current(ids[0]) if (ids.size == 1)
        if ids.size > 1 and !@@current_room_id.nil? and (id = Map.match_multi_ids(ids))
          return Map.set_current(id)
        end
        return Map.match_no_uid()
      end

      # Matches the current room without a UID.
      # @return [Map, nil] The matched map room or nil if none found.
      def Map.match_no_uid() # returns Map/Room
        if (script = Script.current)
          return Map.set_current(Map.match_current(script))
        else
          return Map.set_fuzzy(Map.match_fuzzy())
        end
      end

      # Sets the current room ID to a fuzzy match.
      # @param id [Integer, nil] The ID of the room to set as current.
      # @return [Map, nil] The newly set map room or nil if none exists.
      def Map.set_fuzzy(id) # returns Map/Room
        @@previous_room_id = @@current_room_id if !id.nil? and id != @@current_room_id;
        @@current_room_id  = id
        return nil if id.nil?
        return @@list[id]
      end

      # Matches the current room based on the game state.
      # @return [Integer, nil] The ID of the matched room or nil if none found.
      def Map.match_current(_script) # returns id
        @@current_room_mutex.synchronize {
          Hash.new
          need_set_desc_off = false
          begin
            begin
              @@current_room_count = XMLData.room_count
              foggy_exits = (XMLData.room_exits_string =~ /^Obvious (?:exits|paths): obscured by a thick fog$/)
              if (room = @@list.find { |r|
                    r.title.include?(XMLData.room_title) and
                      r.description.include?(XMLData.room_description.strip) and
                      (foggy_exits or r.paths.include?(XMLData.room_exits_string.strip))
                  })
                redo unless @@current_room_count == XMLData.room_count
                if room.uid.any?
                  unless room.uid.include?(XMLData.room_id)
                    return nil
                  else
                    return room.id
                  end
                else
                  return room.id
                end
              else
                redo unless @@current_room_count == XMLData.room_count
                desc_regex = /#{Regexp.escape(XMLData.room_description.strip.sub(/\.+$/, '')).gsub(/\\\.(?:\\\.\\\.)?/, '|')}/
                if (room = @@list.find { |r|
                      r.title.include?(XMLData.room_title) and
                        (foggy_exits or r.paths.include?(XMLData.room_exits_string.strip)) and
                        (XMLData.room_window_disabled or r.description.any? { |desc| desc =~ desc_regex })
                    })
                  redo unless @@current_room_count == XMLData.room_count
                  if room.uid.any?
                    unless room.uid.include?(XMLData.room_id)
                      return nil
                    else
                      return room.id
                    end
                  else
                    return room.id
                  end
                else
                  redo unless @@current_room_count == XMLData.room_count
                  return nil
                end
              end
            end
          ensure
            put 'set description off' if need_set_desc_off
          end
        }
      end

      # Matches a room based on fuzzy criteria.
      # @return [Integer, nil] The ID of the matched room or nil if none found.
      def Map.match_fuzzy() # returns id
        @@fuzzy_room_mutex.synchronize {
          @@fuzzy_room_count = XMLData.room_count
          begin
            foggy_exits = (XMLData.room_exits_string =~ /^Obvious (?:exits|paths): obscured by a thick fog$/)
            if (room = @@list.find { |r|
                  r.title.include?(XMLData.room_title) and
                    r.description.include?(XMLData.room_description.strip) and
                    (foggy_exits or r.paths.include?(XMLData.room_exits_string.strip))
                })
              redo unless @@fuzzy_room_count == XMLData.room_count

              if room.uid.any?
                unless room.uid.include?(XMLData.room_id)
                  return nil
                else
                  return room.id
                end
              elsif room.tags.any? { |tag| tag =~ /^(set desc on; )?peer [a-z]+ =~ \/.+\/$/ }
                return nil
              else
                return room.id
              end
            else
              redo unless @@fuzzy_room_count == XMLData.room_count
              desc_regex = /#{Regexp.escape(XMLData.room_description.strip.sub(/\.+$/, '')).gsub(/\\\.(?:\\\.\\\.)?/, '|')}/
              if (room = @@list.find { |r|
                    r.title.include?(XMLData.room_title) and
                    (foggy_exits or r.paths.include?(XMLData.room_exits_string.strip)) and
                    (XMLData.room_window_disabled or r.description.any? { |desc| desc =~ desc_regex })
                  })
                redo unless @@fuzzy_room_count == XMLData.room_count

                if room.uid.any?
                  unless room.uid.include?(XMLData.room_id)
                    return nil
                  else
                    return room.id
                  end
                elsif room.tags.any? { |tag| tag =~ /^(set desc on; )?peer [a-z]+ =~ \/.+\/$/ }
                  return nil
                else
                  return room.id
                end
              else
                redo unless @@fuzzy_room_count == XMLData.room_count
                return nil
              end
            end
          end
        }
      end

      # Returns the current room or creates a new one if none exists.
      # @return [Map, nil] The current or newly created map room.
      def Map.current_or_new # returns Map/Room
        return nil unless Script.current
        @@current_room_count = -1
        @@fuzzy_room_count = -1

        Map.load unless @@loaded

        room = nil

        id = Map.current ? Map.current.id : nil

        echo("Map: current room id is #{id.inspect}")
        unless id.nil?
          room = Map[id]
          unless XMLData.room_id.zero? || room.uid.include?(XMLData.room_id)
            room.uid << XMLData.room_id
            Map.uids_add(XMLData.room_id, room.id)
            echo "Map: Adding new uid for #{room.id}: #{XMLData.room_id}"
          end
          return Map.set_current(room.id)
        end
        id               = Map.get_free_id
        title            = [XMLData.room_title]
        description      = [XMLData.room_description.strip]
        paths            = [XMLData.room_exits_string.strip]
        uid              = (XMLData.room_id.zero? ? [] : [XMLData.room_id])
        room             = Map.new(id, title, description, paths, uid)
        Map.uids_add(XMLData.room_id, room.id) unless XMLData.room_id.zero?
        echo "mapped new room, set current room to #{room.id}"
        return Map.set_current(id)
      end

      # Adds a UID to the map's UID list.
      # @param uid [Integer] The UID to add.
      # @param id [Integer] The ID of the room associated with the UID.
      def Map.uids_add(uid, id)
        if !@@uids.key?(uid)
          @@uids[uid] = [id]
        else
          @@uids[uid] << id if !@@uids[uid].include?(id)
        end
      end

      # Sets the current room ID.
      # @param id [Integer] The ID of the room to set as current.
      # @return [Map, nil] The newly set map room or nil if none exists.
      def Map.set_current(id) # returns Map/Room
        @@previous_room_id = @@current_room_id if id != @@current_room_id;
        @@current_room_id  = id
        return nil if id.nil?
        return @@list[id]
      end

      # Matches multiple IDs to find a valid room.
      # @param ids [Array<Integer>] The list of IDs to match.
      # @return [Integer, nil] The matched ID or nil if none found.
      def Map.match_multi_ids(ids) # returns id
        matches = ids.find_all { |s| @@list[@@current_room_id].wayto.keys.include?(s.to_s) }
        return matches[0] if matches.size == 1;
        return nil;
      end

      # Returns a list of all tags from the map rooms.
      # @return [Array<String>] An array of unique tags.
      def Map.tags
        Map.load unless @@loaded
        if @@tags.empty?
          @@list.each { |r|
            r.tags.each { |t|
              @@tags.push(t) unless @@tags.include?(t)
            }
          }
        end
        @@tags.dup
      end

      # Loads UIDs from the map rooms into the UID list.
      def Map.load_uids()
        Map.load unless @@loaded
        @@uids.clear
        @@list.each { |r|
          r.uid.each { |u|
            if @@uids[u].nil?
              @@uids[u] = [r.id]
            else
              @@uids[u] << r.id if !@@uids[u].include?(r.id)
            end
          }
        }
      end

      # Retrieves room IDs associated with a given UID.
      # @param n [Integer] The UID to look up.
      # @return [Array<Integer>] An array of room IDs associated with the UID.
      def Map.ids_from_uid(n)
        return (@@uids[n].nil? || n == 0 ? [] : @@uids[n])
      end

      # Clears the map data and resets the loaded state.
      def Map.clear
        @@load_mutex.synchronize {
          @@list.clear
          @@tags.clear
          @@loaded = false
          GC.start
        }
        true
      end

      # Reloads the map data from the source files.
      def Map.reload
        Map.clear
        Map.load
      end

      # Loads map data from files.
      # @param filename [String, nil] The filename to load from (default: nil).
      # @return [Boolean] True if loading was successful, false otherwise.
      def Map.load(filename = nil)
        if filename.nil?
          file_list = Dir.entries("#{DATA_DIR}/#{XMLData.game}").find_all { |filename| filename =~ /^map\-[0-9]+\.(?:dat|xml|json)$/i }.collect { |filename| "#{DATA_DIR}/#{XMLData.game}/#{filename}" }.sort.reverse
        else
          file_list = [filename]
        end
        if file_list.empty?
          respond "--- Lich: error: no map database found"
          return false
        end
        while (filename = file_list.shift)
          if filename =~ /\.json$/i
            if Map.load_json(filename)
              return true
            end
          elsif filename =~ /\.xml$/
            if Map.load_xml(filename)
              return true
            end
          else
            if Map.load_dat(filename)
              return true
            end
          end
        end
        return false
      end

      # Loads map data from a JSON file.
      # @param filename [String, nil] The filename to load from (default: nil).
      # @return [Boolean] True if loading was successful, false otherwise.
      def Map.load_json(filename = nil)
        @@load_mutex.synchronize {
          if @@loaded
            return true
          else
            if filename
              file_list = [filename]
              # respond "--- loading #{filename}" #if error
            else
              file_list = Dir.entries("#{DATA_DIR}/#{XMLData.game}").find_all { |filename|
                filename =~ /^map\-[0-9]+\.json$/i
              }.collect { |filename|
                "#{DATA_DIR}/#{XMLData.game}/#{filename}"
              }.sort.reverse
              # respond "--- loading #{filename}" #if error
            end
            if file_list.empty?
              respond "--- Lich: error: no map database found"
              return false
            end
            while (filename = file_list.shift)
              if File.exist?(filename)
                File.open(filename) { |f|
                  JSON.parse(f.read).each { |room|
                    room['wayto'].keys.each { |k|
                      if room['wayto'][k][0..2] == ';e '
                        room['wayto'][k] = StringProc.new(room['wayto'][k][3..-1])
                      end
                    }
                    room['timeto'].keys.each { |k|
                      if (room['timeto'][k].is_a?(String)) and (room['timeto'][k][0..2] == ';e ')
                        room['timeto'][k] = StringProc.new(room['timeto'][k][3..-1])
                      end
                    }
                    room['tags'] ||= []
                    room['uid'] ||= []
                    Map.new(room['id'], room['title'], room['description'], room['paths'], room['uid'], room['location'], room['climate'], room['terrain'], room['wayto'], room['timeto'], room['image'], room['image_coords'], room['tags'], room['check_location'], room['unique_loot'])
                  }
                }
                @@tags.clear
                respond "--- Map loaded #{filename}" # if error
                @@loaded = true
                Map.load_uids
                return true
              end
            end
          end
        }
      end

      # Loads map data from a DAT file.
      # @param filename [String, nil] The filename to load from (default: nil).
      # @return [Boolean] True if loading was successful, false otherwise.
      def Map.load_dat(filename = nil)
        @@load_mutex.synchronize {
          if @@loaded
            return true
          else
            if filename.nil?
              file_list = Dir.entries("#{DATA_DIR}/#{XMLData.game}").find_all { |filename| filename =~ /^map\-[0-9]+\.dat$/ }.collect { |filename| "#{DATA_DIR}/#{XMLData.game}/#{filename}" }.sort.reverse
            else
              file_list = [filename]
              respond "--- file_list = #{filename.inspect}"
            end
            if file_list.empty?
              respond "--- Lich: error: no map database found"
              return false
            end
            while (filename = file_list.shift)
              begin
                @@list = File.open(filename, 'rb') { |f| Marshal.load(f.read) }
                respond "--- Map loaded #{filename}" # if error

                @@loaded = true
                Map.load_uids
                return true
              rescue
                if file_list.empty?
                  respond "--- Lich: error: failed to load #{filename}: #{$!}"
                else
                  respond "--- warning: failed to load #{filename}: #{$!}"
                end
              end
            end
            return false
          end
        }
      end

      # Loads map data from an XML file.
      # @param filename [String] The filename to load from (default: "#{DATA_DIR}/#{XMLData.game}/map.xml").
      # @return [Boolean] True if loading was successful, false otherwise.
      def Map.load_xml(filename = "#{DATA_DIR}/#{XMLData.game}/map.xml")
        @@load_mutex.synchronize {
          if @@loaded
            return true
          else
            unless File.exist?(filename)
              raise Exception.exception("MapDatabaseError"), "Fatal error: file `#{filename}' does not exist!"
            end
            missing_end = false
            current_tag = nil
            current_attributes = nil
            room = nil
            buffer = String.new
            unescape = { 'lt' => '<', 'gt' => '>', 'quot' => '"', 'apos' => "'", 'amp' => '&' }
            tag_start = proc { |element, attributes|
              current_tag = element
              current_attributes = attributes
              if element == 'room'
                room = Hash.new
                room['id'] = attributes['id'].to_i
                room['location'] = attributes['location']
                room['climate'] = attributes['climate']
                room['terrain'] = attributes['terrain']
                room['wayto'] = Hash.new
                room['timeto'] = Hash.new
                room['title'] = Array.new
                room['description'] = Array.new
                room['paths'] = Array.new
                room['tags'] = Array.new
                room['unique_loot'] = Array.new
                room['uid'] = Array.new
                room['room_objects'] = Array.new
              elsif element =~ /^(?:image|tsoran)$/ and attributes['name'] and attributes['x'] and attributes['y'] and attributes['size']
                room['image'] = attributes['name']
                room['image_coords'] = [(attributes['x'].to_i - (attributes['size'] / 2.0).round), (attributes['y'].to_i - (attributes['size'] / 2.0).round), (attributes['x'].to_i + (attributes['size'] / 2.0).round), (attributes['y'].to_i + (attributes['size'] / 2.0).round)]
              elsif (element == 'image') and attributes['name'] and attributes['coords'] and (attributes['coords'] =~ /[0-9]+,[0-9]+,[0-9]+,[0-9]+/)
                room['image'] = attributes['name']
                room['image_coords'] = attributes['coords'].split(',').collect { |num| num.to_i }
              elsif element == 'map'
                missing_end = true
              end
            }
            text = proc { |text_string|
              if current_tag == 'tag'
                room['tags'].push(text_string)
              elsif current_tag =~ /^(?:title|description|paths|unique_loot|tag|room_objects)$/
                room[current_tag].push(text_string)
              elsif current_tag =~ /^(?:uid)$/
                room[current_tag].push(text_string.to_i)
              elsif current_tag == 'exit' and current_attributes['target']
                if current_attributes['type'].downcase == 'string'
                  room['wayto'][current_attributes['target']] = text_string
                end
                if current_attributes['cost'] =~ /^[0-9\.]+$/
                  room['timeto'][current_attributes['target']] = current_attributes['cost'].to_f
                elsif current_attributes['cost'].length > 0
                  room['timeto'][current_attributes['target']] = StringProc.new(current_attributes['cost'])
                else
                  room['timeto'][current_attributes['target']] = 0.2
                end
              end
            }
            tag_end = proc { |element|
              if element == 'room'
                room['unique_loot'] = nil if room['unique_loot'].empty?
                room['room_objects'] = nil if room['room_objects'].empty?
                Map.new(room['id'], room['title'], room['description'], room['paths'], room['uid'], room['location'], room['climate'], room['terrain'], room['wayto'], room['timeto'], room['image'], room['image_coords'], room['tags'], room['check_location'], room['unique_loot'], room['room_objects'])
              elsif element == 'map'
                missing_end = false
              end
              current_tag = nil
            }
            begin
              File.open(filename) { |file|
                while (line = file.gets)
                  buffer.concat(line)
                  # fixme: remove   (?=<)   ?
                  while (str = buffer.slice!(/^<([^>]+)><\/\1>|^[^<]+(?=<)|^<[^<]+>/))
                    if str[0, 1] == '<'
                      if str[1, 1] == '/'
                        element = /^<\/([^\s>\/]+)/.match(str).captures.first
                        tag_end.call(element)
                      else
                        if str =~ /^<([^>]+)><\/\1>/
                          element = $1
                          tag_start.call(element)
                          text.call('')
                          tag_end.call(element)
                        else
                          element = /^<([^\s>\/]+)/.match(str).captures.first
                          attributes = Hash.new
                          str.scan(/([A-z][A-z0-9_\-]*)=(["'])(.*?)\2/).each { |attr| attributes[attr[0]] = attr[2].gsub(/&(#{unescape.keys.join('|')});/) { unescape[$1] } }
                          tag_start.call(element, attributes)
                          tag_end.call(element) if str[-2, 1] == '/'
                        end
                      end
                    else
                      text.call(str.gsub(/&(#{unescape.keys.join('|')});/) { unescape[$1] })
                    end
                  end
                end
              }
              if missing_end
                respond "--- Lich: error: failed to load #{filename}: unexpected end of file"
                return false
              end
              @@tags.clear
              Map.load_uids
              @@loaded = true
              return true
            rescue
              respond "--- Lich: error: failed to load #{filename}: #{$!}"
              return false
            end
          end
        }
      end

      # Saves the current map data to a DAT file.
      # @param filename [String] The filename to save to (default: "#{DATA_DIR}/#{XMLData.game}/map-#{Time.now.to_i}.dat").
      # @return [Boolean] True if saving was successful, false otherwise.
      def Map.save(filename = "#{DATA_DIR}/#{XMLData.game}/map-#{Time.now.to_i}.dat")
        if File.exist?(filename)
          respond "--- Backing up map database"
          begin
            # fixme: does this work on all platforms? File.rename(filename, "#{filename}.bak")
            File.open(filename, 'rb') { |infile|
              File.open("#{filename}.bak", 'wb') { |outfile|
                outfile.write(infile.read)
              }
            }
          rescue
            respond "--- Lich: error: #{$!}"
          end
        end
        begin
          File.open(filename, 'wb') { |f| f.write(Marshal.dump(@@list)) }
          @@tags.clear
          respond "--- Map database saved"
        rescue
          respond "--- Lich: error: #{$!}"
        end
      end

      # Converts the map data to JSON format.
      # @param args [Array] Additional arguments for JSON generation.
      # @return [String] The JSON representation of the map.
      def Map.to_json(*args)
        @@list.delete_if { |r| r.nil? }
        @@list.to_json(args)
      end

      # Converts the map room to JSON format.
      # @param _args [Array] Additional arguments for JSON generation.
      # @return [String] The JSON representation of the room.
      def to_json(*_args)
        mapjson = ({
          :id             => @id,
          :title          => @title,
          :description    => @description,
          :paths          => @paths,
          :location       => @location,
          :climate        => @climate,
          :terrain        => @terrain,
          :wayto          => @wayto,
          :timeto         => @timeto,
          :image          => @image,
          :image_coords   => @image_coords,
          :tags           => @tags,
          :check_location => @check_location,
          :unique_loot    => @unique_loot,
          :uid            => @uid,
        }).delete_if { |_a, b| b.nil? or (b.is_a?(Array) and b.empty?) };
        JSON.pretty_generate(mapjson);
      end

      # Saves the current map data to a JSON file.
      # @param filename [String] The filename to save to (default: "#{DATA_DIR}/#{XMLData.game}/map-#{Time.now.to_i}.json").
      # @return [Boolean] True if saving was successful, false otherwise.
      def Map.save_json(filename = "#{DATA_DIR}/#{XMLData.game}/map-#{Time.now.to_i}.json")
        if File.exist?(filename)
          respond "File exists!  Backing it up before proceeding..."
          begin
            File.open(filename, 'rb') { |infile|
              File.open("#{filename}.bak", "wb:UTF-8") { |outfile|
                outfile.write(infile.read)
              }
            }
          rescue
            respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
            Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
          end
        end
        File.open(filename, 'wb:UTF-8') { |file|
          file.write(Map.to_json)
        }
        respond "#{filename} saved"
      end

      # Saves the current map data to an XML file.
      # @param filename [String] The filename to save to (default: "#{DATA_DIR}/#{XMLData.game}/map-#{Time.now.to_i}.xml").
      # @return [Boolean] True if saving was successful, false otherwise.
      def Map.save_xml(filename = "#{DATA_DIR}/#{XMLData.game}/map-#{Time.now.to_i}.xml")
        if File.exist?(filename)
          respond "File exists!  Backing it up before proceeding..."
          begin
            File.open(filename, 'rb') { |infile|
              File.open("#{filename}.bak", "wb") { |outfile|
                outfile.write(infile.read)
              }
            }
          rescue
            respond "--- Lich: error: #{$!}\n\t#{$!.backtrace[0..1].join("\n\t")}"
            Lich.log "error: #{$!}\n\t#{$!.backtrace.join("\n\t")}"
          end
        end
        begin
          escape = { '<' => '&lt;', '>' => '&gt;', '"' => '&quot;', "'" => "&apos;", '&' => '&amp;' }
          File.open(filename, 'w') { |file|
            file.write "<map>\n"
            @@list.each { |room|
              next if room == nil
              if room.location
                location = " location=#{(room.location.gsub(/(<|>|"|'|&)/) { escape[$1] }).inspect}"
              else
                location = ''
              end
              if room.climate
                climate = " climate=#{(room.climate.gsub(/(<|>|"|'|&)/) { escape[$1] }).inspect}"
              else
                climate = ''
              end
              if room.terrain
                terrain = " terrain=#{(room.terrain.gsub(/(<|>|"|'|&)/) { escape[$1] }).inspect}"
              else
                terrain = ''
              end
              file.write "   <room id=\"#{room.id}\"#{location}#{climate}#{terrain}>\n"
              room.title.each { |title| file.write "      <title>#{title.gsub(/(<|>|"|'|&)/) { escape[$1] }}</title>\n" }
              room.description.each { |desc| file.write "      <description>#{desc.gsub(/(<|>|"|'|&)/) { escape[$1] }}</description>\n" }
              room.paths.each { |paths| file.write "      <paths>#{paths.gsub(/(<|>|"|'|&)/) { escape[$1] }}</paths>\n" }
              room.tags.each { |tag| file.write "      <tag>#{tag.gsub(/(<|>|"|'|&)/) { escape[$1] }}</tag>\n" }
              room.uid.each { |u| file.write "      <uid>#{u}</uid>\n" }
              room.unique_loot.to_a.each { |loot| file.write "      <unique_loot>#{loot.gsub(/(<|>|"|'|&)/) { escape[$1] }}</unique_loot>\n" }
              room.room_objects.to_a.each { |loot| file.write "      <room_objects>#{loot.gsub(/(<|>|"|'|&)/) { escape[$1] }}</room_objects>\n" }
              file.write "      <image name=\"#{room.image.gsub(/(<|>|"|'|&)/) { escape[$1] }}\" coords=\"#{room.image_coords.join(',')}\" />\n" if room.image and room.image_coords
              room.wayto.keys.each { |target|
                if room.timeto[target].is_a?(StringProc)
                  cost = " cost=\"#{room.timeto[target]._dump.gsub(/(<|>|"|'|&)/) { escape[$1] }}\""
                elsif room.timeto[target]
                  cost = " cost=\"#{room.timeto[target]}\""
                else
                  cost = ''
                end
                if room.wayto[target].is_a?(StringProc)
                  file.write "      <exit target=\"#{target}\" type=\"Proc\"#{cost}>#{room.wayto[target]._dump.gsub(/(<|>|"|'|&)/) { escape[$1] }}</exit>\n"
                else
                  file.write "      <exit target=\"#{target}\" type=\"#{room.wayto[target].class}\"#{cost}>#{room.wayto[target].gsub(/(<|>|"|'|&)/) { escape[$1] }}</exit>\n"
                end
              }
              file.write "   </room>\n"
            }
            file.write "</map>\n"
          }
          @@tags.clear
          respond "--- map database saved to: #{filename}"
        rescue
          respond $!
        end
        GC.start
      end

      # Estimates the time to traverse a list of rooms.
      # @param array [Array<Integer>] The list of room IDs to estimate time for.
      # @return [Float] The estimated time to traverse the rooms.
      # @raise [Exception] If the input is not an array.
      def Map.estimate_time(array)
        Map.load unless @@loaded
        unless array.is_a?(Array)
          raise Exception.exception("MapError"), "Map.estimate_time was given something not an array!"
        end
        time = 0.to_f
        until array.length < 2
          room = array.shift
          if (t = Map[room].timeto[array.first.to_s])
            if t.is_a?(StringProc)
              time += t.call.to_f
            else
              time += t.to_f
            end
          else
            time += "0.2".to_f
          end
        end
        time
      end

      # Performs Dijkstra's algorithm to find the shortest path.
      # @param source [Map, Integer] The source room or its ID.
      # @param destination [Integer, nil] The destination room ID (default: nil).
      # @return [Array<Integer>, Array<Float>] The previous rooms and shortest distances.
      def Map.dijkstra(source, destination = nil)
        if source.is_a?(Map)
          source.dijkstra(destination)
        elsif (room = Map[source])
          room.dijkstra(destination)
        else
          echo "Map.dijkstra: error: invalid source room"
          nil
        end
      end

      # Performs Dijkstra's algorithm for the current room.
      # @param destination [Integer, nil] The destination room ID (default: nil).
      # @return [Array<Integer>, Array<Float>] The previous rooms and shortest distances.
      def dijkstra(destination = nil)
        begin
          Map.load unless @@loaded
          source = @id
          visited = Array.new
          shortest_distances = Array.new
          previous = Array.new
          pq = [source]
          pq_push = proc { |val|
            for i in 0...pq.size
              if shortest_distances[val] <= shortest_distances[pq[i]]
                pq.insert(i, val)
                break
              end
            end
            pq.push(val) if i.nil? or (i == pq.size - 1)
          }
          visited[source] = true
          shortest_distances[source] = 0
          if destination.nil?
            until pq.size == 0
              v = pq.shift
              visited[v] = true
              @@list[v].wayto.keys.each { |adj_room|
                adj_room_i = adj_room.to_i
                unless visited[adj_room_i]
                  if @@list[v].timeto[adj_room].is_a?(StringProc)
                    nd = @@list[v].timeto[adj_room].call
                  else
                    nd = @@list[v].timeto[adj_room]
                  end
                  if nd
                    nd += shortest_distances[v]
                    if shortest_distances[adj_room_i].nil? or (shortest_distances[adj_room_i] > nd)
                      shortest_distances[adj_room_i] = nd
                      previous[adj_room_i] = v
                      pq_push.call(adj_room_i)
                    end
                  end
                end
              }
            end
          elsif destination.is_a?(Integer)
            until pq.size == 0
              v = pq.shift
              break if v == destination
              visited[v] = true
              @@list[v].wayto.keys.each { |adj_room|
                adj_room_i = adj_room.to_i
                unless visited[adj_room_i]
                  if @@list[v].timeto[adj_room].is_a?(StringProc)
                    nd = @@list[v].timeto[adj_room].call
                  else
                    nd = @@list[v].timeto[adj_room]
                  end
                  if nd
                    nd += shortest_distances[v]
                    if shortest_distances[adj_room_i].nil? or (shortest_distances[adj_room_i] > nd)
                      shortest_distances[adj_room_i] = nd
                      previous[adj_room_i] = v
                      pq_push.call(adj_room_i)
                    end
                  end
                end
              }
            end
          elsif destination.is_a?(Array)
            dest_list = destination.collect { |dest| dest.to_i }
            until pq.size == 0
              v = pq.shift
              break if dest_list.include?(v) and (shortest_distances[v] < 20)
              visited[v] = true
              @@list[v].wayto.keys.each { |adj_room|
                adj_room_i = adj_room.to_i
                unless visited[adj_room_i]
                  if @@list[v].timeto[adj_room].is_a?(StringProc)
                    nd = @@list[v].timeto[adj_room].call
                  else
                    nd = @@list[v].timeto[adj_room]
                  end
                  if nd
                    nd += shortest_distances[v]
                    if shortest_distances[adj_room_i].nil? or (shortest_distances[adj_room_i] > nd)
                      shortest_distances[adj_room_i] = nd
                      previous[adj_room_i] = v
                      pq_push.call(adj_room_i)
                    end
                  end
                end
              }
            end
          end
          return previous, shortest_distances
        rescue
          echo "Map.dijkstra: error: #{$!}"
          respond $!.backtrace
          nil
        end
      end

      # Finds a path from the source room to the destination.
      # @param source [Map, Integer] The source room or its ID.
      # @param destination [Integer] The destination room ID.
      # @return [Array<Integer>, nil] The path as an array of room IDs or nil if no path exists.
      def Map.findpath(source, destination)
        if source.is_a?(Map)
          source.path_to(destination)
        elsif (room = Map[source])
          room.path_to(destination)
        else
          echo "Map.findpath: error: invalid source room"
          nil
        end
      end

      # Finds a path to the specified destination room.
      # @param destination [Integer] The destination room ID.
      # @return [Array<Integer>, nil] The path as an array of room IDs or nil if no path exists.
      def path_to(destination)
        Map.load unless @@loaded
        destination = destination.to_i
        previous, _ = dijkstra(destination)
        return nil unless previous[destination]
        path = [destination]
        path.push(previous[path[-1]]) until previous[path[-1]] == @id
        path.reverse!
        path.pop
        return path
      end

      # Finds the nearest room with the specified tag.
      # @param tag_name [String] The tag to search for.
      # @return [Integer] The ID of the nearest room with the tag.
      def find_nearest_by_tag(tag_name)
        target_list = Array.new
        @@list.each { |room| target_list.push(room.id) if room.tags.include?(tag_name) }
        _, shortest_distances = Map.dijkstra(@id, target_list)
        if target_list.include?(@id)
          @id
        else
          target_list.delete_if { |room_num| shortest_distances[room_num].nil? }
          target_list.sort { |a, b| shortest_distances[a] <=> shortest_distances[b] }.first
        end
      end

      # Finds all nearest rooms with the specified tag.
      # @param tag_name [String] The tag to search for.
      # @return [Array<Integer>] An array of IDs of the nearest rooms with the tag.
      def find_all_nearest_by_tag(tag_name)
        target_list = Array.new
        @@list.each { |room| target_list.push(room.id) if room.tags.include?(tag_name) }
        _, shortest_distances = Map.dijkstra(@id)
        target_list.delete_if { |room_num| shortest_distances[room_num].nil? }
        target_list.sort { |a, b| shortest_distances[a] <=> shortest_distances[b] }
      end

      # Finds the nearest room from a list of target rooms.
      # @param target_list [Array<Integer>] The list of target room IDs.
      # @return [Integer] The ID of the nearest room.
      def find_nearest(target_list)
        target_list = target_list.collect { |num| num.to_i }
        if target_list.include?(@id)
          @id
        else
          _previous, shortest_distances = Map.dijkstra(@id, target_list)
          valid_rooms = target_list.select { |room_num| shortest_distances[room_num].is_a?(Numeric) }
          return valid_rooms.min_by { |room_num| shortest_distances[room_num] }
        end
      end
    end

    # Represents a room in the Lich game.
    # Inherits from Map and can be used to extend functionality.
    # @example Creating a room
    #   room = Lich::Common::Room.new(1, "Room Title", "Room Description", ["path1", "path2"])
    class Room < Map
      def Room.method_missing(*args)
        super(*args)
      end
    end

    # deprecated
    # Deprecated class for map functionality.
    # This class is kept for backward compatibility.
    class Map
      # Returns the description of the room.
      # @return [String] The description of the room.
      def desc
        @description
      end

      # Returns the name of the map.
      # @return [String] The name of the map.
      def map_name
        @image
      end

      # Returns the X coordinate of the map image.
      # @return [Integer, nil] The X coordinate or nil if not set.
      def map_x
        if @image_coords.nil?
          nil
        else
          ((image_coords[0] + image_coords[2]) / 2.0).round
        end
      end

      # Returns the Y coordinate of the map image.
      # @return [Integer, nil] The Y coordinate or nil if not set.
      def map_y
        if @image_coords.nil?
          nil
        else
          ((image_coords[1] + image_coords[3]) / 2.0).round
        end
      end

      # Returns the size of the room based on image coordinates.
      # @return [Integer, nil] The size of the room or nil if not set.
      def map_roomsize
        if @image_coords.nil?
          nil
        else
          image_coords[2] - image_coords[0]
        end
      end

      # Returns geographical information for the room.
      # @return [nil] Always returns nil.
      def geo
        nil
      end
    end
  end
end
