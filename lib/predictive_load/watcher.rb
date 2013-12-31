require 'predictive_load/loader'

module PredictiveLoad
  # Provides N+1 detection / log mode.
  #
  # Usage:
  # ActiveRecord::Relation.collection_observer = PredictiveLoad::Watcher
  #
  # Example output:
  # lazy_loader_log: detected n1 call on Comment#account
  # lazy_loader_log: expect to prevent 1 queries
  # lazy_loader_log: would preload with: SELECT `accounts`.* FROM `accounts`  WHERE `accounts`.`id` IN (...)
  # lazy_loader_log: +----+-------------+----------+-------+---------------+---------+---------+-------+------+-------+
  # lazy_loader_log: | id | select_type | table    | type  | possible_keys | key     | key_len | ref   | rows | Extra |
  # lazy_loader_log: +----+-------------+----------+-------+---------------+---------+---------+-------+------+-------+
  # lazy_loader_log: |  1 | SIMPLE      | accounts | const | PRIMARY       | PRIMARY | 4       | const |    1 |       |
  # lazy_loader_log: +----+-------------+----------+-------+---------------+---------+---------+-------+------+-------+
  # lazy_loader_log: 1 row in set (0.00 sec)
  # lazy_loader_log: would have prevented all 1 queries
  class Watcher < Loader

    attr_reader :loaded_associations

    def initialize(records)
      super
      @loaded_associations = {}
    end

    def loading_association(record, association_name)
      return if !all_records_will_likely_load_association?(association_name)

      if loaded_associations.key?(association_name)
        log_query_plan(association_name)
      end

      increment_query_count(association_name)
    end

    protected

    def log_query_plan(association_name)
      log("detected n1 call on #{records.first.class.name}##{association_name}")

      # Detailed logging for first query
      if query_count == 1
        log("expect to prevent #{expected_query_count} queries")
        log_preload(association_name)
      end

      # All records loaded association
      if query_count == expected_query_count
        log("would have prevented all #{expected_query_count} queries")
      end

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
      Rails.logger.info("lazy_loader: #{message}")
    end

  end
end
