# frozen_string_literal: true

require "spec_helper"

RSpec.describe "DuckDB DatabaseStatements" do
  before(:each) do
    @connection = ActiveRecord::Base.connection
  end

  describe "#exec_query" do
    before(:each) do
      @connection.execute("CREATE TABLE test_users (id INTEGER, name VARCHAR, email VARCHAR, age INTEGER)")
      @connection.execute("INSERT INTO test_users VALUES (1, 'Alice', 'alice@example.com', 30)")
    end

    after(:each) do
      @connection.execute("DROP TABLE IF EXISTS test_users")
    end

    it "returns correct column names dynamically" do
      result = @connection.exec_query("SELECT id, name, email FROM test_users")
      expect(result.columns).to eq(["id", "name", "email"])
    end

    it "returns correct data" do
      result = @connection.exec_query("SELECT id, name FROM test_users WHERE id = 1")
      expect(result.rows).to eq([[1, "Alice"]])
    end

    it "handles single-column queries" do
      result = @connection.exec_query("SELECT COUNT(*) as total FROM test_users")
      expect(result.columns).to eq(["total"])
    end

    it "handles four-column queries" do
      result = @connection.exec_query("SELECT id, name, email, age FROM test_users")
      expect(result.columns).to eq(["id", "name", "email", "age"])
    end
  end
end
