# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "activerecord", "~> #{ENV["ACTIVERECORD_VERSION"]}.0" if ENV["ACTIVERECORD_VERSION"]

group :development, :test do
  gem "debug"
  gem "rake"
  gem "rspec"
  gem "rubocop"
end
