module PredictiveLoad

end

klasses = [ActiveRecord::Associations::Builder::Association]

if ActiveRecord::VERSION::MAJOR == 3
  # when belongs_to etc is loaded before us it already made a copy of valid_options
  klasses.concat ActiveRecord::Associations::Builder::Association.descendants
end

klasses.each do |klass|
  if ActiveRecord::VERSION::MAJOR < 5
    klass.valid_options << :predictive_load
  else
    klass::VALID_OPTIONS << :predictive_load
  end
end
