# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module Duckdb
      module DatabaseStatements # :nodoc:
        def write_query?(sql) # :nodoc:
          !READ_QUERY.match?(sql)
        rescue ArgumentError # Invalid encoding
          !READ_QUERY.match?(sql.b)
        end

        READ_QUERY = ActiveRecord::ConnectionAdapters::AbstractAdapter.build_read_query_regexp(
          :pragma
        ) # :nodoc:
        private_constant :READ_QUERY

        def execute(sql, name = nil) # :nodoc:
          super&.to_a
        end

        def exec_delete(sql, name = nil, binds = []) # :nodoc:
          result = internal_exec_query(sql, name, binds)
          @last_affected_rows
        end
        alias :exec_update :exec_delete

        def begin_db_transaction # :nodoc:
          internal_execute("BEGIN", "TRANSACTION")
        end

        def commit_db_transaction # :nodoc:
          internal_execute("COMMIT", "TRANSACTION")
        end

        def exec_rollback_db_transaction # :nodoc:
          internal_execute("ROLLBACK", "TRANSACTION")
        end

        private
          def perform_query(raw_connection, sql, binds, type_casted_binds, prepare:, notification_payload:, batch: false)
            result = if binds.nil? || binds.empty?
              raw_connection.query(sql)
            else
              raw_connection.query(sql, *type_casted_binds)
            end

            columns = result.columns.map(&:name)
            rows = result.to_a

            ar_result = ActiveRecord::Result.new(columns, rows)
            @last_affected_rows = result.respond_to?(:rows_changed) ? result.rows_changed : 0
            verified!

            notification_payload[:row_count] = ar_result.length
            ar_result
          end

          def cast_result(result)
            result
          end

          def affected_rows(result)
            @last_affected_rows
          end
      end
    end
  end
end
