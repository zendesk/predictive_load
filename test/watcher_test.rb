require_relative 'helper'

if ActiveRecord::VERSION::STRING >= "4.1.0"
  describe "PredictiveLoad::Watcher" do
    it "does not work" do
      skip "does not work"
    end
  end
else

require 'predictive_load/watcher'
require 'logger'

describe PredictiveLoad::Watcher do

  describe "A collection of records" do
    before do
      ActiveRecord::Relation.collection_observer = PredictiveLoad::Watcher

      topic = Topic.create!(:title => "Sleigh repairs")
      user1 = User.create!(:name => "Rudolph")
      user2 = User.create!(:name => "Santa")
      comment1 = topic.comments.create!(:body => "meow",     :user => user1)
      comment2 = topic.comments.create!(:body => "Ho Ho ho", :user => user2)
    end

    after do
      User.delete_all
      Comment.delete_all
      Topic.delete_all
    end

    it "logs what the loader would have done" do
      users = User.all
      users[0].id = 1
      users[1].id = 2
      message = "predictive_load: detected n1 call on User#comments
predictive_load: expect to prevent 1 queries
predictive_load: would preload with: SELECT \"comments\".* FROM \"comments\"  WHERE \"comments\".\"public\" = 't' AND \"comments\".\"user_id\" IN (1, 2)
predictive_load: 0|0|0|SCAN TABLE comments

predictive_load: 0|0|0|EXECUTE LIST SUBQUERY 1

predictive_load: would have prevented all 1 queries
"
      assert_log(message, /\d+\.\d+ms| \(~10+ rows\)/) do
        users.each { |user| user.comments.to_a }
      end
    end

    it "does not log :through association queries" do
      users = User.all
      message = "predictive_load: detected n1 call on User#topics
predictive_load: expect to prevent 1 queries
predictive_load: encountered :through association for topics. Requires loading records to generate query, so skipping for now.
predictive_load: would have prevented all 1 queries
"

      timing_pattern = /\d+\.\d+ms/
      message.gsub!(timing_pattern, '')
      assert_log(message, timing_pattern) do
        users.each { |user| user.topics.to_a }
      end

    end

    it "does not blow up when preloading associations with proc conditions" do
      log    = StringIO.new
      logger = build_logger(log)
      ActiveRecord::Base.logger = logger

      comments = Comment.all.to_a
      assert_equal 2, comments.size
      assert_queries(2) do
        comments.each do |comment|
          if ActiveRecord::VERSION::STRING < "4.1.0"
            assert comment.user_by_proc.full_name
          else
            assert comment.user_by_proc_v2.full_name
          end
        end
      end
    end
  end

  def assert_log(message, ignore)
    original_logger = ActiveRecord::Base.logger
    log    = StringIO.new
    logger = build_logger(log)
    ActiveSupport::LogSubscriber.colorize_logging = false
    ActiveRecord::Base.logger = logger

    yield

    result = log.string
    result.gsub!(ignore, '')
    message.gsub!(ignore, '')
    assert_equal message, result
  ensure
    ActiveRecord::Base.logger = original_logger
  end

  def build_logger(log)
    Logger.new(log).tap do |logger|
      logger.level     = Logger::Severity::INFO
      logger.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n" }
    end
  end
end

end
