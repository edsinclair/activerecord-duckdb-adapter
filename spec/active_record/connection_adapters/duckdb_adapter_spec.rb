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
end
