require 'rubygems'

require 'sinatra'

require 'haml'
require 'sass'

require 'compass'
require 'ninesixty'
require 'baseline'
#require 'fancybuttons'

require 'mongo_mapper'
require 'yajl'

$: << File.join(File.dirname(__FILE__), 'lib')

require 'carrierwave'
require 'carrierwave/orm/mongomapper'

require 'mail'

require 'dam'

configure do
  MongoMapper.database = "dev"
  MongoMapper.connection = Mongo::Connection.new('localhost')
  
  Compass.configuration do |config|
    config.project_path = File.dirname(__FILE__)
    config.sass_dir     = File.join('views', 'stylesheets')
  end
  
  Dam::Storage.database = Redis.new
  
  Mail.defaults do
    smtp "smtp.gmail.com" do
      enable_tls
      user "cropcircle@jpbougie.net"
      pass "379P83"
    end
  end
end

enable :sessions

require 'upload'
require 'annotations'
require 'models'
require 'auth'
Dir['lib/routes/*.rb'].each {|route| require route}


require 'activities'

class App < Sinatra::Application

  get "/stylesheets/:name.css" do |name|
    content_type 'text/css'

    # Use views/stylesheets & blueprint's stylesheet dirs in the Sass load path
    sass :"stylesheets/#{name}", Compass.sass_engine_options
  end

  get '/' do
    if signed_in?
      haml :logged_index
    else
      haml :default_index
    end
  end
  
  register Sinatra::UserManagement
  register Sinatra::Project
end

