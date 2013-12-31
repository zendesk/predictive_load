require_relative 'helper'
require 'predictive_load/watcher'

describe PredictiveLoad::ActiveRecordCollectionObservation do

  describe "Relation#to_a" do
    before do
      user1 = User.create!(:name => "Rudolph")
      user2 = User.create!(:name => "Santa")
    end

    after do
      User.delete_all
    end

    describe "when a collection observer is specified" do
      before do
        ActiveRecord::Relation.collection_observer = PredictiveLoad::Watcher
      end

      it "observes the members of that collection" do
        users = User.all
        assert_equal 2, users.size
        assert users.all? { |user| user.collection_observer }
      end

    end

    describe "when a collection observer is not specified" do
      before do
        ActiveRecord::Relation.collection_observer = nil
      end

      it "does not observe the members of that collection" do
        users = User.all
        assert_equal 2, users.size, users.inspect
        assert users.none? { |user| user.collection_observer }
      end

    end

  end

end
