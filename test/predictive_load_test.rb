require_relative "helper"
require "predictive_load"

describe PredictiveLoad do
  describe "the callback" do
    after { PredictiveLoad.callback = nil }

    it "can be set to nil" do
      PredictiveLoad.callback = nil
      assert_nil PredictiveLoad.callback
    end

    it "can be set to a callable with two arguments" do
      callable = ->(a, b) { puts "#{a}, #{b}" }
      PredictiveLoad.callback = callable
      assert_equal callable, PredictiveLoad.callback
    end

    it "cannot be set to a non-callable" do
      # Setting a non-callable is an error.
      assert_raises ArgumentError do
        PredictiveLoad.callback = "string"
      end
    end

    it "cannot be set to a callable with the wrong arity" do
      # Setting a callable with the wrong arity is an error.
      assert_raises ArgumentError do
        PredictiveLoad.callback = proc { |a| a }
      end
    end
  end
end
