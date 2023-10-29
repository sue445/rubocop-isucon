# frozen_string_literal: true

require "rubocop-isucon"
require "rubocop/rspec/support"
require "pry"
require "active_record/tasks/database_tasks"
require "rspec/its"

Dir["#{__dir__}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense

  config.disable_monkey_patching!
  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
  config.fail_if_no_examples = true

  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end

  config.order = :random
  Kernel.srand config.seed
end

def spec_dir
  Pathname(__dir__)
end

def root_dir
  spec_dir.join("..")
end

module Rails
  def self.root
    spec_dir
  end
end
