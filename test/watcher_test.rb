require_relative 'helper'
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
      message = "predictive_load: detected n1 call on User#comments
predictive_load: expect to prevent 1 queries
predictive_load: would preload with: SELECT \"comments\".* FROM \"comments\"  WHERE \"comments\".\"user_id\" IN (1, 2)
predictive_load: 0|0|0|SCAN TABLE comments (~100000 rows)

predictive_load: 0|0|0|EXECUTE LIST SUBQUERY 1

predictive_load: would have prevented all 1 queries
"
      timing_pattern = /\d+\.\d+ms/
      message.gsub!(timing_pattern, '')
      assert_log(message, timing_pattern) do
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

  end

  def assert_log(message, gsub_pattern)
    original_logger = ActiveRecord::Base.logger
    log    = StringIO.new
    logger = Logger.new(log)
    logger.level = Logger::Severity::INFO
    logger.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n" }
    ActiveSupport::LogSubscriber.colorize_logging = false
    ActiveRecord::Base.logger = logger

    yield
    result = log.string
    result.gsub!(gsub_pattern, '')
    assert_equal message, result
  ensure
    ActiveRecord::Base.logger = original_logger
  end

end
