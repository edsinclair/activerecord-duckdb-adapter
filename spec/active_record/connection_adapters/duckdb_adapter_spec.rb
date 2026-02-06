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
