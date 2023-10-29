# frozen_string_literal: true

require_relative "lib/rubocop/isucon/version"

Gem::Specification.new do |spec|
  spec.name          = "rubocop-isucon"
  spec.version       = RuboCop::Isucon::VERSION
  spec.authors       = ["sue445"]
  spec.email         = ["sue445@sue445.net"]

  spec.summary       = "RuboCop plugin for ruby reference implementation of ISUCON"
  spec.description   = "RuboCop plugin for ruby reference implementation of ISUCON"
  spec.homepage      = "https://github.com/sue445/rubocop-isucon"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sue445/rubocop-isucon"
  spec.metadata["changelog_uri"] = "https://github.com/sue445/rubocop-isucon/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://sue445.github.io/rubocop-isucon/"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html

  spec.add_runtime_dependency "activerecord", ">= 6.1.0"
  spec.add_runtime_dependency "gda", "!= 1.1.2"
  spec.add_runtime_dependency "rubocop", ">= 1.49.0"
  spec.add_runtime_dependency "rubocop-performance"

  spec.add_development_dependency "benchmark-ips"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "redcarpet"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-its"
  spec.add_development_dependency "rubocop_auto_corrector"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "yard"
end
