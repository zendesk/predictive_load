module PredictiveLoad::ActiveRecordCollectionObservation
  def self.included(base)
    ActiveRecord::Relation.class_attribute :collection_observer
    ActiveRecord::Relation.prepend Rails5RelationObservation
    ActiveRecord::Base.include CollectionMember
    ActiveRecord::Base.extend UnscopedTracker
    ActiveRecord::Associations::Association.prepend AssociationNotification
    ActiveRecord::Associations::CollectionAssociation.prepend CollectionAssociationNotification
  end

  module Rails5RelationObservation
    # this essentially intercepts the enumerable methods that would result in n+1s since most of
    # those are delegated to :records in Rails 5+ in the ActiveRecord::Relation::Delegation module
    def records
      record_array = super
      if record_array.size > 1 && collection_observer
        collection_observer.observe(record_array.dup)
      end
      record_array
    end
  end

  module CollectionMember
    attr_accessor :collection_observer
  end

  # disable eager loading since includes + unscoped is broken on rails 4
  module UnscopedTracker
    def unscoped
      if block_given?
        begin
          predictive_load_disabled << self
          super
        ensure
          predictive_load_disabled.pop
        end
      else
        super
      end
    end

    def predictive_load_disabled
      Thread.current[:predictive_load_disabled] ||= []
    end
  end

  module AssociationNotification
    def load_target
      notify_collection_observer if find_target?

      super
    end

    protected

    def notify_collection_observer
      @owner.collection_observer&.loading_association(@owner, self)
    end
  end

  module CollectionAssociationNotification
    def load_target
      notify_collection_observer if find_target?

      super
    end
  end
end
