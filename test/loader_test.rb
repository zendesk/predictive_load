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
      topic.comments.create!(:body => "meow",     :user => user1)
      topic.comments.create!(:body => "Ho Ho ho", :user => user2)
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
        comments = Comment.all.to_a
        assert_equal 2, comments.size
        assert_queries(1) do
          comments.each { |comment| assert comment.user.name }
        end
      end

      it "preloads when first record association is nil already loaded" do
        user = User.create!(:name => "Santa is dead")
        Topic.first.comments.create!(:body => "cri cri", :user => user)

        comment = Comment.first
        comment.update_attributes!(user_id: nil)

        refute comment.reload.user
        assert comment.association(:user).loaded?

        comments = Comment.all.to_a
        assert_equal 3, comments.size
        assert_queries(1) do
          comments.each { |comment| comment.user }
        end
      end

      it "preloads when first record association is nil and not already loaded" do
        user = User.create!(:name => "Santa is dead")
        Topic.first.comments.create!(:body => "cri cri", :user => user)

        comment = Comment.first
        comment.update_attributes!(user_id: nil)

        comment.reload
        refute comment.association(:user).loaded?

        comments = Comment.all.to_a
        assert_equal 3, comments.size
        assert_queries(1) do
          comments.each { |comment| comment.user }
        end
      end

      it "preloads with static conditions" do
        skip "Unsupported syntax"
        comments = Comment.all.to_a
        assert_equal 2, comments.size
        assert_queries(1) do
          comments.each { |comment| assert comment.user_with_static_conditions.name }
        end
      end

      it "does not attempt to preload associations with proc conditions" do
        skip "Unsupported syntax"
        comments = Comment.all.to_a
        assert_equal 2, comments.size
        assert_queries(2) do
          comments.each { |comment| assert comment.user_by_proc.full_name }
        end
      end

      it "does not attempt to preload associations with proc that has arguments / uses instance" do
        comments = Comment.all.to_a
        assert_equal 2, comments.size
        assert_queries(2) do
          comments.each { |comment| assert comment.user_by_proc_v2.full_name }
        end
      end

      it "does attempt to preload associations with proc that have no arguments / does not use instance" do
        comments = Comment.all.to_a
        assert_equal 2, comments.size
        assert_queries(1) do
          comments.each { |comment| assert comment.user_by_proc_v2_no_args.full_name }
        end
      end

      it "does not attempt to preload associations with predictive_load: false" do
        comments = Comment.all.to_a
        assert_equal 2, comments.size
        assert_queries(2) do
          comments.each { |comment| assert comment.user_no_preload.full_name }
        end
      end
    end

    describe "has_one" do
      it "automatically preloads" do
        users = User.all.to_a
        assert_equal 2, users.size

        assert_queries(1) do
          users.each { |user| user.photo }
        end
      end
    end

    describe "has_many :through" do
      it "automatically preloads" do
        users = User.all.to_a
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
        User.create!(name: 'ddd')
        users = User.all.to_a
        assert_equal 3, users.size
        users.each { |user| EmailsUser.create!(user_id: user.id, email_id: Email.create!.id) }

        assert_queries(2) do
          users.each { |user| user.emails.to_a }
        end
      end
    end

    describe "has_many" do
      it "automatically prelaods" do
        users = User.all.to_a
        assert_equal 2, users.size
        assert_queries(1) do
          users.each { |user| user.comments.to_a }
        end
      end

      it "preloads #length" do
        users = User.all.to_a
        assert_equal 2, users.size
        assert_queries(1) do
          users.each { |user| user.comments.length }
        end
      end

      it "preloads #present?" do
        users = User.all.to_a
        assert_equal 2, users.size
        assert_queries(1) do
          users.each { |user| user.comments.present? }
        end
      end

      it "preloads polymorphic" do
        users = User.all.to_a

        if ActiveRecord::VERSION::MAJOR >= 5
          # Rails 5 produces this query:
          # (SELECT * FROM sqlite_master UNION ALL
          # SELECT * FROM sqlite_temp_master)
          # WHERE type='table' and name='attachments' ;
          Attachment.count
        end

        assert_equal 2, users.size
        assert_queries(1) do
          users.each { |user| user.attachments.present? }
        end
      end

      describe "with comments outside of default scope" do
        before do
          # users each have a public and private comment, the private comment is excluded by the default scope
          @users = User.all.to_a
          assert_equal 2, @users.size
          @users.each { |u| Comment.create!(user: u, public: false, topic: Topic.first, body: "xx") }
        end

        it "preloads correctly when unscoped for eager loaded class" do
          # when eager loading inside of unscoped the private comment should show up
          Comment.unscoped do
            assert_queries(2) do
              @users.each { |user| _(user.comments.to_a.map(&:public).uniq).must_equal [true, false] }
            end
          end
        end

        it "preloads correctly when unscoped for a different class" do
          User.unscoped do
            assert_queries(1) do
              @users.each { |user| _(user.comments.to_a.map(&:public).uniq).must_equal [true] }
            end
          end
        end
      end

      describe "unsupported behavior" do
        it "does not preload when dynamically scoped" do
          users = User.all.to_a
          topic = Topic.first
          assert_queries(2) do
            users.each { |user| user.comments.by_topic(topic).to_a }
          end
        end

        it "does not preload when staticly scoped" do
          skip "this only caches on rails 4.0 ... and is removed in rails 4.1+"
          users = User.all.to_a
          assert_queries(2) do
            users.each { |user| user.comments.recent.to_a }
          end
        end

        it "does not preload when block scoped" do
          users = User.all.to_a
          assert_queries(2) do
            users.each { |user| user.comments.recent_v2.to_a }
          end
        end

        it "does not preload #size" do
          users = User.all.to_a
          assert_queries(2) do
            users.each { |user| user.comments.size }
          end
        end

        it "does not preload first/last" do
          users = User.all.to_a
          assert_queries(2) do
            users.each { |user| user.comments.first }
          end
        end
      end
    end
  end
end
