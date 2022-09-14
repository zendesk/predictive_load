module PredictiveLoad

end

if ActiveRecord::VERSION::MAJOR >= 5
  ActiveRecord::Associations::Builder::Association::VALID_OPTIONS << :predictive_load
else
  ActiveRecord::Associations::Builder::Association.valid_options << :predictive_load
end
