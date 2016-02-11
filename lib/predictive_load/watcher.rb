raise "Not supported on rails 4.1+" if ActiveRecord::VERSION::STRING >= "4.1.0"

require 'predictive_load/loader'
require 'predictive_load/preload_log'

module PredictiveLoad
  # Provides N+1 detection / log mode.
  #
  # Usage:
  # ActiveRecord::Relation.collection_observer = PredictiveLoad::Watcher
  #
  # Example output:
  # predictive_load: detected n1 call on Comment#account
  # predictive_load: expect to prevent 1 queries
  # predictive_load: would preload with: SELECT `accounts`.* FROM `accounts`  WHERE `accounts`.`id` IN (...)
  # predictive_load: +----+-------------+----------+-------+---------------+---------+---------+-------+------+-------+
  # predictive_load: | id | select_type | table    | type  | possible_keys | key     | key_len | ref   | rows | Extra |
  # predictive_load: +----+-------------+----------+-------+---------------+---------+---------+-------+------+-------+
  # predictive_load: |  1 | SIMPLE      | accounts | const | PRIMARY       | PRIMARY | 4       | const |    1 |       |
  # predictive_load: +----+-------------+----------+-------+---------------+---------+---------+-------+------+-------+
  # predictive_load: 1 row in set (0.00 sec)
  # predictive_load: would have prevented all 1 queries
  class Watcher < Loader

    attr_reader :loaded_associations

    def initialize(records)
      super
      @loaded_associations = {}
    end

    def loading_association(record, association)
      association_name = association.reflection.name
      return if !all_records_will_likely_load_association?(association_name)
      return if !supports_preload?(association)

      if loaded_associations.key?(association_name)
        log_query_plan(association_name)
      end

      increment_query_count(association_name)
    end

    protected

    def log_query_plan(association_name)
      log("detected n+1 call on #{records.first.class.name}##{association_name}")

      # Detailed logging for first query
      if query_count(association_name) == 1
        log("expect to prevent #{expected_query_count} queries")
        log_preload(association_name)
      end

      # All records loaded association
      if query_count(association_name) == expected_query_count
        log("would have prevented all #{expected_query_count} queries")
      end

    end

    def query_count(association_name)
      loaded_associations[association_name] || 0
    end

    def increment_query_count(association_name)
      loaded_associations[association_name] ||= 0
      loaded_associations[association_name] += 1
    end

    def expected_query_count
      records.size - 1
    end

    def log_preload(association_name)
      PreloadLog.new(records_with_association(association_name), [ association_name ]).run
    end

    def log(message)
      ActiveRecord::Base.logger.info("predictive_load: #{message}")
    end

  end
end
