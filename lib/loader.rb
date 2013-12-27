module PredictiveLoad
  # Predictive loader
  #
  # Usage:
  # ActiveRecord::Relation.collection_observer = LazyLoader
  #
  class Loader

    attr_reader :records

    def initialize(records)
      @records = records
    end

    def observe
      records.each do |record|
        record.collection_observer = self
      end
    end

    def loading_association(record, association_name)
      return if Rails.env.test? && association_name.to_s.index('_stub_')

      preload(association_name)
    end

    def preload(association_name)
      ActiveRecord::Associations::Preloader.new(records_with_association(association_name), [ association_name ]).run
    end

    def records_with_association(association_name)
      if mixed_collection?
        @records.select { |r| r.class.reflect_on_association(association_name) }
      else
        @records
      end
    end

    def mixed_collection?
      @mixed_collection ||= begin
                              klass = records.first.class
                              records.any? { |record| record.class != klass }
                            end
    end

  end
end
