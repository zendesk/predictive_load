require 'active_record/associations/preloader'

module PredictiveLoad
  class PreloadLog < ActiveRecord::Associations::Preloader

    attr_accessor :logger

    def preload(association)
      grouped_records(association).each do |reflection, klasses|
        klasses.each do |klass, records|
          preloader   = preloader_for(reflection).new(klass, records, reflection, options)

          if preloader.respond_to?(:through_reflection)
            log("encountered :through association for #{association}. Requires loading records to generate query, so skipping for now.")
            next
          end

          preload_sql = preloader.scoped.where(collection_arel(preloader)).to_sql

          log("would preload with: #{preload_sql.to_s}")
          ActiveRecord::Base.connection.explain(preload_sql).each_line do |line|
            log(line)
          end
        end
      end
    end

    def collection_arel(preloader)
      owners_map = preloader.owners_by_key
      owner_keys = owners_map.keys.compact
      preloader.association_key.in(owner_keys)
    end

    def log(message)
      ActiveRecord::Base.logger.info("predictive_load: #{message}")
    end

  end

end
