# frozen_string_literal: true

require_relative "lib/active_record/connection_adapters/duckdb/version"

Gem::Specification.new do |spec|
  spec.name = "activerecord-duckdb-adapter"
  spec.version = ActiveRecord::ConnectionAdapters::DuckDB::VERSION
  spec.authors = ["Eirik Dentz Sinclair"]
  spec.email = ["eirikdentz@gmail.com"]

  spec.summary = "ActiveRecord connection adapter for DuckDB"
  spec.description = "An ActiveRecord connection adapter for DuckDB, the fast in-process analytical database. " \
                     "Provides full migration support, native type mapping, foreign keys, indexes, JSON columns, " \
                     "and Rails integration via Railtie."
  spec.homepage = "https://github.com/edsinclair/activerecord-duckdb-adapter"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/edsinclair/activerecord-duckdb-adapter"
  spec.metadata["changelog_uri"] = "https://github.com/edsinclair/activerecord-duckdb-adapter/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "activerecord", "~> 8.0.4"
  spec.add_dependency("duckdb")

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
