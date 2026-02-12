# frozen_string_literal: true

require "active_record/connection_adapters/duckdb_adapter"

if defined?(Rails)
  module ActiveRecord
    module ConnectionAdapters
      class DuckdbRailtie < ::Rails::Railtie
        rake_tasks do
          load "active_record/connection_adapters/duckdb/database_tasks.rb"
        end

        ActiveSupport.on_load(:active_record) do
          if ActiveRecord::ConnectionAdapters.respond_to?(:register)
            ActiveRecord::ConnectionAdapters.register(
              "duckdb",
              "ActiveRecord::ConnectionAdapters::DuckdbAdapter",
              "active_record/connection_adapters/duckdb_adapter"
            )
          end
        end
      end
    end
  end
elsif ActiveRecord::ConnectionAdapters.respond_to?(:register)
  # Non-Rails usage: register the adapter manually
  ActiveRecord::ConnectionAdapters.register(
    "duckdb",
    "ActiveRecord::ConnectionAdapters::DuckdbAdapter",
    "active_record/connection_adapters/duckdb_adapter"
  )
end
