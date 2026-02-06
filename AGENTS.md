# AGENTS.md - ActiveRecord DuckDB Adapter

## Project Overview

An ActiveRecord connection adapter for [DuckDB](https://duckdb.org/), enabling DuckDB as a backend for Rails and standalone ActiveRecord applications.

- **Gem name**: `activerecord-duckdb-adapter`
- **Ruby**: >= 3.1.0
- **ActiveRecord**: ~> 8.0.4
- **DuckDB driver**: `duckdb` gem (ruby-duckdb)
- **Test framework**: RSpec (not MiniTest)

## Project Structure

```
lib/
  activerecord-duckdb-adapter.rb          # Gem entry point, Railtie registration
  active_record/
    connection_adapters/
      duckdb_adapter.rb                   # Main adapter class (DuckdbAdapter < AbstractAdapter)
      duckdb/
        database_statements.rb            # SQL execution (exec_query, execute, etc.)
        schema_statements.rb              # DDL introspection (tables, columns, indexes)
        schema_definitions.rb             # TableDefinition for DuckDB
        schema_creation.rb                # DDL generation
        schema_dumper.rb                  # schema.rb dumper support
        quoting.rb                        # SQL quoting (strings, identifiers, booleans)
        column.rb                         # Column metadata
        explain_pretty_printer.rb         # EXPLAIN output formatting
        version.rb                        # VERSION constant
spec/
  spec_helper.rb                          # Bootstraps AR standalone, connects :memory:
  active_record/
    connection_adapters/
      duckdb_adapter_spec.rb              # Adapter loading and connection tests
      duckdb/
        database_statements_spec.rb       # exec_query, execute, select_* tests
        schema_statements_spec.rb         # tables, columns, indexes, create_table tests
        data_types_spec.rb                # Type round-trip tests
        transactions_spec.rb              # Transaction and savepoint tests
  model_integration_spec.rb              # Full ActiveRecord model CRUD tests
```

## Module Naming Convention

Use `Duckdb` (lowercase db) for all module namespacing to match the adapter class name `DuckdbAdapter`:

```ruby
module ActiveRecord
  module ConnectionAdapters
    class DuckdbAdapter < AbstractAdapter
      include Duckdb::DatabaseStatements
      include Duckdb::SchemaStatements
    end

    module Duckdb
      module DatabaseStatements; end
      module SchemaStatements; end
    end
  end
end
```

The only exception is `DuckDB::VERSION` in `version.rb` which uses uppercase for gem naming conventions.

## Development Workflow - Strict TDD

All development on this project MUST follow strict Test-Driven Development:

### The TDD Cycle

1. **Write a failing test first** - Write the RSpec test that describes the desired behavior
2. **Run tests** (`bundle exec rspec`) - Verify the test fails for the RIGHT reason
3. **Implement minimum code** - Write only enough code to make the test pass
4. **Run tests** - Verify all tests are green (no regressions)
5. **Commit** - Test and implementation together in one atomic commit

### Rules

- Never write implementation code without a failing test first
- Never proceed to the next feature with failing tests
- Keep implementations minimal - don't add code that isn't required by a test
- Each commit should contain both the test and the implementation that makes it pass
- Run the full test suite before every commit to catch regressions

### Running Tests

```bash
bundle exec rspec                    # Run full suite
bundle exec rspec spec/path/file.rb  # Run single file
bundle exec rspec --format doc       # Verbose output
```

### Test Conventions

- Use `RSpec.describe` (monkey patching is disabled)
- Use `before(:each)` / `after(:each)` for test isolation (not `before(:all)`)
- Create tables with raw SQL in `before(:each)` when testing introspection
- Drop tables in `after(:each)` for cleanup
- All tests use in-memory database (`:memory:`) via shared `spec_helper.rb`
- Prefer `expect` syntax exclusively (`config.expect_with :rspec { |c| c.syntax = :expect }`)

## ActiveRecord Standalone Bootstrap

When loading ActiveRecord outside of Rails, the correct require order is critical:

```ruby
require "active_record"
require "active_record/connection_adapters"
require "active_record/base"
```

This is handled in `spec/spec_helper.rb`. Do not add these requires to the adapter files themselves.

## DuckDB-Specific Notes

### Connection Model

DuckDB has a two-step connection:
1. `DuckDB::Database.open(path)` returns a Database object
2. `database.connect` returns a Connection object (needed for queries)

The adapter's `@raw_connection` should be the Connection, not the Database.

### Type Mapping

| DuckDB Type | ActiveRecord Type |
|-------------|-------------------|
| VARCHAR     | :string           |
| INTEGER     | :integer          |
| BIGINT      | :bigint           |
| DOUBLE      | :float            |
| DECIMAL     | :decimal          |
| BOOLEAN     | :boolean          |
| DATE        | :date             |
| TIME        | :time             |
| TIMESTAMP   | :datetime         |
| BLOB        | :binary           |
| UUID        | :uuid             |

### Boolean Quoting

DuckDB uses native `TRUE`/`FALSE` (not `1`/`0` like SQLite3).

### Metadata Queries

```sql
-- Tables
SELECT table_name FROM information_schema.tables
  WHERE table_schema = 'main' AND table_type = 'BASE TABLE';

-- Columns
SELECT column_name, data_type, column_default, is_nullable
  FROM information_schema.columns WHERE table_name = ?;

-- Primary keys
SELECT constraint_column_names FROM duckdb_constraints()
  WHERE table_name = ? AND constraint_type = 'PRIMARY KEY';

-- Indexes
SELECT * FROM duckdb_indexes() WHERE table_name = ?;
```

## Commit Messages

```
<phase>.<step>: <short description>

<optional body>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

## Tooling

- **Ruby version**: Managed via `mise.toml`
- **Dependencies**: `bundle install`
- **Linting**: `bundle exec rubocop` (config in `.rubocop.yml`)
