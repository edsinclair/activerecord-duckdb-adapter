# ActiveRecord DuckDB Adapter

An ActiveRecord connection adapter for [DuckDB](https://duckdb.org/), the fast in-process analytical database. This gem lets you use DuckDB as a backend for Rails applications and any Ruby project using ActiveRecord.

## Features

- Full ActiveRecord migration support (create/drop/rename tables, add/remove/change columns)
- Auto-incrementing primary keys via DuckDB sequences
- Native type mapping: string, text, integer, bigint, float, decimal, datetime, time, date, boolean, binary, UUID, JSON
- Foreign keys with deferrable constraints
- Check constraints
- Indexes
- Views
- `INSERT ... RETURNING`
- `INSERT ... ON CONFLICT`
- Generated/virtual columns
- `EXPLAIN` query support
- Transaction support (BEGIN/COMMIT/ROLLBACK)
- File-based and in-memory (`:memory:`) databases
- Rails integration via Railtie

## Requirements

- Ruby >= 3.1.0
- Rails ~> 8.0
- The [`duckdb`](https://github.com/suketa/ruby-duckdb) gem (native DuckDB bindings)

## Installation

Add to your Gemfile:

```ruby
gem "activerecord-duckdb-adapter"
```

Then run:

```bash
bundle install
```

## Usage

### Rails

Configure your `database.yml`:

```yaml
development:
  adapter: duckdb
  database: db/development.duckdb

test:
  adapter: duckdb
  database: ":memory:"
```

Migrations, models, and queries work as you'd expect with any ActiveRecord adapter:

```ruby
class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2
      t.json :metadata
      t.timestamps
    end
  end
end
```

### Standalone (without Rails)

```ruby
require "active_record"
require "activerecord_duckdb_adapter"

ActiveRecord::Base.establish_connection(
  adapter: "duckdb",
  database: ":memory:"
)
```

## Known Limitations

- Savepoints are not supported
- DuckDB is an analytical database — it excels at read-heavy and analytical workloads but is not optimized for high-concurrency OLTP writes

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/edsinclair/activerecord-duckdb-adapter. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/edsinclair/activerecord-duckdb-adapter/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
