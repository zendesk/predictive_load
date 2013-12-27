module PredictiveLoad::ActiveRecordCollectionObservation

  def self.included(base)
    ActiveRecord::Relation.send(:include, RelationObservation)
    ActiveRecord::Base.send(:include, CollectionMember)
    ActiveRecord::Associations::Association.send(:include, AssociationNotification)
    ActiveRecord::Associations::CollectionAssociation.send(:include, CollectionAssociationNotification)
  end

  module RelationObservation

    def self.included(base)
      base.class_attribute :collection_observer
      base.alias_method_chain :to_a, :collection_observer
    end

    def to_a_with_collection_observer
      records = to_a_without_collection_observer

      if records.size > 1 && collection_observer
        collection_observer.new(records.dup).observe
      end

      records
    end

  end

  module CollectionMember

    attr_accessor :collection_observer

  end

  module AssociationNotification

    def self.included(base)
      base.alias_method_chain :load_target, :notification
    end

    def load_target_with_notification
      notify_collection_observer if find_target?

      load_target_without_notification
    end

    protected

    def notify_collection_observer
      if @owner.collection_observer
        @owner.collection_observer.loading_association(@owner, @reflection.name)
      end
    end

  end

  module CollectionAssociationNotification

    def self.included(base)
      base.alias_method_chain :load_target, :notification
    end

    def load_target_with_notification
      notify_collection_observer if find_target?

      load_target_without_notification
    end

  end

end
