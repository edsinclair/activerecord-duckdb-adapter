# frozen_string_literal: true

require "spec_helper"

RSpec.describe "DuckDB Transactions" do
  before(:each) do
    @connection = ActiveRecord::Base.connection
    @connection.execute("CREATE TABLE test_txn (name VARCHAR)")
  end

  after(:each) do
    @connection.execute("DROP TABLE IF EXISTS test_txn")
  end

  it "commits transaction" do
    @connection.transaction do
      @connection.execute("INSERT INTO test_txn (name) VALUES ('Test')")
    end
    expect(@connection.select_value("SELECT COUNT(*) FROM test_txn")).to eq(1)
  end

  it "rolls back transaction on error" do
    expect do
      @connection.transaction do
        @connection.execute("INSERT INTO test_txn (name) VALUES ('Test')")
        raise "Rollback"
      end
    end.to raise_error(RuntimeError)
    expect(@connection.select_value("SELECT COUNT(*) FROM test_txn")).to eq(0)
  end

  it "rolls back transaction on ActiveRecord::Rollback" do
    @connection.transaction do
      @connection.execute("INSERT INTO test_txn (name) VALUES ('Test')")
      raise ActiveRecord::Rollback
    end
    expect(@connection.select_value("SELECT COUNT(*) FROM test_txn")).to eq(0)
  end

  it "does not support savepoints" do
    expect(@connection.supports_savepoints?).to be false
  end
end
