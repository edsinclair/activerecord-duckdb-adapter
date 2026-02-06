# frozen_string_literal: true

require "spec_helper"

RSpec.describe "DuckDB SchemaStatements" do
  before(:each) do
    @connection = ActiveRecord::Base.connection
  end

  describe "#tables" do
    before(:each) do
      @connection.execute("CREATE TABLE test_table_1 (id INTEGER)")
      @connection.execute("CREATE TABLE test_table_2 (id INTEGER)")
    end
    after(:each) do
      @connection.execute("DROP TABLE IF EXISTS test_table_1")
      @connection.execute("DROP TABLE IF EXISTS test_table_2")
    end

    it "returns list of tables" do
      tables = @connection.tables
      expect(tables).to include("test_table_1", "test_table_2")
    end

    it "excludes views from tables list" do
      @connection.execute("CREATE VIEW test_view AS SELECT * FROM test_table_1")
      expect(@connection.tables).not_to include("test_view")
      @connection.execute("DROP VIEW test_view")
    end
  end

  describe "#table_exists?" do
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_exists") }

    it "returns true for existing table" do
      @connection.execute("CREATE TABLE test_exists (id INTEGER)")
      expect(@connection.table_exists?("test_exists")).to be true
    end

    it "returns false for non-existing table" do
      expect(@connection.table_exists?("non_existent_table")).to be false
    end
  end

  describe "#columns" do
    before(:each) do
      @connection.execute(<<-SQL)
        CREATE TABLE test_columns (
          id INTEGER PRIMARY KEY,
          name VARCHAR,
          age INTEGER,
          created_at TIMESTAMP
        )
      SQL
    end
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_columns") }

    it "returns array of columns" do
      columns = @connection.columns("test_columns")
      expect(columns).to be_an(Array)
      expect(columns.length).to eq(4)
    end

    it "returns correct column names" do
      column_names = @connection.columns("test_columns").map(&:name)
      expect(column_names).to include("id", "name", "age", "created_at")
    end

    it "returns correct column types" do
      columns = @connection.columns("test_columns")
      expect(columns.find { |c| c.name == "id" }.type).to eq(:integer)
      expect(columns.find { |c| c.name == "name" }.type).to eq(:string)
    end
  end

  describe "#primary_keys" do
    after(:each) do
      @connection.execute("DROP TABLE IF EXISTS test_pk")
      @connection.execute("DROP TABLE IF EXISTS test_no_pk")
      @connection.execute("DROP TABLE IF EXISTS test_composite_pk")
    end

    it "returns primary key for single column" do
      @connection.execute("CREATE TABLE test_pk (id INTEGER PRIMARY KEY, name VARCHAR)")
      expect(@connection.primary_keys("test_pk")).to eq(["id"])
    end

    it "returns empty array for table without primary key" do
      @connection.execute("CREATE TABLE test_no_pk (id INTEGER, name VARCHAR)")
      expect(@connection.primary_keys("test_no_pk")).to eq([])
    end

    it "returns multiple columns for composite primary key" do
      @connection.execute("CREATE TABLE test_composite_pk (id1 INTEGER, id2 INTEGER, PRIMARY KEY (id1, id2))")
      expect(@connection.primary_keys("test_composite_pk")).to contain_exactly("id1", "id2")
    end
  end

  describe "#views" do
    before(:each) do
      @connection.execute("CREATE TABLE test_base (id INTEGER)")
      @connection.execute("CREATE VIEW test_view AS SELECT * FROM test_base")
    end
    after(:each) do
      @connection.execute("DROP VIEW IF EXISTS test_view")
      @connection.execute("DROP TABLE IF EXISTS test_base")
    end

    it "returns list of views" do
      expect(@connection.views).to include("test_view")
    end

    it "excludes tables from views list" do
      expect(@connection.views).not_to include("test_base")
    end
  end
end
