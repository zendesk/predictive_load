require "bundler/setup"
require "minitest/autorun"
require "minitest/rg"
require "active_record"
require "active_support/all"
require "active_record/associations/builder/belongs_to" # pretend we loaded this first to test initializer
require "predictive_load"
require "predictive_load/active_record_collection_observation"
require "pry-byebug"

ActiveRecord::Base.class_eval do
  include PredictiveLoad::ActiveRecordCollectionObservation
end

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)
require_relative "schema"
require_relative "models"

class QueryCounter
  OPERATIONS = %w[SELECT INSERT UPDATE DELETE]

  attr_reader :queries

  def initialize
    @queries = []
  end

  def execute!(&block)
    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record", &block)
  end

  private

  def subscriber
    ->(*, payload) { @queries << payload[:sql] if OPERATIONS.any? { |op| payload[:sql].lstrip.start_with?(op) } }
  end
end

def assert_queries(num = 1, &block)
  counter = QueryCounter.new
  result = counter.execute!(&block)
  queries = counter.queries
  assert_equal num, queries.size, "#{queries.size} instead of #{num} queries were executed.#{"\nQueries:\n#{queries.join("\n")}" unless queries.empty?}"
  result
end
