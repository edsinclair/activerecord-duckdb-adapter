# frozen_string_literal: true

require "spec_helper"

RSpec.describe "DuckDB EXPLAIN" do
  before(:each) do
    @connection = ActiveRecord::Base.connection
    @connection.execute("CREATE TABLE test_explain (id INTEGER, name VARCHAR)")
    @connection.execute("INSERT INTO test_explain VALUES (1, 'Alice')")
  end
  after(:each) { @connection.execute("DROP TABLE IF EXISTS test_explain") }

  it "returns explain output for a query" do
    result = @connection.explain("SELECT * FROM test_explain WHERE id = 1")
    expect(result).to be_a(String)
    expect(result).not_to be_empty
  end
end
