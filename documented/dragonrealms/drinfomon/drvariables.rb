# Lich module containing various constants and data structures for the DragonRealms game.
# @example
#   include Lich::DragonRealms
module Lich
  # Module containing constants related to DragonRealms gameplay mechanics.
  # @example
  #   puts Lich::DragonRealms::DR_LEARNING_RATES
  module DragonRealms
    # Array of learning rates used in the game.
    # @return [Array<String>] An array of strings representing different learning rates.
    DR_LEARNING_RATES = [
      'clear',
      'dabbling',
      'perusing',
      'learning',
      'thoughtful',
      'thinking',
      'considering',
      'pondering',
      'ruminating',
      'concentrating',
      'attentive',
      'deliberative',
      'interested',
      'examining',
      'understanding',
      'absorbing',
      'intrigued',
      'scrutinizing',
      'analyzing',
      'studious',
      'focused',
      'very focused',
      'engaged',
      'very engaged',
      'cogitating',
      'fascinated',
      'captivated',
      'engrossed',
      'riveted',
      'very riveted',
      'rapt',
      'very rapt',
      'enthralled',
      'nearly locked',
      'mind lock'
    ]

    # Array of balance values used in the game.
    # @return [Array<String>] An array of strings representing different balance values.
    DR_BALANCE_VALUES = [
      'completely',
      'hopelessly',
      'extremely',
      'very badly',
      'badly',
      'somewhat off',
      'off',
      'slightly off',
      'solidly',
      'nimbly',
      'adeptly',
      'incredibly'
    ]

    # Hash containing skill data for various skillsets in the game.
    # @return [Hash] A hash with skillsets and their corresponding skills.
    DR_SKILLS_DATA = {
      "skillsets": {
        "Armor": [
          "Shield Usage",
          "Light Armor",
          "Chain Armor",
          "Brigandine",
          "Plate Armor",
          "Defending",
          "Conviction"
        ],
        "Lore": [
          "Alchemy",
          "Appraisal",
          "Enchanting",
          "Engineering",
          "Forging",
          "Outfitting",
          "Performance",
          "Scholarship",
          "Tactics",
          "Empathy",
          "Bardic Lore",
          "Trading",
          "Mechanical Lore"
        ],
        "Weapon": [
          "Parry Ability",
          "Small Edged",
          "Large Edged",
          "Twohanded Edged",
          "Small Blunt",
          "Large Blunt",
          "Twohanded Blunt",
          "Slings",
          "Bow",
          "Crossbow",
          "Staves",
          "Polearms",
          "Light Thrown",
          "Heavy Thrown",
          "Brawling",
          "Offhand Weapon",
          "Melee Mastery",
          "Missile Mastery",
          "Expertise"
        ],
        "Magic": [
          "Primary Magic",
          "Arcana",
          "Attunement",
          "Augmentation",
          "Debilitation",
          "Targeted Magic",
          "Utility",
          "Warding",
          "Sorcery",
          "Astrology",
          "Summoning",
          "Theurgy",
          "Inner Magic",
          "Inner Fire",
          "Lunar Magic",
          "Elemental Magic",
          "Holy Magic",
          "Life Magic",
          "Arcane Magic"
        ],
        "Survival": [
          "Evasion",
          "Athletics",
          "Perception",
          "Stealth",
          "Locksmithing",
          "Thievery",
          "First Aid",
          "Outdoorsmanship",
          "Skinning",
          "Instinct",
          "Backstab",
          "Thanatology"
        ]
      },
      "guild_skill_aliases": {
        "Cleric"       => { "Primary Magic" => "Holy Magic" },
        "Necromancer"  => { "Primary Magic" => "Arcane Magic" },
        "Warrior Mage" => { "Primary Magic" => "Elemental Magic" },
        "Thief"        => { "Primary Magic" => "Inner Magic" },
        "Barbarian"    => { "Primary Magic" => "Inner Fire" },
        "Ranger"       => { "Primary Magic" => "Life Magic" },
        "Bard"         => { "Primary Magic" => "Elemental Magic" },
        "Paladin"      => { "Primary Magic" => "Holy Magic" },
        "Empath"       => { "Primary Magic" => "Life Magic" },
        "Trader"       => { "Primary Magic" => "Lunar Magic" },
        "Moon Mage"    => { "Primary Magic" => "Lunar Magic" }
      }
    }

    # Array of bank names in the Kronar region.
    # @return [Array<String>] An array of strings representing bank names.
    KRONAR_BANKS = ['Crossings', 'Dirge', 'Ilaya Taipa', 'Leth Deriel']
    # Array of bank names in the Lirum region.
    # @return [Array<String>] An array of strings representing bank names.
    LIRUM_BANKS = ["Aesry Surlaenis'a", "Hara'jaal", "Mer'Kresh", "Muspar'i", "Ratha", "Riverhaven", "Rossman's Landing", "Therenborough", "Throne City"]
    # Array of bank names in the Dokora region.
    # @return [Array<String>] An array of strings representing bank names.
    DOKORA_BANKS = ["Ain Ghazal", "Boar Clan", "Chyolvea Tayeu'a", "Hibarnhvidar", "Fang Cove", "Raven's Point", "Shard"]

    # Hash mapping bank names to their titles.
    # @return [Hash] A hash where keys are bank names and values are arrays of titles.
    BANK_TITLES = {
      "Aesry Surlaenis'a" => ["[[Tona Kertigen, Deposit Window]]"],
      "Ain Ghazal"        => ["[[Ain Ghazal, Private Depository]]"],
      "Boar Clan"         => ["[[Ranger Guild, Bank]]"],
      "Chyolvea Tayeu'a"  => ["[[Chyolvea Tayeu'a, Teller]]"],
      "Crossings"         => ["[[Provincial Bank, Teller]]"],
      "Dirge"             => ["[[Dirge, Traveller's Bank]]"],
      "Fang Cove"         => ["[[First Council Banking, Vault]]"],
      "Hara'jaal"         => ["[[Baron's Forset, Teller]]"],
      "Hibarnhvidar"      => ["[[Second Provincial Bank of Hibarnhvidar, Teller]]", "[[Hibarnhvidar, Teller Windows]]", "[[First Arachnid Bank, Lobby]]"],
      "Ilaya Taipa"       => ["[[Ilaya Taipa, Trader Outpost Bank]]"],
      "Leth Deriel"       => ["[[Imperial Depository, Domestic Branch]]"],
      "Mer'Kresh"         => ["[[Harti Clemois Bank, Teller's Window]]"],
      "Muspar'i"          => ["[[Old Lata'arna Keep, Teller Windows]]"],
      "Ratha"             => ["[[Lower Bank of Ratha, Cashier]]", "[[Sshoi-sson Palace, Grand Provincial Bank, Bursarium]]"],
      "Raven's Point"     => ["[[Bank of Raven's Point, Depository]]"],
      "Riverhaven"        => ["[[Bank of Riverhaven, Teller]]"],
      "Rossman's Landing" => ["[[Traders' Guild Outpost, Depository]]"],
      "Shard"             => ["[[First Bank of Ilithi, Teller's Windows]]"],
      "Therenborough"     => ["[[Bank of Therenborough, Teller]]"],
      "Throne City"       => ["[[Faldesu Exchequer, Teller]]"]
    }

    # Hash mapping vault names to their titles.
    # @return [Hash] A hash where keys are vault names and values are arrays of titles.
    VAULT_TITLES = {
      "Crossings"     => ["[[Crossing, Carousel Chamber]]"],
      "Fang Cove"     => ["[[Fang Cove, Carousel Chamber]]"],
      "Leth Deriel"   => ["[[Leth Deriel, Carousel Chamber]]"],
      "Mer'Kresh"     => ["[[Mer'Kresh, Carousel Square]]"],
      "Muspar'i"      => ["[[Muspar'i, Carousel Square]]"],
      "Ratha"         => ["[[Ratha, Carousel Square]]"],
      "Riverhaven"    => ["[[Riverhaven, Carousel Chamber]]"],
      "Shard"         => ["[[Shard, Carousel Chamber]]"],
      "Therenborough" => ["[[Therenborough, Carousel Chamber]]"]
    }

    # Some spells may last for an unknown duration,
    # such as cyclic spells that last as long as
    # the caster can harness mana for it.
    # Or, barbarian abilities when the character
    # doesn't have Power Monger mastery to see true
    # durations but only vague guestimates.
    # In those situations, we set use this value.
    # Constant representing an unknown duration for spells.
    # @return [Integer] A default value indicating unknown duration.
    UNKNOWN_DURATION = 1000 unless defined?(UNKNOWN_DURATION)

    # Hash mapping hometown names to their regex patterns for matching.
    # @return [Hash] A hash where keys are hometown names and values are regex patterns.
    $HOMETOWN_REGEX_MAP = {
      "Arthe Dale"        => /^(arthe( dale)?)$/i,
      "Crossing"          => /^(cross(ing)?)$/i,
      "Darkling Wood"     => /^(darkling( wood)?)$/i,
      "Dirge"             => /^(dirge)$/i,
      "Fayrin's Rest"     => /^(fayrin'?s?( rest)?)$/i,
      "Leth Deriel"       => /^(leth( deriel)?)$/i,
      "Shard"             => /^(shard)$/i,
      "Steelclaw Clan"    => /^(steel( )?claw( clan)?|SCC)$/i,
      "Stone Clan"        => /^(stone( clan)?)$/i,
      "Tiger Clan"        => /^(tiger( clan)?)$/i,
      "Wolf Clan"         => /^(wolf( clan)?)$/i,
      "Riverhaven"        => /^(river|haven|riverhaven)$/i,
      "Rossman's Landing" => /^(rossman'?s?( landing)?)$/i,
      "Therenborough"     => /^(theren(borough)?)$/i,
      "Langenfirth"       => /^(lang(enfirth)?)$/i,
      "Fornsted"          => /^(fornsted)$/i,
      "Hvaral"            => /^(hvaral)$/i,
      "Ratha"             => /^(ratha)$/i,
      "Aesry"             => /^(aesry)$/i,
      "Mer'Kresh"         => /^(mer'?kresh)$/i,
      "Throne City"       => /^(throne( city)?)$/i,
      "Hibarnhvidar"      => /^(hib(arnhvidar)?)$/i,
      "Raven's Point"     => /^(raven'?s?( point)?)$/i,
      "Boar Clan"         => /^(boar( clan)?)$/i,
      "Fang Cove"         => /^(fang( cove)?)$/i,
      "Muspar'i"          => /^(muspar'?i)$/i,
      "Ain Ghazal"        => /^(ain( )?ghazal)$/i
    }

    # List of canonical town names, like 'Therenborough' and 'Langenfirth'.
    # List of canonical town names derived from the regex map.
    # @return [Array<String>] An array of strings representing town names.
    $HOMETOWN_LIST = $HOMETOWN_REGEX_MAP.keys

    # Union of regular expressions that match town names, like /^(theren(borough)?)$/i
    # Union of regex patterns that match town names.
    # @return [Regexp] A regex object that matches various town names.
    $HOMETOWN_REGEX = Regexp.union($HOMETOWN_REGEX_MAP.values)

    # Array of ordinal numbers as strings.
    # @return [Array<String>] An array of strings representing ordinal numbers.
    $ORDINALS = %w[first second third fourth fifth sixth seventh eighth ninth tenth eleventh twelfth thirteenth fourteenth fifteenth sixteenth seventeenth eighteenth nineteenth twentieth]

    # Array of currency types used in the game.
    # @return [Array<String>] An array of strings representing currency types.
    $CURRENCIES = %w[Kronars Lirums Dokoras]

    # Hash mapping encumbrance descriptions to their corresponding values.
    # @return [Hash] A hash where keys are encumbrance descriptions and values are integers.
    $ENC_MAP = {
      'None'                                => 0,
      'Light Burden'                        => 1,
      'Somewhat Burdened'                   => 2,
      'Burdened'                            => 3,
      'Heavy Burden'                        => 4,
      'Very Heavy Burden'                   => 5,
      'Overburdened'                        => 6,
      'Very Overburdened'                   => 7,
      'Extremely Overburdened'              => 8,
      'Tottering Under Burden'              => 9,
      'Are you even able to move?'          => 10,
      'It\'s amazing you aren\'t squashed!' => 11
    }

    # Hash mapping number words to their corresponding integer values.
    # @return [Hash] A hash where keys are number words and values are integers.
    $NUM_MAP = {
      'zero'      => 0,
      'one'       => 1,
      'two'       => 2,
      'three'     => 3,
      'four'      => 4,
      'five'      => 5,
      'six'       => 6,
      'seven'     => 7,
      'eight'     => 8,
      'nine'      => 9,
      'ten'       => 10,
      'eleven'    => 11,
      'twelve'    => 12,
      'thirteen'  => 13,
      'fourteen'  => 14,
      'fifteen'   => 15,
      'sixteen'   => 16,
      'seventeen' => 17,
      'eighteen'  => 18,
      'nineteen'  => 19,
      'twenty'    => 20,
      'thirty'    => 30,
      'forty'     => 40,
      'fifty'     => 50,
      'sixty'     => 60,
      'seventy'   => 70,
      'eighty'    => 80,
      'ninety'    => 90
    }

    # Regex pattern for matching box types in the game.
    # @return [Regexp] A regex object that matches various box types.
    $box_regex = /((?:brass|copper|deobar|driftwood|iron|ironwood|mahogany|oaken|pine|steel|wooden) (?:box|caddy|casket|chest|coffer|crate|skippet|strongbox|trunk))/

    # Hash mapping mana quality descriptions to their corresponding arrays of terms.
    # @return [Hash] A hash where keys are mana quality descriptions and values are arrays of strings.
    $MANA_MAP = {
      'weak'       => %w[dim glowing bright],
      'developing' => %w[faint muted glowing luminous bright],
      'improving'  => %w[faint hazy flickering shimmering glowing lambent shining fulgent glaring],
      'good'       => %w[faint dim hazy dull muted dusky pale flickering shimmering pulsating glowing lambent shining luminous radiant fulgent brilliant flaring glaring blazing blinding]
    }

    # Regex pattern for matching primary sigils in the game.
    # @return [Regexp] A regex object that matches primary sigils.
    $PRIMARY_SIGILS_PATTERN = /\b(?:abolition|congruence|induction|permutation|rarefaction) sigil\b/
    # Regex pattern for matching secondary sigils in the game.
    # @return [Regexp] A regex object that matches secondary sigils.
    $SECONDARY_SIGILS_PATTERN = /\b(?:antipode|ascension|clarification|decay|evolution|integration|metamorphosis|nurture|paradox|unity) sigil\b/

    # Hash mapping volume descriptions to their corresponding values.
    # @return [Hash] A hash where keys are volume descriptions and values are integers.
    $VOL_MAP = {
      'enormous' => 20,
      'massive'  => 10,
      'huge'     => 5,
      'large'    => 4,
      'medium'   => 3,
      'small'    => 2,
      'tiny'     => 1
    }
  end
end
