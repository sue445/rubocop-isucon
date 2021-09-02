# frozen_string_literal: true

require "rubocop-isucon"
require "rubocop/rspec/support"
require "pry"
require "active_record/tasks/database_tasks"

Dir["#{__dir__}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense

  config.disable_monkey_patching!
  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
  config.fail_if_no_examples = true

  config.order = :random
  Kernel.srand config.seed
end

def spec_dir
  Pathname(__dir__)
end

module Rails
  def self.root
    spec_dir
  end
end
