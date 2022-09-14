module PredictiveLoad
  module Rails5AssociationOptions
    def valid_options(options)
      super + [:predictive_load]
    end
  end
end

if ActiveRecord::VERSION::MAJOR >= 5
  ActiveRecord::Associations::Builder::Association.singleton_class.prepend(PredictiveLoad::Rails5AssociationOptions)
else
  ActiveRecord::Associations::Builder::Association.valid_options << :predictive_load
end
