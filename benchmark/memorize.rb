require "benchmark/ips"

class DefineMethodMemorizer
  # @param method_name [String,Symbol]
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
  def self.memorize(method_name)
    class_eval <<~RUBY
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
