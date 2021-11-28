# frozen_string_literal: true

module RuboCop
  module Isucon
    # Memorize helper
    #
    module MemorizeMethods
      # Define memorize method
      #
      # @param method_name [String,Symbol]
      #
      # @example Usage
      #   extends RuboCop::Isucon::MemorizeMethods
      #
      #   memorize :foo
      #
      # @example Generated followings
      #   def foo_with_cache
      #     @foo_with_cache ||= foo_without_cache
      #   end
      #   alias_method :foo_without_cache, :foo
      #   alias_method :foo, :foo_with_cache
      def memorize(method_name)
        class_eval <<~RUBY, __FILE__, __LINE__ + 1
          # def foo_with_cache
          #   @foo_with_cache ||= foo_without_cache
          # end
          def #{method_name}_with_cache
            @#{method_name}_with_cache ||= #{method_name}_without_cache
          end
        RUBY

        alias_method "#{method_name}_without_cache", method_name
        alias_method method_name, "#{method_name}_with_cache"
      end
    end
  end
end
