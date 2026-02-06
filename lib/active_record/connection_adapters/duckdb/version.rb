# frozen_string_literal: true

module ActiveRecord
  module ConnectionAdapters
    module DuckDB
      VERSION = File.read(File.expand_path("../../../../VERSION", __dir__)).chomp
    end
  end
end
