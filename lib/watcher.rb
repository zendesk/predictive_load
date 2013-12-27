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
      return if Rails.env.test? && association_name.to_s.index('_stub_')

      if query_count = @loaded_associations[association_name]
        log("detected n1 call on #{records.first.class.name}##{association_name}")

        if query_count == 1
          log("expect to prevent #{expected_query_count} queries")
          log_preload(association_name)
        end

        if query_count == expected_query_count
          log("would have prevented all #{expected_query_count} queries")
        end
      end

      @loaded_associations[association_name] ||= 0
      @loaded_associations[association_name] += 1
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
