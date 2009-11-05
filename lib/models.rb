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
  
  def gravatar(size=nil)
    "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(self.email)}" + (size ? "?s=#{size}" : "")
  end
  
  many :projects
  
end

class Tag
  include MongoMapper::EmbeddedDocument
  
  key :tag, String
end

class Comment
  include MongoMapper::EmbeddedDocument
  
  key :body, String, :required => true
  key :user_id, String
  key :created_at, Time
  
  many :comments
  
  belongs_to :user
end

class Project
  include MongoMapper::Document

  key :name, :required => true
  key :description, String
  key :temp, Boolean
  key :user_id, String
  key :slug, String, :unique => true
  key :collaborators_ids, Array
  
  before_validation :update_slug
  
  belongs_to :user
  many :iterations
  
  timestamps!
  
  def collaborators
    if self.collaborators_ids.nil?
      []
    else
      User.find(self.collaborators_ids)
    end
  end
  
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
  
  #validates_uniqueness_of :order, :scope => :project_id
  belongs_to :project
  
  many :alternatives
  many :comments
  
  before_save :set_order
  
  def set_order
    if new?
      write_attribute('order', self.project.iterations.count + 1)
    end
  end
  
  def current?
    self.project.iterations.count == self.order
  end
end

class PendingIteration < Iteration
  set_collection_name "pending_iterations"
  
  
  # creates a new iteration with the pending one, moves all the alternatives before deleting itself
  def activate!
    it = Iteration.create(:project => self.project)
    it.save
    
    update_hash = Alternative.all(:conditions => {:iteration_id => self.id}).inject({}) do |hash, alt|
      hash[alt.id] = {:iteration_id => it.id}
      hash
    end
    
    Alternative.update(update_hash)
    
    self.destroy
  end
end

class Alternative
  include MongoMapper::Document
  
  key :name, String
  key :filename, String
  key :description, String
  key :iteration_id, String
  key :likes, Array
  
  mount_uploader :asset, AssetUploader
  
  timestamps!
  
  belongs_to :iteration
  many :comments
  many :annotations
end

class Annotation
  include MongoMapper::EmbeddedDocument
  
  key :user_id, String

  belongs_to :user
  
  many :elements, :polymorphic => true
  
end

class Invitation
  include MongoMapper::Document
  
  key :project_id, String
  key :status, String
  key :secret, String, :unique => true
  key :email, String
  
  timestamps!
  
  belongs_to :project
  
  
  def send_email!
    # Pony.mail(:to => self.email, :from => "do-not-reply@corpcircleapp.com", 
    #           :subject => "An invitation to collaborate on Crop Circle from #{self.project.user.name}",
    #           :body => "http://www.cropcircleapp.com/invite/#{self.secret}")
              
    self.status = "sent"
    self.save
  end
  
  class << self
    def import(project, body)
      # split the e-mails on whitespace
      emails = body.split(/\s/)
      registered_users = User.all(:conditions => { :email => emails })
      
      # add these registered users directly to the project
      project.collaborators_ids ||= []
      project.collaborators_ids << registered_users.collect{|u| u.id }
      project.save
      
      # remove those so we are left with those who don't have an account
      emails_to_invite = emails - registered_users.collect {|user| user.email }
      
      emails_to_invite.each do |email|
        inv = Invitation.create :project => project, :email => email, :status => "created", :secret => Invitation.random_secret
        inv.send_email!
      end
    end
    
    def random_secret
      allowed_characters = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + %w(= - /)
      (0..15).map {|x| allowed_characters[rand(allowed_characters.size)]}
    end
  end
    
end