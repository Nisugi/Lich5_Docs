# Lich module containing various utilities for the DragonRealms game.
# @example
#   include Lich::DragonRealms
module Lich
  module DragonRealms
    # Converts a given amount to copper based on the denomination.
    # @param amt [Numeric] The amount to convert.
    # @param denomination [String] The type of denomination (e.g., 'platinum', 'gold', 'silver', 'bronze').
    # @return [Numeric] The equivalent amount in copper.
    # @example
    #   convert2copper(10, 'gold') #=> 10000
    def convert2copper(amt, denomination)
      if denomination =~ /platinum/
        (amt.to_i * 10_000)
      elsif denomination =~ /gold/
        (amt.to_i * 1000)
      elsif denomination =~ /silver/
        (amt.to_i * 100)
      elsif denomination =~ /bronze/
        (amt.to_i * 10)
      else
        amt
      end
    end

    # Checks the experience modifiers currently in effect.
    # @return [String] The output of the command issued.
    # @example
    #   check_exp_mods
    def check_exp_mods
      Lich::Util.issue_command("exp mods", /The following skills are currently under the influence of a modifier/, /^<output class=""/, quiet: true, include_end: false, usexml: false)
    end

    # Converts a given amount of copper to various denominations.
    # @param copper [Numeric] The amount of copper to convert.
    # @return [String] A string representation of the amount in different denominations.
    # @example
    #   convert2plats(25000) #=> '2 platinum, 5 gold'
    def convert2plats(copper)
      denominations = [[10_000, 'platinum'], [1000, 'gold'], [100, 'silver'], [10, 'bronze'], [1, 'copper']]
      denominations.inject([copper, []]) do |result, denomination|
        remaining = result.first
        display = result.last
        if remaining / denomination.first > 0
          display << "#{remaining / denomination.first} #{denomination.last}"
        end
        [remaining % denomination.first, display]
      end.last.join(', ')
    end

    # Cleans and splits room objects into an array.
    # @param room_objs [String] The string containing room objects.
    # @return [Array<String>] An array of cleaned room object names.
    # @example
    #   clean_and_split("You also see a dragon, a knight.") #=> ['a dragon', 'a knight']
    def clean_and_split(room_objs)
      room_objs.sub(/You also see/, '').sub(/ with a [\w\s]+ sitting astride its back/, '').strip.split(/,|\sand\s/)
    end

    # Finds player characters in the room description.
    # @param room_players [String] The string containing room players.
    # @return [Array<String>] An array of player character names.
    # @example
    #   find_pcs("John who is glowing, Mary who is sitting") #=> ['John', 'Mary']
    def find_pcs(room_players)
      room_players.sub(/ and (.*)$/) { ", #{Regexp.last_match(1)}" }
                  .split(', ')
                  .map { |obj| obj.sub(/ (who|whose body)? ?(has|is|appears|glows) .+/, '').sub(/ \(.+\)/, '') }
                  .map { |obj| obj.strip.scan(/\w+$/).first }
    end

    # Finds player characters that are lying down in the room description.
    # @param room_players [String] The string containing room players.
    # @return [Array<String>] An array of prone player character names.
    # @example
    #   find_pcs_prone("John who is lying down, Mary who is sitting") #=> ['John']
    def find_pcs_prone(room_players)
      room_players.sub(/ and (.*)$/) { ", #{Regexp.last_match(1)}" }
                  .split(', ')
                  .select { |obj| obj =~ /who is lying down/i }
                  .map { |obj| obj.sub(/ who (has|is) .+/, '').sub(/ \(.+\)/, '') }
                  .map { |obj| obj.strip.scan(/\w+$/).first }
    end

    # Finds player characters that are sitting in the room description.
    # @param room_players [String] The string containing room players.
    # @return [Array<String>] An array of sitting player character names.
    # @example
    #   find_pcs_sitting("John who is sitting, Mary who is standing") #=> ['John']
    def find_pcs_sitting(room_players)
      room_players.sub(/ and (.*)$/) { ", #{Regexp.last_match(1)}" }
                  .split(', ')
                  .select { |obj| obj =~ /who is sitting/i }
                  .map { |obj| obj.sub(/ who (has|is) .+/, '').sub(/ \(.+\)/, '') }
                  .map { |obj| obj.strip.scan(/\w+$/).first }
    end

    # Finds all non-player characters (NPCs) in the room description.
    # @param room_objs [String] The string containing room objects.
    # @return [Array<String>] An array of NPC names.
    # @example
    #   find_all_npcs("You also see a goblin, a troll.") #=> ['a goblin', 'a troll']
    def find_all_npcs(room_objs)
      room_objs.sub(/You also see/, '').sub(/ with a [\w\s]+ sitting astride its back/, '').strip
               .scan(%r{<pushBold/>[^<>]*<popBold/> which appears dead|<pushBold/>[^<>]*<popBold/> \(dead\)|<pushBold/>[^<>]*<popBold/>})
    end

    # Cleans and normalizes a list of NPC names.
    # @param npc_string [Array<String>] An array of NPC names.
    # @return [Array<String>] A sorted array of cleaned NPC names with ordinals for duplicates.
    # @example
    #   clean_npc_string(['goblin', 'goblin', 'troll']) #=> ['1 goblin', '2 goblin', 'troll']
    def clean_npc_string(npc_string)
      # Normalize NPC names
      normalized_npcs = npc_string
                        .map { |obj| normalize_creature_names(obj) }
                        .map { |obj| remove_html_tags(obj) }
                        .map { |obj| extract_last_creature(obj) }
                        .map { |obj| extract_final_name(obj) }
                        .sort

      # Count occurrences and add ordinals
      add_ordinals_to_duplicates(normalized_npcs)
    end

    # Normalizes specific creature names in the text.
    # @param text [String] The text containing creature names.
    # @return [String] The normalized text.
    # @example
    #   normalize_creature_names("an alfar warrior") #=> 'alfar warrior'
    def normalize_creature_names(text)
      text
        .sub(/.*alfar warrior.*/, 'alfar warrior')
        .sub(/.*sinewy leopard.*/, 'sinewy leopard')
        .sub(/.*lesser naga.*/, 'lesser naga')
    end

    # Removes HTML tags from the given text.
    # @param text [String] The text containing HTML tags.
    # @return [String] The text without HTML tags.
    # @example
    #   remove_html_tags("<pushBold/>a goblin<popBold/>") #=> 'a goblin'
    def remove_html_tags(text)
      text
        .sub('<pushBold/>', '')
        .sub(%r{<popBold/>.*}, '')
    end

    # Extracts the last creature name from a string after 'and'.
    # @param text [String] The text containing creature names.
    # @return [String] The last creature name extracted.
    # @example
    #   extract_last_creature("a goblin and a troll") #=> 'a troll'
    def extract_last_creature(text)
      # Get the last creature name after "and", removing modifiers like "glowing with"
      text.split(/\sand\s/).last.sub(/(?:\sglowing)?\swith\s.*/, '')
    end

    # Extracts just the creature name from the text.
    # @param text [String] The text containing the creature name.
    # @return [String] The extracted creature name.
    # @example
    #   extract_final_name("a goblin") #=> 'goblin'
    def extract_final_name(text)
      # Extract just the creature name (letters, hyphens, apostrophes)
      text.strip.scan(/[A-z'-]+$/).first
    end

    # Adds ordinal numbers to duplicate NPC names in the list.
    # @param npc_list [Array<String>] The list of NPC names.
    # @return [Array<String>] The list with ordinals added to duplicates.
    # @example
    #   add_ordinals_to_duplicates(['goblin', 'goblin', 'troll']) #=> ['1 goblin', '2 goblin', 'troll']
    def add_ordinals_to_duplicates(npc_list)
      flat_npcs = []

      npc_list.uniq.each do |npc|
        # Count how many times this NPC appears
        count = npc_list.count(npc)

        # Create entries with ordinals for duplicates
        count.times do |index|
          name = index.zero? ? npc : "#{$ORDINALS[index]} #{npc}"
          flat_npcs << name
        end
      end

      flat_npcs
    end

    # Finds all NPCs in the room that are not dead.
    # @param room_objs [String] The string containing room objects.
    # @return [Array<String>] An array of living NPC names.
    # @example
    #   find_npcs("You also see a goblin which appears dead, a troll.") #=> ['a troll']
    def find_npcs(room_objs)
      npcs = find_all_npcs(room_objs).reject { |obj| obj =~ /which appears dead|\(dead\)/ }
      clean_npc_string(npcs)
    end

    # Finds all NPCs in the room that are dead.
    # @param room_objs [String] The string containing room objects.
    # @return [Array<String>] An array of dead NPC names.
    # @example
    #   find_dead_npcs("You also see a goblin which appears dead, a troll.") #=> ['a goblin']
    def find_dead_npcs(room_objs)
      dead_npcs = find_all_npcs(room_objs).select { |obj| obj =~ /which appears dead|\(dead\)/ }
      clean_npc_string(dead_npcs)
    end

    # Finds and cleans object names in the room description.
    # @param room_objs [String] The string containing room objects.
    # @return [Array<String>] An array of cleaned object names.
    # @example
    #   find_objects("<pushBold/>a goblin<popBold/>, a troll.") #=> ['goblin', 'a troll']
    def find_objects(room_objs)
      room_objs.sub!("<pushBold/>a domesticated gelapod<popBold/>", 'domesticated gelapod')
      clean_and_split(room_objs)
        .reject { |obj| obj =~ /pushBold/ }
        .map { |obj| obj.sub(/\.$/, '').strip.sub(/^a /, '').strip.sub(/^some /, '') }
    end
  end
end
