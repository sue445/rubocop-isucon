# frozen_string_literal: true

module RuboCop
  module Isucon
    module GDA
      # Location in SQL
      class NodeLocation
        # @return [Integer]
        attr_reader :begin_pos

        # @return [Integer]
        attr_reader :end_pos

        # @return [String]
        attr_reader :body

        # @param begin_pos [Integer]
        # @param end_pos [Integer]
        # @param body [String]
        def initialize(begin_pos:, end_pos:, body:)
          @begin_pos = begin_pos
          @end_pos = end_pos
          @body = body
        end

        # @param other [RuboCop::Isucon::GDA::NodeLocation]
        # @return [Boolean]
        def ==(other)
          other.is_a?(NodeLocation) &&
            begin_pos == other.begin_pos &&
            end_pos == other.end_pos &&
            body == other.body
        end

        # @return [Integer]
        def length
          end_pos - begin_pos
        end
      end
    end
  end
end
