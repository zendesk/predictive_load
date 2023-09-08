require "bundler/setup"
require "minitest/autorun"
require "minitest/rg"
require "active_record"
require "active_support/all"
require "active_record/associations/builder/belongs_to" # pretend we loaded this first to test initializer
require "predictive_load"
require "predictive_load/active_record_collection_observation"
require "query_diet/logger"
require "query_diet/active_record_ext"

ActiveRecord::Base.class_eval do
  include PredictiveLoad::ActiveRecordCollectionObservation
end

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)
ActiveRecord::Base.default_timezone = :utc
require_relative "schema"
require_relative "models"

def assert_queries(num = 1)
  old = QueryDiet::Logger.queries.dup
  result = yield
  new = QueryDiet::Logger.queries[old.size..]
  assert_equal num, new.size, "#{new.size} instead of #{num} queries were executed.#{new.size == 0 ? '' : "\nQueries:\n#{new.map(&:first).join("\n")}"}"
  result
end
