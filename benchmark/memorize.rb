require "benchmark/ips"

class DefineMethodMemorizer
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
  def self.memorize(method_name)
    define_method "#{method_name}_with_cache" do
      if (ret = instance_variable_get("@#{method_name}_with_cache"))
        ret
      else
        ret = send("#{method_name}_without_cache")
        instance_variable_set("@#{method_name}_with_cache", ret)
        ret
      end
    end

    alias_method "#{method_name}_without_cache", method_name
    alias_method method_name, "#{method_name}_with_cache"
  end

  def value
    1
  end

  memorize :value
end

class ClassEvalMemorizer
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
  def self.memorize(method_name)
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

  def value
    1
  end

  memorize :value
end

Benchmark.ips do |x|
  x.report("DefineMethodMemorizer") do
    m = DefineMethodMemorizer.new
    m.value
    m.value
  end

  x.report("ClassEvalMemorizer") do
    m = ClassEvalMemorizer.new
    m.value
    m.value
  end
end
