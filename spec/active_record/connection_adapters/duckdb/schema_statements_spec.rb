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

  describe "#create_table" do
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_create") }

    it "creates table with columns" do
      @connection.create_table(:test_create) do |t|
        t.string :name
        t.integer :age
      end
      expect(@connection.table_exists?(:test_create)).to be true
      expect(@connection.columns(:test_create).map(&:name)).to include("name", "age")
    end

    it "creates table with auto-increment primary key" do
      @connection.create_table(:test_create) do |t|
        t.string :name
      end
      expect(@connection.primary_keys(:test_create)).to eq(["id"])
    end

    it "creates table without primary key when id: false" do
      @connection.create_table(:test_create, id: false) do |t|
        t.string :name
      end
      expect(@connection.primary_keys(:test_create)).to eq([])
    end
  end

  describe "#drop_table" do
    it "drops existing table" do
      @connection.execute("CREATE TABLE test_drop (id INTEGER)")
      @connection.drop_table(:test_drop)
      expect(@connection.table_exists?(:test_drop)).to be false
    end

    it "does not raise error with if_exists option" do
      expect { @connection.drop_table(:non_existent, if_exists: true) }.not_to raise_error
    end
  end

  describe "#add_column" do
    before(:each) do
      @connection.execute("CREATE TABLE test_add_col (name VARCHAR)")
    end
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_add_col") }

    it "adds column to existing table" do
      @connection.add_column(:test_add_col, :age, :integer)
      age_col = @connection.columns(:test_add_col).find { |c| c.name == "age" }
      expect(age_col).not_to be_nil
      expect(age_col.type).to eq(:integer)
    end
  end

  describe "#remove_column" do
    before(:each) do
      @connection.execute("CREATE TABLE test_rm_col (name VARCHAR, age INTEGER)")
    end
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_rm_col") }

    it "removes column from table" do
      @connection.remove_column(:test_rm_col, :age)
      column_names = @connection.columns(:test_rm_col).map(&:name)
      expect(column_names).not_to include("age")
      expect(column_names).to include("name")
    end
  end

  describe "#rename_table" do
    after(:each) do
      @connection.execute("DROP TABLE IF EXISTS old_name")
      @connection.execute("DROP TABLE IF EXISTS new_name")
      @connection.execute("DROP SEQUENCE IF EXISTS old_name_id_seq")
      @connection.execute("DROP SEQUENCE IF EXISTS new_name_id_seq")
    end

    it "renames table" do
      @connection.execute("CREATE TABLE old_name (data VARCHAR)")
      @connection.rename_table(:old_name, :new_name)
      expect(@connection.table_exists?(:old_name)).to be false
      expect(@connection.table_exists?(:new_name)).to be true
    end

    it "renames sequence and auto-increment still works after rename" do
      @connection.create_table(:old_name) { |t| t.string :name }
      @connection.execute("INSERT INTO old_name (name) VALUES ('before')")
      @connection.rename_table(:old_name, :new_name)

      # Verify new sequence exists and old one doesn't
      sequences = @connection.select_values("SELECT sequence_name FROM duckdb_sequences()")
      expect(sequences).to include("new_name_id_seq")
      expect(sequences).not_to include("old_name_id_seq")

      # Verify auto-increment still works
      @connection.execute("INSERT INTO new_name (name) VALUES ('after')")
      ids = @connection.select_values("SELECT id FROM new_name ORDER BY id")
      expect(ids.length).to eq(2)
      expect(ids.last).to be > ids.first
    end
  end

  describe "#add_index and #indexes" do
    before(:each) do
      @connection.execute("CREATE TABLE test_idx (email VARCHAR, name VARCHAR)")
    end
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_idx") }

    it "adds index on single column" do
      @connection.add_index(:test_idx, :email)
      idx = @connection.indexes(:test_idx).find { |i| i.columns == ["email"] }
      expect(idx).not_to be_nil
    end

    it "adds named index" do
      @connection.add_index(:test_idx, :email, name: "idx_email")
      expect(@connection.indexes(:test_idx).map(&:name)).to include("idx_email")
    end

    it "adds unique index" do
      @connection.add_index(:test_idx, :email, unique: true)
      idx = @connection.indexes(:test_idx).find { |i| i.columns == ["email"] }
      expect(idx.unique).to be true
    end

    it "adds composite index" do
      @connection.add_index(:test_idx, [:email, :name])
      idx = @connection.indexes(:test_idx).find { |i| i.columns == ["email", "name"] }
      expect(idx).not_to be_nil
    end
  end

  describe "#remove_index" do
    before(:each) do
      @connection.execute("CREATE TABLE test_rm_idx (email VARCHAR)")
      @connection.add_index(:test_rm_idx, :email, name: "idx_email")
    end
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_rm_idx") }

    it "removes index by name" do
      @connection.remove_index(:test_rm_idx, name: "idx_email")
      expect(@connection.indexes(:test_rm_idx)).to be_empty
    end
  end

  describe "#change_column_default" do
    before(:each) { @connection.execute("CREATE TABLE test_alter (name VARCHAR, status VARCHAR DEFAULT 'active')") }
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_alter") }

    it "sets a new default value" do
      @connection.change_column_default(:test_alter, :status, "inactive")
      @connection.execute("INSERT INTO test_alter (name) VALUES ('test')")
      expect(@connection.select_value("SELECT status FROM test_alter")).to eq("inactive")
    end

    it "drops default value" do
      @connection.change_column_default(:test_alter, :status, nil)
      @connection.execute("INSERT INTO test_alter (name) VALUES ('test')")
      expect(@connection.select_value("SELECT status FROM test_alter")).to be_nil
    end
  end

  describe "#change_column_null" do
    before(:each) { @connection.execute("CREATE TABLE test_null (name VARCHAR)") }
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_null") }

    it "adds NOT NULL constraint" do
      @connection.change_column_null(:test_null, :name, false)
      expect {
        @connection.execute("INSERT INTO test_null (name) VALUES (NULL)")
      }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "removes NOT NULL constraint" do
      @connection.execute("ALTER TABLE test_null ALTER COLUMN name SET NOT NULL")
      @connection.change_column_null(:test_null, :name, true)
      expect {
        @connection.execute("INSERT INTO test_null (name) VALUES (NULL)")
      }.not_to raise_error
    end
  end

  describe "#rename_column" do
    before(:each) { @connection.execute("CREATE TABLE test_rename_col (old_name VARCHAR)") }
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_rename_col") }

    it "renames column" do
      @connection.rename_column(:test_rename_col, :old_name, :new_name)
      column_names = @connection.columns(:test_rename_col).map(&:name)
      expect(column_names).to include("new_name")
      expect(column_names).not_to include("old_name")
    end
  end

  describe "#change_column" do
    before(:each) { @connection.execute("CREATE TABLE test_change_type (val INTEGER)") }
    after(:each) { @connection.execute("DROP TABLE IF EXISTS test_change_type") }

    it "changes column type" do
      @connection.change_column(:test_change_type, :val, :string)
      col = @connection.columns(:test_change_type).find { |c| c.name == "val" }
      expect(col.type).to eq(:string)
    end
  end

  describe "#foreign_keys" do
    before(:each) do
      @connection.execute("CREATE TABLE fk_parent (id INTEGER PRIMARY KEY)")
      @connection.execute("CREATE TABLE fk_child (id INTEGER, parent_id INTEGER REFERENCES fk_parent(id))")
    end
    after(:each) do
      @connection.execute("DROP TABLE IF EXISTS fk_child")
      @connection.execute("DROP TABLE IF EXISTS fk_parent")
    end

    it "returns foreign keys for a table" do
      fks = @connection.foreign_keys("fk_child")
      expect(fks.length).to eq(1)
      expect(fks.first.from_table).to eq("fk_child")
      expect(fks.first.to_table).to eq("fk_parent")
      expect(fks.first.column).to eq("parent_id")
      expect(fks.first.primary_key).to eq("id")
    end

    it "returns empty array for table without foreign keys" do
      fks = @connection.foreign_keys("fk_parent")
      expect(fks).to be_empty
    end
  end
end
