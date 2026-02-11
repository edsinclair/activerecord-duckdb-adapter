# frozen_string_literal: true

require "spec_helper"

RSpec.describe "DuckDB Data Types" do
  before(:each) do
    @connection = ActiveRecord::Base.connection
  end

  describe "NATIVE_DATABASE_TYPES" do
    it "includes all essential Rails types" do
      types = ActiveRecord::ConnectionAdapters::DuckdbAdapter::NATIVE_DATABASE_TYPES
      %i[string text integer float decimal datetime date
         time boolean binary bigint].each do |t|
        expect(types).to have_key(t), "Missing type: #{t}"
      end
    end
  end

  describe "type round-trips" do
    before(:each) do
      @connection.execute(<<-SQL)
        CREATE TABLE test_types (
          str_val VARCHAR,
          int_val INTEGER,
          bigint_val BIGINT,
          float_val DOUBLE,
          decimal_val DECIMAL(10,2),
          bool_val BOOLEAN,
          date_val DATE,
          datetime_val TIMESTAMP
        )
      SQL
    end
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_types") }

    it "stores and retrieves strings" do
      @connection.execute("INSERT INTO test_types (str_val) VALUES ('hello')")
      expect(@connection.select_value("SELECT str_val FROM test_types")).to eq("hello")
    end

    it "stores and retrieves integers" do
      @connection.execute("INSERT INTO test_types (int_val) VALUES (42)")
      expect(@connection.select_value("SELECT int_val FROM test_types")).to eq(42)
    end

    it "stores and retrieves booleans" do
      @connection.execute("INSERT INTO test_types (bool_val) VALUES (true)")
      expect(@connection.select_value("SELECT bool_val FROM test_types")).to eq(true)
    end

    it "stores and retrieves dates" do
      @connection.execute("INSERT INTO test_types (date_val) VALUES ('2024-01-15')")
      result = @connection.select_value("SELECT date_val FROM test_types")
      expect(result).to be_a(Date)
      expect(result.to_s).to eq("2024-01-15")
    end
  end

  describe "quoting" do
    it "quotes strings with single quotes" do
      expect(@connection.quote("hello")).to eq("'hello'")
    end

    it "escapes single quotes in strings" do
      expect(@connection.quote("it's")).to eq("'it''s'")
    end

    it "quotes booleans as TRUE/FALSE" do
      expect(@connection.quoted_true).to eq("TRUE")
      expect(@connection.quoted_false).to eq("FALSE")
    end

    it "quotes nil as NULL" do
      expect(@connection.quote(nil)).to eq("NULL")
    end

    it "quotes column names with double quotes" do
      expect(@connection.quote_column_name("name")).to eq('"name"')
    end

    it "quotes table names with double quotes" do
      expect(@connection.quote_table_name("users")).to eq('"users"')
    end
  end
end
