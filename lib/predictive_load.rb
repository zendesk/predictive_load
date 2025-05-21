module PredictiveLoad
  module Rails5AssociationOptions
    def valid_options(options)
      super + [:predictive_load]
    end
  end

  class << self
    attr_reader :callback

    # Configure a callback to be invoked when the library preloads some association.
    #
    # It must be a callable with an arity of two.
    # The callback receives two arguments:
    # - The record (instance) on which the queries that triggered automatic preloading
    #   are being performed, in the form of some association call.
    # - The association object, which can be inspected to check the type and name of
    #   the association.
    #
    def callback=(c)
      if c.nil? || (c.respond_to?(:call) && c.respond_to?(:arity) && c.arity == 2)
        @callback = c
      else
        raise ArgumentError, "wrong callback type, it must be a callable that supports 2 arguments"
      end
    end
  end
end

ActiveRecord::Associations::Builder::Association.singleton_class.prepend(PredictiveLoad::Rails5AssociationOptions)
