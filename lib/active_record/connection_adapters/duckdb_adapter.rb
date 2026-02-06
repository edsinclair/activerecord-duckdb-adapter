# frozen_string_literal: true

require "active_record/connection_adapters/duckdb/column"
require "active_record/connection_adapters/duckdb/database_statements"
require "active_record/connection_adapters/duckdb/explain_pretty_printer"
require "active_record/connection_adapters/duckdb/quoting"
require "active_record/connection_adapters/duckdb/schema_creation"
require "active_record/connection_adapters/duckdb/schema_definitions"
require "active_record/connection_adapters/duckdb/schema_dumper"
require "active_record/connection_adapters/duckdb/schema_statements"

module ActiveRecord
  module ConnectionAdapters # :nodoc:
    # = Active Record DuckDB Adapter
    #
    # Options:
    #
    # * <tt>:database</tt> - Path to the database file, or ":memory:" for in-memory.
    class DuckdbAdapter < AbstractAdapter
      ADAPTER_NAME = "DuckDB"

      class << self
        def new_client(config)
          db = ::DuckDB::Database.open(config[:database].to_s)
          db.connect
        end
      end

      def initialize(...)
        super
        @last_affected_rows = nil
        @connection_parameters = @config.merge(
          database: @config[:database].to_s
        )
      end

      include Duckdb::Quoting
      include Duckdb::DatabaseStatements
      include Duckdb::SchemaStatements

      NATIVE_DATABASE_TYPES = {
        primary_key:  "INTEGER PRIMARY KEY",
        string:       { name: "VARCHAR" },
        text:         { name: "VARCHAR" },
        integer:      { name: "INTEGER" },
        float:        { name: "REAL" },
        decimal:      { name: "DECIMAL" },
        datetime:     { name: "TIMESTAMP" },
        time:         { name: "TIME" },
        date:         { name: "DATE" },
        bigint:       { name: "BIGINT" },
        binary:       { name: "BLOB" },
        boolean:      { name: "BOOLEAN" },
        uuid:         { name: "UUID" },
        json:         { name: "JSON" },
      }

      def native_database_types
        NATIVE_DATABASE_TYPES
      end

      def connected?
        !@raw_connection.nil?
      end

      def active?
        if connected?
          verified!
          true
        end
      end

      def supports_insert_returning?
        true
      end

      def supports_ddl_transactions?
        true
      end

      def supports_foreign_keys?
        true
      end

      def supports_check_constraints?
        true
      end

      def supports_views?
        true
      end

      def supports_explain?
        true
      end

      def supports_json?
        true
      end

      def supports_savepoints?
        false
      end

      def supports_insert_on_conflict?
        true
      end
      alias supports_insert_on_duplicate_skip? supports_insert_on_conflict?
      alias supports_insert_on_duplicate_update? supports_insert_on_conflict?
      alias supports_insert_conflict_target? supports_insert_on_conflict?

      def disconnect!
        super

        @raw_connection = nil
      end

      def primary_keys(table_name) # :nodoc:
        raise ArgumentError unless table_name.present?

        results = query("PRAGMA table_info(#{table_name})", "SCHEMA")
        results.each_with_object([]) do |result, keys|
          _cid, name, _type, _notnull, _dflt_value, pk = result
          keys << name if pk
        end
      end

      private
        def translate_exception(exception, message:, sql:, binds:)
          case exception.message
          when /Duplicate key.*violates unique constraint/i
            RecordNotUnique.new(message, sql: sql, binds: binds, connection_pool: @pool)
          when /NOT NULL constraint failed/i
            NotNullViolation.new(message, sql: sql, binds: binds, connection_pool: @pool)
          when /Violates foreign key constraint/i
            InvalidForeignKey.new(message, sql: sql, binds: binds, connection_pool: @pool)
          else
            super
          end
        end

        def connect
          @raw_connection = self.class.new_client(@connection_parameters)
        rescue ConnectionNotEstablished => ex
          raise ex.set_pool(@pool)
        end

        def reconnect
          if active?
            # DuckDB doesn't have a rollback on the connection level outside transactions
          else
            connect
          end
        end
    end
  end
end
