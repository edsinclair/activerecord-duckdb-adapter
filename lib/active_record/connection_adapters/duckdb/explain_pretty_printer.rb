# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module Duckdb
      class ExplainPrettyPrinter # :nodoc:
        # Pretty prints the result of an EXPLAIN query from DuckDB.
        # DuckDB returns explain output as rows with explain_key and explain_value columns.
        def pp(result)
          result.rows.map { |row| row.last }.join("\n") + "\n"
        end
      end
    end
  end
end
