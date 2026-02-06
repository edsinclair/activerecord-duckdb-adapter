# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "bundler/setup"

# Bootstrap ActiveRecord in the correct order for standalone (non-Rails) use
require "active_record"
require "active_record/connection_adapters"
require "active_record/base"

require "duckdb"
require "active_record/connection_adapters/duckdb_adapter"

# Register adapter for non-Rails usage
ActiveRecord::ConnectionAdapters.register(
  "duckdb",
  "ActiveRecord::ConnectionAdapters::DuckdbAdapter",
  "active_record/connection_adapters/duckdb_adapter"
)

# Establish a shared in-memory connection for all tests
ActiveRecord::Base.establish_connection(adapter: "duckdb", database: ":memory:")

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
