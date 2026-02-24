# frozen_string_literal: true

source "https://rubygems.org"

gemspec

if ENV["ACTIVERECORD_VERSION"]
  gem "activerecord", "~> #{ENV["ACTIVERECORD_VERSION"]}"
end

group :development, :test do
  gem "debug"
  gem "rake"
  gem "rspec"
  gem "rubocop"
end
