require_relative "helper"
require "predictive_load/loader"

describe PredictiveLoad::Loader do
  before do
    # Normally run without callback, to verify that its configuration is optional.
    PredictiveLoad.callback = nil
  end

  describe "A collection of records" do
    before do
      ActiveRecord::Relation.collection_observer = PredictiveLoad::Loader
      # trigger schema lookup to avoid messing with query count assertions
      Photo.columns

      topic = Topic.create!(title: "Sleigh repairs")
      user1 = User.create!(name: "Rudolph")
      user2 = User.create!(name: "Santa")
      user1.emails.create!
      topic.comments.create!(body: "meow", user: user1)
      topic.comments.create!(body: "Ho Ho ho", user: user2)
      # anticipate queries to cache foreign_key definitions
      Attachment.create(source_id: 0, source_type: '0').then(&:destroy)
      Photo.create(user_id: 0).then(&:destroy)
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
        user = User.create!(name: "Santa is dead")
        Topic.first.comments.create!(body: "cri cri", user: user)

        comment = Comment.first
        comment.update!(user_id: nil)

        refute comment.reload.user
        assert comment.association(:user).loaded?

        comments = Comment.all.to_a
        assert_equal 3, comments.size
        assert_queries(1) do
          comments.each { |comment| comment.user }
        end
      end

      it "preloads when first record association is nil and not already loaded" do
        user = User.create!(name: "Santa is dead")
        Topic.first.comments.create!(body: "cri cri", user: user)

        comment = Comment.first
        comment.update!(user_id: nil)

        comment.reload
        refute comment.association(:user).loaded?

        comments = Comment.all.to_a
        assert_equal 3, comments.size
        assert_queries(1) do
          comments.each { |comment| comment.user }
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

      describe "the callback, when configured" do
        before do
          @calls = []
          PredictiveLoad.callback = proc do |record, association|
            @calls << [record, association]
          end
        end

        after { PredictiveLoad.callback = nil }

        it "invokes the callback once when it preloads" do
          comments = Comment.all.to_a
          assert_equal 2, comments.size

          assert_empty @calls
          # Preload-triggering query.
          assert_queries(1) do
            comments.each { |comment| assert comment.user.name }
          end

          assert_equal 1, @calls.length
          assert_equal comments[0], @calls[0][0]
          assert_equal comments[0].association(:user), @calls[0][1]
        end

        it "does not invoke the callback when it doesn't preloads" do
          comments = Comment.all.to_a
          assert_equal 2, comments.size

          assert_empty @calls
          # Preload-bypassing query.
          assert_queries(2) do
            comments.each { |comment| assert comment.user_by_proc_v2.full_name }
          end

          assert_empty @calls
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

      describe "the callback, when configured" do
        before do
          @calls = []
          PredictiveLoad.callback = proc do |record, association|
            @calls << [record, association]
          end
        end

        after { PredictiveLoad.callback = nil }

        it "invokes the callback once when it preloads" do
          users = User.all.to_a
          assert_equal 2, users.size

          assert_empty @calls
          # Preload-triggering query.
          assert_queries(1) do
            users.each { |user| user.photo }
          end

          assert_equal 1, @calls.length
          assert_equal users[0], @calls[0][0]
          assert_equal users[0].association(:photo), @calls[0][1]
        end

        it "does not invoke the callback when it doesn't preloads" do
          users = User.all.to_a
          assert_equal 2, users.size

          assert_empty @calls
          # Preload-bypassing query.
          assert_queries(2) do
            users.each { |user| user.photo_no_preload }
          end

          assert_empty @calls
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
        User.create!(name: "ddd")
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

      describe "the callback, when configured" do
        before do
          @calls = []
          PredictiveLoad.callback = proc do |record, association|
            @calls << [record, association]
          end
        end

        after { PredictiveLoad.callback = nil }

        it "invokes the callback once when it preloads" do
          users = User.all.to_a
          assert_equal 2, users.size

          assert_empty @calls
          # Preload-triggering query.
          assert_queries(1) do
            users.each { |user| user.comments.to_a }
          end

          assert_equal 1, @calls.length
          assert_equal users[0], @calls[0][0]
          assert_equal users[0].association(:comments), @calls[0][1]
        end

        it "does not invoke the callback when it doesn't preloads" do
          users = User.all.to_a
          assert_equal 2, users.size

          assert_empty @calls
          # Preload-bypassing query.
          assert_queries(2) do
            users.each { |user| user.comments_no_preload.to_a }
          end

          assert_empty @calls
        end
      end
    end
  end
end
