module PredictiveLoad::ActiveRecordCollectionObservation

  def self.included(base)
    if ActiveRecord::VERSION::MAJOR >= 5
      ActiveRecord::Relation.send(:include, Rails5RelationObservation)
    else
      ActiveRecord::Relation.send(:include, RelationObservation)
    end
    ActiveRecord::Base.send(:include, CollectionMember)
    ActiveRecord::Base.send(:extend, UnscopedTracker)
    ActiveRecord::Associations::Association.send(:include, AssociationNotification)
    ActiveRecord::Associations::CollectionAssociation.send(:include, CollectionAssociationNotification)
  end

  module Rails5RelationObservation

    def self.included(base)
      base.class_attribute :collection_observer
      base.send(:alias_method, :records_without_collection_observer, :records)
      base.send(:alias_method, :records, :records_with_collection_observer)
    end

    def records_with_collection_observer
      records = records_without_collection_observer

      if records.size > 1 && collection_observer
        collection_observer.observe(records.dup)
      end

      records
    end

  end

  module RelationObservation

    def self.included(base)
      base.class_attribute :collection_observer
      base.send(:alias_method, :to_a_without_collection_observer, :to_a)
      base.send(:alias_method, :to_a, :to_a_with_collection_observer)
    end

    def to_a_with_collection_observer
      records = to_a_without_collection_observer

      if records.size > 1 && collection_observer
        collection_observer.observe(records.dup)
      end

      records
    end

  end

  module CollectionMember

    attr_accessor :collection_observer

  end

  # disable eager loading since includes + unscoped is broken on rails 4
  module UnscopedTracker
    if ActiveRecord::VERSION::MAJOR >= 4
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
    end

    def predictive_load_disabled
      Thread.current[:predictive_load_disabled] ||= []
    end
  end

  module AssociationNotification

    def self.included(base)
      base.send(:alias_method, :load_target_without_notification, :load_target)
      base.send(:alias_method, :load_target, :load_target_with_notification)
    end

    def load_target_with_notification
      notify_collection_observer if find_target?

      load_target_without_notification
    end

    protected

    def notify_collection_observer
      if @owner.collection_observer
        @owner.collection_observer.loading_association(@owner, self)
      end
    end

  end

  module CollectionAssociationNotification

    def self.included(base)
      base.send(:alias_method, :load_target_without_notification, :load_target)
      base.send(:alias_method, :load_target, :load_target_with_notification)
    end

    def load_target_with_notification
      notify_collection_observer if find_target?

      load_target_without_notification
    end

  end

end
