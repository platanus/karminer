ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

# Set up gems listed in the Gemfile.
require 'bundler/setup'
Bundler.require(:default)

require 'dotenv/load' # setup enviroment

# ensure lib path is loaded
lib_dir = File.expand_path('./lib')
$:.unshift(lib_dir) unless $:.include?(lib_dir)

require 'karminer'

# Miner entry point
