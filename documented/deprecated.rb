# Carve out deprecated (?) functions
# 2024-06-13

# The current version of the Lich5 project
$version = LICH_VERSION
$room_count = 0
$psinet = false
$stormfront = true

# Checks if the character can survive poison.
# @return [Boolean] Always returns true as there is no XML for poison rate.
# @example
#   result = survivepoison?
#   puts result # => true
def survivepoison?
  echo 'survivepoison? called, but there is no XML for poison rate'
  return true
end

# Checks if the character can survive disease.
# @return [Boolean] Always returns true as there is no XML for disease rate.
# @example
#   result = survivedisease?
#   puts result # => true
def survivedisease?
  echo 'survivepoison? called, but there is no XML for disease rate'
  return true
end

# Fetches loot from the game object and stores it in the user's bag.
# @param userbagchoice [String] The name of the bag to store loot in (default is UserVars.lootsack).
# @return [Boolean] Returns false if there is no loot to fetch, otherwise returns true.
# @example
#   fetchloot
#   fetchloot("my_custom_bag")
def fetchloot(userbagchoice = UserVars.lootsack)
  if GameObj.loot.empty?
    return false
  end

  if UserVars.excludeloot.empty?
    regexpstr = nil
  else
    regexpstr = UserVars.excludeloot.split(', ').join('|')
  end
  if checkright and checkleft
    stowed = GameObj.right_hand.noun
    fput "put my #{stowed} in my #{UserVars.lootsack}"
  else
    stowed = nil
  end
  GameObj.loot.each { |loot|
    unless not regexpstr.nil? and loot.name =~ /#{regexpstr}/
      fput "get #{loot.noun}"
      fput("put my #{loot.noun} in my #{userbagchoice}") if (checkright || checkleft)
    end
  }
  if stowed
    fput "take my #{stowed} from my #{UserVars.lootsack}"
  end
end

# Takes items and stores them in the user's bag.
# @param items [Array<String>] The items to take.
# @return [void]
# @example
#   take("item1", "item2")
def take(*items)
  items.flatten!
  if (righthand? && lefthand?)
    weap = checkright
    fput "put my #{checkright} in my #{UserVars.lootsack}"
    unsh = true
  else
    unsh = false
  end
  items.each { |trinket|
    fput "take #{trinket}"
    fput("put my #{trinket} in my #{UserVars.lootsack}") if (righthand? || lefthand?)
  }
  if unsh then fput("take my #{weap} from my #{UserVars.lootsack}") end
end

# class StringProc
#  def StringProc._load(string)
#    StringProc.new(string)
#  end
# end

# Extends the String class with additional methods for compatibility.
# @example
#   "example string".to_a # => ["example string"]
class String
  # Converts the string to an array containing the string itself.
  # @return [Array<String>] An array with the string as its only element.
  # @example
  #   result = "hello world".to_a
  #   puts result.inspect # => ["hello world"]
  def to_a # for compatibility with Ruby 1.8
    [self]
  end

  # Returns false, indicating that the string is not silent.
  # @return [Boolean] Always returns false.
  # @example
  #   puts "test string".silent # => false
  def silent
    false
  end

  # Splits the string into a list based on specific patterns.
  # @return [Array<String>] An array of trimmed strings.
  # @example
  #   result = "You notice a tree and a rock".split_as_list
  #   puts result.inspect # => ["tree", "rock"]
  def split_as_list
    string = self
    string.sub!(/^You (?:also see|notice) |^In the .+ you see /, ',')
    string.sub('.', '').sub(/ and (an?|some|the)/, ', \1').split(',').reject { |str| str.strip.empty? }.collect { |str| str.lstrip }
  end
end
