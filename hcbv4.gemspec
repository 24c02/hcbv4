# frozen_string_literal: true

require_relative "lib/hcbv4/version"

Gem::Specification.new do |spec|
  spec.name = "hcbv4"
  spec.version = HCBV4::VERSION
  spec.authors = ["24c02"]
  spec.email = ["163450896+24c02@users.noreply.github.com"]

  spec.summary = "Ruby client for the HCB API v4."
  spec.description = "A Ruby SDK for interacting with the Hack Club Bank (HCB) API v4. Provides access to organizations, transactions, cards, and financial operations."
  spec.homepage = "https://github.com/hackclub/hcbv4"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/hackclub/hcbv4"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
