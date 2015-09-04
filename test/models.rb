class User < ActiveRecord::Base
  has_many :comments,  :dependent => :destroy
  has_many :topics,    :through => :comments
  has_many :attachments, as: :source
  has_one  :photo
  has_and_belongs_to_many :emails

  def full_name
    name
  end
end

class Email < ActiveRecord::Base
end

class EmailsUser < ActiveRecord::Base
end

class Topic < ActiveRecord::Base
  has_many :comments, :dependent => :destroy
end

class Comment < ActiveRecord::Base
  default_scope { where(public: true) }
  belongs_to :user

  unless ActiveRecord::VERSION::STRING > "4.1.0"
    ActiveSupport::Deprecation.silence do
      belongs_to :user_by_proc, :class_name => "User", :foreign_key => :user_id,
        :conditions => proc { |object| "1 = #{ActiveRecord::VERSION::MAJOR == 3 ? one : object.one}" }
    end
  end

  if ActiveRecord::VERSION::MAJOR > 3
    belongs_to :user_by_proc_v2,
      proc { |object| where("1 = #{ActiveRecord::VERSION::MAJOR == 3 ? one : object.one}") }, :class_name => "User", :foreign_key => :user_id

    belongs_to :user_by_proc_v2_no_args,
      proc { where("1 = 1") }, :class_name => "User", :foreign_key => :user_id
  end

  belongs_to :user_no_preload,
    :class_name => "User", :foreign_key => :user_id, :predictive_load => false

  belongs_to :topic

  scope :by_topic, lambda { |topic| where(:topic_id => topic.id) }
  ActiveSupport::Deprecation.silence do
    scope :recent, order('updated_at desc')
  end
  scope :recent_v2, lambda { order('updated_at desc') }

  def one
    1
  end
end

class Photo < ActiveRecord::Base
  belongs_to :user
end

class Attachment < ActiveRecord::Base
  belongs_to :source, polymorphic: true
end
