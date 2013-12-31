class User < ActiveRecord::Base
  has_many :comments,        :dependent => :destroy
  has_many :dicussed_topics, :through => :comments, :class_name => 'Topic'
end

class Topic < ActiveRecord::Base
  has_many :comments, :dependent => :destroy
end

class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :topic
end
