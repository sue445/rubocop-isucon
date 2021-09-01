# frozen_string_literal: true

require "rubocop-isucon"
require "rubocop/rspec/support"
require "pry"
require "active_record/tasks/database_tasks"

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense

  config.disable_monkey_patching!
  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
  config.fail_if_no_examples = true

  config.order = :random
  Kernel.srand config.seed
end

def spec_root
  Pathname(__dir__)
end

def schema_dir
  spec_root.join("schemas")
end

module Rails
  def self.root
    spec_root
  end
end
