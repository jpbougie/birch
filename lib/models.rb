class User
  include MongoMapper::Document

  key :name, String, :required => true, :unique => true
  key :email, String, :required => true, :unique => true
  key :hashed_password, String, :required => true
  key :salt, String
  key :active, Boolean
  
  timestamps!
  
  def password=(pass)
    self.salt ||= User.random_salt
    self.hashed_password = User.encrypt(pass, self.salt)
  end
  
  def self.encrypt(pass, salt)
    Digest::SHA1.hexdigest([pass,salt].join("-"))
  end
  
  def self.authenticate(email, pass)
    user = User.find_by_email email
    return user if user and user.hashed_password == User.encrypt(pass, user.salt)
  end
  
  def self.random_salt
    allowed_characters = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + %w(= - /)
    (0..15).map {|x| allowed_characters[rand(allowed_characters.size)]}
  end
  
  many :projects
  
end

class Tag
  include MongoMapper::EmbeddedDocument
  
  key :tag, String
end

class Comment
  include MongoMapper::Document
  
  key :body, String, :required => true
  key :user_id, String
  
  timestamps!
  
  belongs_to :user
end

class Crop
  include MongoMapper::EmbeddedDocument
  
  key :top, Integer
  key :left, Integer
  key :width, Integer
  key :height, Integer
end


class Project
  include MongoMapper::Document

  key :name, :required => true
  key :description, String
  key :temp, Boolean
  key :user_id, String
  
  belongs_to :user
  many :iterations
  
  timestamps!
end

class Iteration
  include MongoMapper::Document
  
  key :project_id, String
  
  timestamps!
  
  belongs_to :project
  many :alternatives
end

class Alternative
  include MongoMapper::Document
  
  key :asset, String
  key :name, String
  key :content_type, String
  key :description, String
  key :iteration_id, String
  
  timestamps!
  
  belongs_to :iteration
  many :comments
end

class Event
  include MongoMapper::Document
  
  key :type, String
  key :user_id, String
  
  timestamps!
  
  belongs_to :user
end