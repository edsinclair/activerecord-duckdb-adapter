# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module Duckdb
      module SchemaStatements # :nodoc:
        def create_table(table_name, id: :primary_key, primary_key: nil, **options, &block)
          super

          return unless id != false

          pk_name = primary_key || "id"
          seq_name = sequence_name_for(table_name, pk_name)
          execute("CREATE SEQUENCE IF NOT EXISTS #{quote_table_name(seq_name)}")
          execute(<<~SQL.squish)
            ALTER TABLE #{quote_table_name(table_name)}
            ALTER COLUMN #{quote_column_name(pk_name)}
            SET DEFAULT nextval('#{seq_name}')
          SQL
        end

        def drop_table(table_name, **options)
          pk = begin
            primary_keys(table_name.to_s)
          rescue StandardError
            []
          end
          super

          return unless pk.length == 1

          seq_name = sequence_name_for(table_name, pk.first)
          execute("DROP SEQUENCE IF EXISTS #{quote_table_name(seq_name)}")
        end

        def rename_table(table_name, new_name, **)
          pk = begin
            primary_keys(table_name.to_s)
          rescue StandardError
            []
          end

          execute("ALTER TABLE #{quote_table_name(table_name)} RENAME TO #{quote_table_name(new_name)}")
          rename_table_indexes(table_name, new_name)

          return unless pk.length == 1

          rename_sequence(table_name, pk.first, new_name, pk.first)
        end

        def indexes(table_name)
          result = query(<<~SQL.squish, "SCHEMA")
            SELECT index_name, is_unique, expressions FROM duckdb_indexes()
            WHERE table_name = #{quote(table_name.to_s)} AND NOT is_primary
          SQL
          result.map do |row|
            index_name, is_unique, expressions = row
            columns = parse_index_expressions(expressions)
            IndexDefinition.new(table_name.to_s, index_name, is_unique, columns)
          end
        end

        def remove_index(table_name, column_name = nil, **options)
          index_name = index_name_for_remove(table_name, column_name, options)
          execute("DROP INDEX #{quote_column_name(index_name)}")
        end

        def change_column_default(table_name, column_name, default_or_changes)
          default = extract_new_default_value(default_or_changes)
          if default.nil?
            execute(<<~SQL.squish)
              ALTER TABLE #{quote_table_name(table_name)}
              ALTER COLUMN #{quote_column_name(column_name)} DROP DEFAULT
            SQL
          else
            execute(<<~SQL.squish)
              ALTER TABLE #{quote_table_name(table_name)}
              ALTER COLUMN #{quote_column_name(column_name)} SET DEFAULT #{quote(default)}
            SQL
          end
        end

        def change_column_null(table_name, column_name, null, _default = nil)
          if null
            execute(<<~SQL.squish)
              ALTER TABLE #{quote_table_name(table_name)}
              ALTER COLUMN #{quote_column_name(column_name)} DROP NOT NULL
            SQL
          else
            execute(<<~SQL.squish)
              ALTER TABLE #{quote_table_name(table_name)}
              ALTER COLUMN #{quote_column_name(column_name)} SET NOT NULL
            SQL
          end
        end

        def rename_column(table_name, column_name, new_column_name)
          execute(<<~SQL.squish)
            ALTER TABLE #{quote_table_name(table_name)}
            RENAME COLUMN #{quote_column_name(column_name)} TO #{quote_column_name(new_column_name)}
          SQL
        end

        def change_column(table_name, column_name, type, **options)
          sql_type = type_to_sql(type, **options.slice(:limit, :precision, :scale))
          execute(<<~SQL.squish)
            ALTER TABLE #{quote_table_name(table_name)}
            ALTER COLUMN #{quote_column_name(column_name)} SET DATA TYPE #{sql_type}
          SQL
          change_column_default(table_name, column_name, options[:default]) if options.key?(:default)
          change_column_null(table_name, column_name, options[:null]) if options.key?(:null)
        end

        def foreign_keys(table_name)
          result = query(<<~SQL, "SCHEMA")
            SELECT constraint_name, constraint_column_names, referenced_table, referenced_column_names
            FROM duckdb_constraints()
            WHERE table_name = #{quote(table_name.to_s)}
            AND constraint_type = 'FOREIGN KEY'
          SQL

          result.map { |row| build_foreign_key(table_name, row) }
        end

        def schema_creation # :nodoc:
          Duckdb::SchemaCreation.new(self)
        end

        private

        def create_table_definition(name, **options)
          Duckdb::TableDefinition.new(self, name, **options)
        end

        def column_definitions(table_name)
          query("PRAGMA table_info(#{quote_table_name(table_name)})", "SCHEMA")
        end

        def new_column_from_field(_table_name, field, _definitions = nil)
          _cid, name, type, notnull, dflt_value, _pk = field

          type_metadata = fetch_type_metadata(type)
          default_value = dflt_value
          default_function = nil

          if default_value.is_a?(String) && default_value.match?(/\w+\(/)
            default_function = default_value
            default_value = nil
          end

          Duckdb::Column.new(*column_args(name, type, default_value, type_metadata, !notnull, default_function))
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

        def parse_index_expressions(expressions)
          # DuckDB returns expressions like: [email, '"name"']
          # Strip outer brackets and split by comma, then clean up quotes
          inner = expressions.to_s.gsub(/\A\[|\]\z/, "")
          inner.split(",").map do |col|
            col.strip.gsub(/\A'?"?|"?'?\z/, "")
          end
        end

        def extract_schema_qualified_name(string)
          schema, name = string.to_s.scan(/[^`.\s]+|`[^`]*`/)
          unless name
            name = schema
            schema = nil
          end
          [schema, name]
        end

        def build_foreign_key(table_name, row)
          constraint_name, columns, to_table, primary_keys = row
          options = {
            name: constraint_name,
            column: columns.length == 1 ? columns.first : columns,
            primary_key: primary_keys.length == 1 ? primary_keys.first : primary_keys
          }
          ForeignKeyDefinition.new(table_name.to_s, to_table, options)
        end

        def sequence_name_for(table_name, pk_name)
          "#{table_name}_#{pk_name}_seq"
        end

        def column_args(name, type, default_value, type_metadata, null, default_function)
          args = [name]
          args << lookup_cast_type(type) if ar_81_or_later?
          args.push(default_value, type_metadata, null, default_function)
        end

        def ar_81_or_later?
          ActiveRecord::VERSION::MAJOR > 8 ||
            (ActiveRecord::VERSION::MAJOR == 8 && ActiveRecord::VERSION::MINOR >= 1)
        end

        def rename_sequence(old_table, pk_name, new_table, new_pk_name)
          old_seq = sequence_name_for(old_table, pk_name)
          new_seq = sequence_name_for(new_table, new_pk_name)
          return if old_seq == new_seq

          # Get the current sequence value so the new sequence continues from it
          last_value = select_value("SELECT last_value FROM duckdb_sequences() WHERE sequence_name = #{quote(old_seq)}")
          return unless last_value

          # Create new sequence starting after the last used value
          execute("CREATE SEQUENCE #{quote_table_name(new_seq)} START #{last_value + 1}")
          execute(<<~SQL.squish)
            ALTER TABLE #{quote_table_name(new_table)}
            ALTER COLUMN #{quote_column_name(new_pk_name)}
            SET DEFAULT nextval('#{new_seq}')
          SQL
          execute("DROP SEQUENCE #{quote_table_name(old_seq)}")
        end
      end
    end
  end
end
