class User < ActiveRecord::Base
  has_many :comments,  :dependent => :destroy
  has_many :topics,    :through => :comments
  has_one  :photo
  has_and_belongs_to_many :emails
end

class Email < ActiveRecord::Base
end

class Topic < ActiveRecord::Base
  has_many :comments, :dependent => :destroy
end

class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :topic
end

class Photo < ActiveRecord::Base
  belongs_to :user
end
