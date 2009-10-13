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
  MongoMapper.connection = Mongo::Connection.new('localhost')
  MongoMapper.database = "dev"
  
  Compass.configuration do |config|
    config.project_path = File.dirname(__FILE__)
    config.sass_dir     = File.join('views', 'stylesheets')
  end
end

enable :sessions

require 'models'

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
  @user = User.find(session[:user])
  p = Project.find(params[:project])
  p.user = @user
  p.name = params[:name]
  p.description = params[:description]
  p.save
  
  redirect "/projects/#{p.id}"
end

post '/upload' do
  
  content_type :json
  
  #@user = User.find(session[:user])
  project = if params[:project] then
    Project.find(params[:project])
  else
    Project.create :name => "Untitled", :temp => true
  end
  
  iteration = project.iterations.last || project.iterations.create
  
  alternative = iteration.alternatives.create :asset => params[:"asset.path"], :name => params[:"asset.name"]
  
  {:project_id => project.id, :alternative_id => alternative.id}.to_json
  
end