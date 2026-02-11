# frozen_string_literal: true

require "spec_helper"

RSpec.describe ActiveRecord::ConnectionAdapters::DuckdbAdapter do
  it "loads the adapter without error" do
    expect(defined?(ActiveRecord::ConnectionAdapters::DuckdbAdapter)).to eq("constant")
  end

  it "has correct adapter name" do
    expect(ActiveRecord::ConnectionAdapters::DuckdbAdapter::ADAPTER_NAME).to eq("DuckDB")
  end

  it "includes DatabaseStatements module" do
    expect(ActiveRecord::ConnectionAdapters::DuckdbAdapter.ancestors).to include(
      ActiveRecord::ConnectionAdapters::Duckdb::DatabaseStatements
    )
  end

  it "includes SchemaStatements module" do
    expect(ActiveRecord::ConnectionAdapters::DuckdbAdapter.ancestors).to include(
      ActiveRecord::ConnectionAdapters::Duckdb::SchemaStatements
    )
  end

  describe "feature support" do
    let(:connection) { ActiveRecord::Base.connection }

    it { expect(connection.supports_ddl_transactions?).to be true }
    it { expect(connection.supports_foreign_keys?).to be true }
    it { expect(connection.supports_check_constraints?).to be true }
    it { expect(connection.supports_views?).to be true }
    it { expect(connection.supports_explain?).to be true }
    it { expect(connection.supports_json?).to be true }
    it { expect(connection.supports_savepoints?).to be false }
    it { expect(connection.supports_insert_on_conflict?).to be true }
    it { expect(connection.supports_concurrent_connections?).to be true }
  end

  describe "error translation" do
    before(:each) do
      @connection = ActiveRecord::Base.connection
      @connection.execute("CREATE TABLE test_errors (id INTEGER PRIMARY KEY, email VARCHAR UNIQUE, name VARCHAR NOT NULL)")
    end
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_errors") }

    it "raises RecordNotUnique on duplicate unique value" do
      @connection.execute("INSERT INTO test_errors (id, email, name) VALUES (1, 'a@b.com', 'A')")
      expect do
        @connection.execute("INSERT INTO test_errors (id, email, name) VALUES (2, 'a@b.com', 'B')")
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "raises NotNullViolation on null in NOT NULL column" do
      expect do
        @connection.execute("INSERT INTO test_errors (id, email) VALUES (1, 'a@b.com')")
      end.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "raises StatementInvalid on bad SQL" do
      expect do
        @connection.execute("INVALID SQL")
      end.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe "connection" do
    it "connects to in-memory database" do
      conn = ActiveRecord::Base.connection
      expect(conn).to be_a(described_class)
    end

    it "is active after executing a query" do
      conn = ActiveRecord::Base.connection
      conn.execute("SELECT 1")
      expect(conn).to be_active
    end

    it "can execute a simple query" do
      result = ActiveRecord::Base.connection.execute("SELECT 1 AS num")
      expect(result).not_to be_nil
    end

    it "reports inactive after disconnect" do
      conn = ActiveRecord::Base.connection
      conn.disconnect!
      expect(conn).not_to be_active
    end

    it "is active after reconnect" do
      conn = ActiveRecord::Base.connection
      conn.disconnect!
      conn.reconnect!
      expect(conn).to be_active
    end
  end
end
