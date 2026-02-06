# frozen_string_literal: true

require "spec_helper"

class DuckdbTestUser < ActiveRecord::Base
  self.table_name = "duckdb_test_users"
end

RSpec.describe "ActiveRecord Model Integration" do
  before(:each) do
    @connection = ActiveRecord::Base.connection
    @connection.execute("DROP TABLE IF EXISTS duckdb_test_users")
    @connection.create_table(:duckdb_test_users) do |t|
      t.string :name
      t.string :email
      t.integer :age
    end
    DuckdbTestUser.reset_column_information
  end

  after(:each) do
    @connection.execute("DROP TABLE IF EXISTS duckdb_test_users")
  end

  it "creates record with auto-generated id" do
    user = DuckdbTestUser.create!(name: "John", email: "john@example.com", age: 30)
    expect(user.persisted?).to be true
    expect(user.id).not_to be_nil
  end

  it "reads record by id" do
    user = DuckdbTestUser.create!(name: "Jane", email: "jane@example.com")
    found = DuckdbTestUser.find(user.id)
    expect(found.name).to eq("Jane")
  end

  it "updates record" do
    user = DuckdbTestUser.create!(name: "Bob", email: "bob@example.com")
    user.update!(name: "Robert")
    expect(DuckdbTestUser.find(user.id).name).to eq("Robert")
  end

  it "deletes record" do
    user = DuckdbTestUser.create!(name: "Charlie", email: "charlie@example.com")
    user_id = user.id
    user.destroy!
    expect(DuckdbTestUser.find_by(id: user_id)).to be_nil
  end

  it "queries with where" do
    DuckdbTestUser.create!(name: "Alice", email: "alice@example.com", age: 25)
    DuckdbTestUser.create!(name: "Bob", email: "bob@example.com", age: 35)
    young = DuckdbTestUser.where("age < ?", 30)
    expect(young.count).to eq(1)
    expect(young.first.name).to eq("Alice")
  end

  it "supports count" do
    DuckdbTestUser.create!(name: "A", email: "a@test.com")
    DuckdbTestUser.create!(name: "B", email: "b@test.com")
    expect(DuckdbTestUser.count).to eq(2)
  end

  it "supports order" do
    DuckdbTestUser.create!(name: "Zoe", email: "z@test.com")
    DuckdbTestUser.create!(name: "Alice", email: "a@test.com")
    expect(DuckdbTestUser.order(:name).first.name).to eq("Alice")
  end
end
