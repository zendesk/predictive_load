module PredictiveLoad
end

ActiveRecord::Associations::Builder::Association.valid_options << :no_preload
