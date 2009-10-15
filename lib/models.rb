class User
  include MongoMapper::Document

  key :name, String, :required => true, :unique => true
  key :username, String, :required => true, :unique => true
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
  key :slug, String, :unique => true
  
  before_validation :update_slug
  
  belongs_to :user
  many :iterations
  
  timestamps!
  
  private
  
  def update_slug
    write_attribute('slug', self.name.downcase.gsub(/[\W\/]/, '-'))
  end
end

class Iteration
  include MongoMapper::Document
  
  key :project_id, String
  key :order, Integer
  
  timestamps!
  
  validates_uniqueness_of :order, :scope => :project_id
  belongs_to :project
  many :alternatives
  
  before_save :set_order
  
  def set_order
    if new?
      write_attribute('order', self.project.iterations.count + 1)
    end
  end
end

class Alternative
  include MongoMapper::Document
  
  key :name, String
  key :filename, String
  key :description, String
  key :iteration_id, String
  
  mount_uploader :asset, AssetUploader
  
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