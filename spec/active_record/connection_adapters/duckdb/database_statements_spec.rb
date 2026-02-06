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

  describe "#execute" do
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_execute") }

    it "executes CREATE TABLE" do
      expect {
        @connection.execute("CREATE TABLE test_execute (id INTEGER, name VARCHAR)")
      }.not_to raise_error
    end

    it "executes INSERT" do
      @connection.execute("CREATE TABLE test_execute (id INTEGER, name VARCHAR)")
      expect {
        @connection.execute("INSERT INTO test_execute VALUES (1, 'Test')")
      }.not_to raise_error
    end

    it "executes SELECT and returns result" do
      @connection.execute("CREATE TABLE test_execute (id INTEGER, name VARCHAR)")
      @connection.execute("INSERT INTO test_execute VALUES (1, 'Test')")
      result = @connection.execute("SELECT * FROM test_execute")
      expect(result).not_to be_nil
    end
  end

  describe "select methods" do
    before(:each) do
      @connection.execute("CREATE TABLE test_select (id INTEGER, name VARCHAR)")
      @connection.execute("INSERT INTO test_select VALUES (1, 'Alice')")
      @connection.execute("INSERT INTO test_select VALUES (2, 'Bob')")
    end
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_select") }

    it "#select_all returns all rows" do
      result = @connection.select_all("SELECT * FROM test_select ORDER BY id")
      expect(result.to_a.length).to eq(2)
    end

    it "#select_all returns correct column names" do
      result = @connection.select_all("SELECT id, name FROM test_select")
      expect(result.columns).to eq(["id", "name"])
    end

    it "#select_one returns single row as hash" do
      result = @connection.select_one("SELECT * FROM test_select WHERE id = 1")
      expect(result).to be_a(Hash)
      expect(result["name"]).to eq("Alice")
    end

    it "#select_value returns single value" do
      result = @connection.select_value("SELECT COUNT(*) FROM test_select")
      expect(result).to eq(2)
    end

    it "#select_values returns array of first column values" do
      result = @connection.select_values("SELECT name FROM test_select ORDER BY id")
      expect(result).to eq(["Alice", "Bob"])
    end
  end
end
