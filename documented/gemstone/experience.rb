require "ostruct"

# Contains the Lich module
# This module serves as a namespace for the Lich project.
module Lich
  # Contains the Gemstone module
  # This module serves as a namespace for gemstone-related functionalities.
  module Gemstone
    # Provides methods to access experience-related data
    # This module includes methods to retrieve various experience metrics.
    # @example Accessing current field experience
    #   current_fxp = Lich::Gemstone::Experience.fxp_current
    module Experience
      # Retrieves the fame value
      # @return [Integer] the current fame value
      # @example
      #   fame_value = Lich::Gemstone::Experience.fame
      def self.fame
        Infomon.get("experience.fame")
      end

      # Retrieves the current field experience
      # @return [Integer] the current field experience
      # @example
      #   current_fxp = Lich::Gemstone::Experience.fxp_current
      def self.fxp_current
        Infomon.get("experience.field_experience_current")
      end

      # Retrieves the maximum field experience
      # @return [Integer] the maximum field experience
      # @example
      #   max_fxp = Lich::Gemstone::Experience.fxp_max
      def self.fxp_max
        Infomon.get("experience.field_experience_max")
      end

      # Retrieves the current experience
      # @return [Integer] the current experience
      # @example
      #   current_exp = Lich::Gemstone::Experience.exp
      def self.exp
        Stats.exp
      end

      # Retrieves the ascension experience
      # @return [Integer] the current ascension experience
      # @example
      #   current_axp = Lich::Gemstone::Experience.axp
      def self.axp
        Infomon.get("experience.ascension_experience")
      end

      # Retrieves the total experience
      # @return [Integer] the total experience
      # @example
      #   total_xp = Lich::Gemstone::Experience.txp
      def self.txp
        Infomon.get("experience.total_experience")
      end

      # Calculates the percentage of current field experience
      # @return [Float] the percentage of current field experience
      # @example
      #   percent = Lich::Gemstone::Experience.percent_fxp
      def self.percent_fxp
        (fxp_current.to_f / fxp_max.to_f) * 100
      end

      # Calculates the percentage of ascension experience
      # @return [Float] the percentage of ascension experience
      # @example
      #   percent = Lich::Gemstone::Experience.percent_axp
      def self.percent_axp
        (axp.to_f / txp.to_f) * 100
      end

      # Calculates the percentage of current experience
      # @return [Float] the percentage of current experience
      # @example
      #   percent = Lich::Gemstone::Experience.percent_exp
      def self.percent_exp
        (exp.to_f / txp.to_f) * 100
      end

      # Retrieves the long-term experience
      # @return [Integer] the long-term experience
      # @example
      #   long_term_exp = Lich::Gemstone::Experience.lte
      def self.lte
        Infomon.get("experience.long_term_experience")
      end

      # Retrieves the deeds value
      # @return [Integer] the current deeds value
      # @example
      #   deeds_value = Lich::Gemstone::Experience.deeds
      def self.deeds
        Infomon.get("experience.deeds")
      end

      # Retrieves the deaths sting value
      # @return [Integer] the current deaths sting value
      # @example
      #   deaths_sting_value = Lich::Gemstone::Experience.deaths_sting
      def self.deaths_sting
        Infomon.get("experience.deaths_sting")
      end
    end
  end
end
