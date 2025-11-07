# Contains the Lich project modules
# @example Including the Lich module
#   include Lich
module Lich
  # Contains the DragonRealms related functionality
  # @example Including the DragonRealms module
  #   include Lich::DragonRealms
  module DragonRealms
    # Provides DRInfomon functionality for DragonRealms
    # @example Including the DRInfomon module
    #   include Lich::DragonRealms::DRInfomon
    module DRInfomon
      # The version of the DRInfomon module
      # @return [String] The current version of DRInfomon
      $DRINFOMON_VERSION = '3.0'

      # An array of core Lich defines used in DRInfomon
      # @return [Array<String>] List of core Lich defines
      DRINFOMON_CORE_LICH_DEFINES = %W(drinfomon common common-arcana common-crafting common-healing common-healing-data common-items common-money common-moonmage common-summoning common-theurgy common-travel common-validation events slackbot equipmanager spellmonitor)

      # Indicates if DRInfomon is included in the core Lich
      # @return [Boolean] True if DRInfomon is in core Lich
      DRINFOMON_IN_CORE_LICH = true
      require_relative 'drinfomon/drdefs'
      require_relative 'drinfomon/drvariables'
      require_relative 'drinfomon/drparser'
      require_relative 'drinfomon/drskill'
      require_relative 'drinfomon/drstats'
      require_relative 'drinfomon/drroom'
      require_relative 'drinfomon/drspells'
      require_relative 'drinfomon/events'
    end
  end
end
