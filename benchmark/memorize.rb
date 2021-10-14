require "benchmark/ips"

class DefineMethodWithInstanceVariableMemorizer
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
  x.report("DefineMethodWithInstanceVariableMemorizer") do
    m = DefineMethodWithInstanceVariableMemorizer.new
    m.value
    m.value
  end

  x.report("ClassEvalMemorizer") do
    m = ClassEvalMemorizer.new
    m.value
    m.value
  end
end
