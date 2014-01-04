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

def assert_queries(num = 1)
  ActiveRecord::SQLCounter.log = []
  yield
ensure
  assert_equal num, ActiveRecord::SQLCounter.log.size, "#{ActiveRecord::SQLCounter.log.size} instead of #{num} queries were executed.#{ActiveRecord::SQLCounter.log.size == 0 ? '' : "\nQueries:\n#{ActiveRecord::SQLCounter.log.join("\n")}"}"
end

# Yanked from ActiveRecord tests
module ActiveRecord
  class SQLCounter
    cattr_accessor :ignored_sql
    self.ignored_sql = [/^PRAGMA (?!(table_info))/, /^SELECT currval/, /^SELECT CAST/, /^SELECT @@IDENTITY/, /^SELECT @@ROWCOUNT/, /^SAVEPOINT/, /^ROLLBACK TO SAVEPOINT/, /^RELEASE SAVEPOINT/, /^SHOW max_identifier_length/, /^BEGIN/, /^COMMIT/]

    # FIXME: this needs to be refactored so specific database can add their own
    # ignored SQL.  This ignored SQL is for Oracle.
    ignored_sql.concat [/^select .*nextval/i, /^SAVEPOINT/, /^ROLLBACK TO/, /^\s*select .* from all_triggers/im]

    cattr_accessor :log
    self.log = []

    attr_reader :ignore

    def initialize(ignore = self.class.ignored_sql)
      @ignore   = ignore
    end

    def call(name, start, finish, message_id, values)
      sql = values[:sql]

      # FIXME: this seems bad. we should probably have a better way to indicate
      # the query was cached
      return if 'CACHE' == values[:name] || ignore.any? { |x| x =~ sql }
      self.class.log << sql
    end
  end

  ActiveSupport::Notifications.subscribe('sql.active_record', SQLCounter.new)
end
