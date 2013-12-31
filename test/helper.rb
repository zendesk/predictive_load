require 'rubygems'
require 'bundler/setup'
require 'minitest'
require 'minitest/spec'
require 'minitest/autorun'
require 'active_record'
require 'predictive_load'
require 'predictive_load/active_record_collection_observation'

ActiveRecord::Base.class_eval do
  include PredictiveLoad::ActiveRecordCollectionObservation
end

database_config = YAML.load_file(File.join(File.dirname(__FILE__), 'database.yml'))
ActiveRecord::Base.establish_connection(database_config['test'])
ActiveRecord::Base.default_timezone = :utc
require_relative 'schema'
require_relative 'models'
