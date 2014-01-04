require_relative 'helper'
require 'predictive_load/loader'

describe PredictiveLoad::Loader do

  describe "A collection of records" do
    before do
      ActiveRecord::Relation.collection_observer = PredictiveLoad::Loader
      # trigger schema lookup to avoid messing with query count assertions
      Photo.columns

      topic = Topic.create!(:title => "Sleigh repairs")
      user1 = User.create!(:name => "Rudolph")
      user2 = User.create!(:name => "Santa")
      user1.emails.create!
      comment1 = topic.comments.create!(:body => "meow",     :user => user1)
      comment2 = topic.comments.create!(:body => "Ho Ho ho", :user => user2)
    end

    after do
      User.delete_all
      Comment.delete_all
      Topic.delete_all
      Photo.delete_all
      Email.delete_all
    end

    it "supports nested loading" do
      # 3: User, Comment, Topic
      assert_queries(3) do
        User.all.each do |user|
          user.comments.each { |comment| assert comment.topic }
        end
      end
    end

    describe "belongs_to" do

      it "automatically preloads" do
        comments = Comment.all
        assert_equal 2, comments.size
        assert_queries(1) do
          comments.each { |comment| assert comment.user.name }
        end
      end

    end

    describe "has_one" do

      it "automatically preloads" do
        users = User.all
        assert_equal 2, users.size

        assert_queries(1) do
          users.each { |user| user.photo }
        end
      end

    end

    describe "has_many :through" do

      it "automatically preloads" do
        users = User.all
        assert_equal 2, users.size

        assert_queries(3) do
          users.each do |user|
            user.topics.each do |topic|
              topic.comments.to_a
            end
          end
        end

      end
    end

    describe "has_and_belongs_to_many" do

      it "automatically preloads" do
        users = User.all
        assert_equal 2, users.size

        assert_queries(1) do
          users.each { |user| user.emails.to_a }
        end

      end
    end

    describe "has_many" do

      it "automatically prelaods" do
        users = User.all
        assert_equal 2, users.size
        assert_queries(1) do
          users.each { |user| user.comments.to_a }
        end
      end

      it "preloads #length" do
        users = User.all
        assert_equal 2, users.size
        assert_queries(1) do
          users.each { |user| user.comments.length }
        end
      end

      describe "unsupported behavior" do
        it "does not preload when dynamically scoped" do
          users = User.all
          topic = Topic.first
          assert_queries(2) do
            users.each { |user| user.comments.by_topic(topic).to_a }
          end
        end

        it "does not preload when staticly scoped" do
          users = User.all
          topic = Topic.first
          assert_queries(2) do
            users.each { |user| user.comments.recent.to_a }
          end
        end


        it "does not preload #size" do
          users = User.all
          assert_queries(2) do
            users.each { |user| user.comments.size }
          end
        end

        it "does not preload first/last" do
          users = User.all
          assert_queries(2) do
            users.each { |user| user.comments.first }
          end
        end
      end

    end

  end

end
