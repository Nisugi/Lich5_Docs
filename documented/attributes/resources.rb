# The Lich module provides various utilities for the game.
# @example
#   include Lich
module Lich
  # The Resources module handles resource-related information.
  # @example
  #   Lich::Resources.weekly
  module Resources
    # Retrieves the weekly resources.
    # @return [Object] The weekly resource data.
    # @example
    #   resources = Lich::Resources.weekly
    def self.weekly
      Lich::Gemstone::Infomon.get('resources.weekly')
    end

    # Retrieves the total resources.
    # @return [Object] The total resource data.
    # @example
    #   resources = Lich::Resources.total
    def self.total
      Lich::Gemstone::Infomon.get('resources.total')
    end

    # Retrieves the suffused resources.
    # @return [Object] The suffused resource data.
    # @example
    #   resources = Lich::Resources.suffused
    def self.suffused
      Lich::Gemstone::Infomon.get('resources.suffused')
    end

    # Retrieves the type of resources.
    # @return [Object] The resource type data.
    # @example
    #   resource_type = Lich::Resources.type
    def self.type
      Lich::Gemstone::Infomon.get('resources.type')
    end

    # Retrieves the Voln favor resources.
    # @return [Object] The Voln favor resource data.
    # @example
    #   voln_favor = Lich::Resources.voln_favor
    def self.voln_favor
      Lich::Gemstone::Infomon.get('resources.voln_favor')
    end

    # Retrieves the covert arts charges.
    # @return [Object] The covert arts charges data.
    # @example
    #   charges = Lich::Resources.covert_arts_charges
    def self.covert_arts_charges
      Lich::Gemstone::Infomon.get('resources.covert_arts_charges')
    end

    # Checks the current resources and returns weekly, total, and suffused resources.
    # @param quiet [Boolean] Whether to suppress output (default: false).
    # @return [Array<Object>] An array containing weekly, total, and suffused resource data.
    # @example
    #   resources = Lich::Resources.check(true)
    # @note This method issues a command and may take time to respond.
    def self.check(quiet = false)
      Lich::Util.issue_command('resource', /^Health: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Mana: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Stamina: \d+\/(?:<pushBold\/>)?\d+(?:<popBold\/>)?\s+Spirit: \d+\/(?:<pushBold\/>)?\d+/, /<prompt/, silent: true, quiet: quiet)
      return [self.weekly, self.total, self.suffused]
    end
  end
end
