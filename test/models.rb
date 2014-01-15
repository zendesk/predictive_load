class User < ActiveRecord::Base
  has_many :comments,  :dependent => :destroy
  has_many :topics,    :through => :comments
  has_one  :photo
  has_and_belongs_to_many :emails

  def full_name
    name
  end

end

class Email < ActiveRecord::Base
end

class Topic < ActiveRecord::Base
  has_many :comments, :dependent => :destroy
end

class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :user_by_proc, :class_name => "User", :foreign_key => :user_id,
                            :conditions => proc { "1 = #{one}" }
  belongs_to :topic

  scope :by_topic, lambda { |topic| where(:topic_id => topic.id) }
  scope :recent, order('updated_at desc')

  def one
    1
  end
end

class Photo < ActiveRecord::Base
  belongs_to :user
end
