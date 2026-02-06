# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module Duckdb
      module SchemaStatements # :nodoc:
        def rename_table(table_name, new_name, **)
          execute("ALTER TABLE #{quote_table_name(table_name)} RENAME TO #{quote_table_name(new_name)}")
          rename_table_indexes(table_name, new_name)
        end

        def indexes(table_name)
          []
        end

        private

        def column_definitions(table_name)
          query("PRAGMA table_info(#{quote_table_name(table_name)})", "SCHEMA")
        end

        def new_column_from_field(table_name, field, _definitions = nil)
          _cid, name, type, notnull, dflt_value, _pk = field

          type_metadata = fetch_type_metadata(type)
          default_value = dflt_value

          Column.new(
            name,
            default_value,
            type_metadata,
            !notnull,
            nil # default function
          )
        end

        def data_source_sql(name = nil, type: nil)
          scope = quoted_scope(name, type: type)

          sql = +"SELECT table_name FROM information_schema.tables"
          sql << " WHERE table_schema = #{scope[:schema]}"
          if scope[:type] || scope[:name]
            conditions = []
            conditions << "table_type = #{scope[:type]}" if scope[:type]
            conditions << "table_name = #{scope[:name]}" if scope[:name]
            sql << " AND #{conditions.join(" AND ")}"
          end
          sql
        end

        def quoted_scope(name = nil, type: nil)
          schema, name = extract_schema_qualified_name(name)
          scope = {}
          scope[:schema] = schema ? quote(schema) : "'main'"
          scope[:name] = quote(name) if name
          scope[:type] = quote(type) if type
          scope
        end

        def extract_schema_qualified_name(string)
          schema, name = string.to_s.scan(/[^`.\s]+|`[^`]*`/)
          schema, name = nil, schema unless name
          [schema, name]
        end
      end
    end
  end
end
