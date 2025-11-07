# The Lich module provides various functionalities for the Lich5 project.
# It serves as a namespace for different components.
# @example Using the Lich module
#   Lich::Currency.silver
module Lich
  # The Currency module provides methods to retrieve various types of currency.
  # It interacts with the Infomon service to fetch currency data.
  # @example Fetching silver currency
  #   silver_amount = Lich::Currency.silver
  module Currency
    # Retrieves the amount of silver currency.
    # @return [Integer] The amount of silver.
    # @example Fetching silver
    #   amount = Lich::Currency.silver
    def self.silver
      Lich::Gemstone::Infomon.get('currency.silver')
    end

    # Retrieves the silver container information.
    # @return [String] The silver container details.
    # @example Fetching silver container
    #   container = Lich::Currency.silver_container
    def self.silver_container
      Lich::Gemstone::Infomon.get('currency.silver_container')
    end

    # Retrieves the amount of redsteel marks currency.
    # @return [Integer] The amount of redsteel marks.
    # @example Fetching redsteel marks
    #   marks = Lich::Currency.redsteel_marks
    def self.redsteel_marks
      Lich::Gemstone::Infomon.get('currency.redsteel_marks')
    end

    # Retrieves the amount of tickets currency.
    # @return [Integer] The amount of tickets.
    # @example Fetching tickets
    #   ticket_count = Lich::Currency.tickets
    def self.tickets
      Lich::Gemstone::Infomon.get('currency.tickets')
    end

    # Retrieves the amount of blackscrip currency.
    # @return [Integer] The amount of blackscrip.
    # @example Fetching blackscrip
    #   scrip_amount = Lich::Currency.blackscrip
    def self.blackscrip
      Lich::Gemstone::Infomon.get('currency.blackscrip')
    end

    # Retrieves the amount of bloodscrip currency.
    # @return [Integer] The amount of bloodscrip.
    # @example Fetching bloodscrip
    #   bloodscrip_amount = Lich::Currency.bloodscrip
    def self.bloodscrip
      Lich::Gemstone::Infomon.get('currency.bloodscrip')
    end

    # Retrieves the amount of ethereal scrip currency.
    # @return [Integer] The amount of ethereal scrip.
    # @example Fetching ethereal scrip
    #   ethereal_amount = Lich::Currency.ethereal_scrip
    def self.ethereal_scrip
      Lich::Gemstone::Infomon.get('currency.ethereal_scrip')
    end

    # Retrieves the amount of raikhen currency.
    # @return [Integer] The amount of raikhen.
    # @example Fetching raikhen
    #   raikhen_amount = Lich::Currency.raikhen
    def self.raikhen
      Lich::Gemstone::Infomon.get('currency.raikhen')
    end

    # Retrieves the amount of elans currency.
    # @return [Integer] The amount of elans.
    # @example Fetching elans
    #   elans_amount = Lich::Currency.elans
    def self.elans
      Lich::Gemstone::Infomon.get('currency.elans')
    end

    # Retrieves the amount of soul shards currency.
    # @return [Integer] The amount of soul shards.
    # @example Fetching soul shards
    #   soul_shard_amount = Lich::Currency.soul_shards
    def self.soul_shards
      Lich::Gemstone::Infomon.get('currency.soul_shards')
    end

    # Retrieves the amount of gigas artifact fragments currency.
    # @return [Integer] The amount of gigas artifact fragments.
    # @example Fetching gigas artifact fragments
    #   fragments = Lich::Currency.gigas_artifact_fragments
    def self.gigas_artifact_fragments
      Lich::Gemstone::Infomon.get('currency.gigas_artifact_fragments')
    end

    # Retrieves the amount of gemstone dust currency.
    # @return [Integer] The amount of gemstone dust.
    # @example Fetching gemstone dust
    #   dust_amount = Lich::Currency.gemstone_dust
    def self.gemstone_dust
      Lich::Gemstone::Infomon.get('currency.gemstone_dust')
    end
  end
end
