# frozen_string_literal: true

module Lich
  module Gemstone
    # Wounds class for tracking character wounds
    # Wounds class for tracking character wounds
    #
    # This class provides methods to access and manage the wounds of a character in the game.
    # It includes methods for individual body parts, composite wounds, and overall wound levels.
    # @example Creating a Wounds instance
    #   wounds = Lich::Gemstone::Wounds
    class Wounds < Gemstone::CharacterStatus # GameBase::CharacterStatus
      class << self
        # Body part accessor methods
        # XML from Simutronics drives the structure of the wound naming (eg. leftEye)
        # The following is a hash of the body parts and shorthand aliases created for more idiomatic Ruby
        # A hash of body parts and their shorthand aliases.
        # This constant drives the structure of the wound naming for various body parts.
        BODY_PARTS = {
          leftEye: ['leye'],
          rightEye: ['reye'],
          head: [],
          neck: [],
          back: [],
          chest: [],
          abdomen: ['abs'],
          leftArm: ['larm'],
          rightArm: ['rarm'],
          rightHand: ['rhand'],
          leftHand: ['lhand'],
          leftLeg: ['lleg'],
          rightLeg: ['rleg'],
          leftFoot: ['lfoot'],
          rightFoot: ['rfoot'],
          nsys: ['nerves']
        }.freeze

        # Define methods for each body part and its aliases
        BODY_PARTS.each do |part, aliases|
          # Define the primary method
          define_method(part) do
            fix_injury_mode('both') # continue to use 'both' (_injury2) for now

            XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['wound']
          end

          # Define alias methods
          aliases.each do |ali|
            alias_method ali, part
          end
        end

        # Alias snake_case methods for overachievers
        # Returns the wound level for the left eye using snake_case.
        # @return [Integer, nil] The wound level for the left eye or nil if not present.
        # @example
        #   wound_level = wounds.left_eye
        def left_eye; leftEye; end
        def right_eye; rightEye; end
        def left_arm; leftArm; end
        def right_arm; rightArm; end
        def left_hand; leftHand; end
        def right_hand; rightHand; end
        def left_leg; leftLeg; end
        def right_leg; rightLeg; end
        def left_foot; leftFoot; end
        def right_foot; rightFoot; end

        # Composite wound methods
        # Returns the maximum wound level for both arms and hands.
        # @return [Integer, nil] The maximum wound level for arms or nil if not present.
        # @example
        #   max_wound = wounds.arms
        def arms
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['wound'],
            XMLData.injuries['rightArm']['wound'],
            XMLData.injuries['leftHand']['wound'],
            XMLData.injuries['rightHand']['wound']
          ].max
        end

        # Returns the maximum wound level for both arms, hands, and legs.
        # @return [Integer, nil] The maximum wound level for limbs or nil if not present.
        # @example
        #   max_wound = wounds.limbs
        def limbs
          fix_injury_mode('both')
          [
            XMLData.injuries['leftArm']['wound'],
            XMLData.injuries['rightArm']['wound'],
            XMLData.injuries['leftHand']['wound'],
            XMLData.injuries['rightHand']['wound'],
            XMLData.injuries['leftLeg']['wound'],
            XMLData.injuries['rightLeg']['wound']
          ].max
        end

        # Returns the maximum wound level for the torso including eyes, chest, abdomen, and back.
        # @return [Integer, nil] The maximum wound level for the torso or nil if not present.
        # @example
        #   max_wound = wounds.torso
        def torso
          fix_injury_mode('both')
          [
            XMLData.injuries['rightEye']['wound'],
            XMLData.injuries['leftEye']['wound'],
            XMLData.injuries['chest']['wound'],
            XMLData.injuries['abdomen']['wound'],
            XMLData.injuries['back']['wound']
          ].max
        end

        # Helper method to get wound level for any body part
        # Returns the wound level for a specified body part.
        # @param part [Symbol] The body part to check (e.g., :leftEye).
        # @return [Integer, nil] The wound level for the specified body part or nil if not present.
        # @example
        #   wound_level = wounds.wound_level(:leftEye)
        def wound_level(part)
          fix_injury_mode('both')
          XMLData.injuries[part.to_s] && XMLData.injuries[part.to_s]['wound']
        end

        # Helper method to get all wound levels
        # Returns a hash of all body parts and their corresponding wound levels.
        # @return [Hash<Symbol, Integer>] A hash mapping body parts to their wound levels.
        # @example
        #   all_wounds = wounds.all_wounds
        def all_wounds
          fix_injury_mode('both')
          XMLData.injuries.transform_values { |v| v['wound'] }
        end
      end
    end
  end
end
