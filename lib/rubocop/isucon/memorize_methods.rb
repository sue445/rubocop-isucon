# frozen_string_literal: true

module RuboCop
  module Isucon
    # Memorize helper
    #
    # @example usage
    #   extends RuboCop::Isucon::MemorizeMethods
    #
    #   memorize :foo
    #
    # @example generated followings
    #   def foo_with_cache
    #     @foo_with_cache ||= foo_without_cache
    #   end
    #   alias_method :foo_without_cache, :foo
    #   alias_method :foo, :foo_with_cache
    module MemorizeMethods
      # @param method_name [String,Symbol]
      def memorize(method_name) # rubocop:disable Metrics/MethodLength
        define_method "#{method_name}_with_cache" do
          if instance_variable_get("@#{method_name}_with_cache")
            instance_variable_get("@#{method_name}_with_cache")
          else
            ret = send("#{method_name}_without_cache")
            instance_variable_set("@#{method_name}_with_cache", ret)
            ret
          end
        end

        alias_method "#{method_name}_without_cache", method_name
        alias_method method_name, "#{method_name}_with_cache"
      end
    end
  end
end
