$TESTING = true
require 'coveralls'
Coveralls.wear! do
  add_filter "/test/"
end

ENV['RACK_ENV'] = ENV['RAILS_ENV'] = 'test'

if ENV.has_key?("SIMPLECOV")
  require 'simplecov'
  SimpleCov.start do
    add_filter "/test/"
  end
end

begin
  require 'pry'
rescue LoadError
end

require 'casted_hash'

require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/setup'
