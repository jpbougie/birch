require 'rubygems'

require 'sinatra'

gem 'haml-edge'
require 'haml'

gem 'chriseppstein-compass'
require 'compass'

gem 'jnunemaker-mongomapper'
require 'mongomapper'

$: << File.join(File.dirname(__FILE__), 'lib')

configure do
  MongoMapper.connection = XGen::Mongo::Driver::Mongo.new('localhost')
  MongoMapper.database = "dev"
  
  Compass.configuration do |config|
    config.project_path = File.dirname(__FILE__)
    config.sass_dir     = File.join('views', 'stylesheets')
  end
end

enable :sessions

require 'birch/models'

get "/stylesheets/:name.css" do |name|
  content_type 'text/css'

  # Use views/stylesheets & blueprint's stylesheet dirs in the Sass load path
  sass :"stylesheets/#{name}", Compass.sass_engine_options
end

get '/' do
  if session[:user]
    @user = User.find(session[:user])
    haml :logged_index
  else
    haml :default_index
  end
end

get '/signup' do
  haml :sign_up
end

post '/signup' do
  @user = User.new params[:user]
    
  if @user.save
    session[:user] = @user.id
    redirect "/"
  else
    haml :sign_up
  end
end

get '/login' do
  haml :login
end

post '/login' do
  @user = User.authenticate(params[:email], params[:password])
  if @user
    session[:user] = @user.id
    redirect(params[:next] || '/')
  else
    haml :login
  end
end

get '/create' do
  haml :create
end

post '/create' do
  
end

post '/upload' do
  params.to_s
end

post '/upload_completed' do
  params.to_s
end