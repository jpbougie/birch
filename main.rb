require 'rubygems'

require 'sinatra'

require 'haml'
require 'sass'

require 'compass'
require 'ninesixty'
require 'baseline'

require 'mongo_mapper'

$: << File.join(File.dirname(__FILE__), 'lib')

require 'carrierwave'
require 'carrierwave/orm/mongomapper'


configure do
  MongoMapper.connection = Mongo::Connection.new('localhost')
  MongoMapper.database = "dev"
  
  Compass.configuration do |config|
    config.project_path = File.dirname(__FILE__)
    config.sass_dir     = File.join('views', 'stylesheets')
  end
end

enable :sessions

require 'upload'
require 'models'
require 'auth'

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

get '/signup' do
  haml :sign_up
end

post '/signup' do
  @user = User.new params[:user]
  
  if @user.save
    login(@user)
    redirect "/"
  else
    haml :sign_up
  end
end

get '/login' do
  haml :login
end

post '/login'  do
  user = authenticate(params[:username], params[:password])
  if user
    login(user)
    redirect(params[:next] || '/')
  else
    haml :login
  end
end

get '/logout' do
  logout
  redirect '/'
end

get '/create' do
  login_required
  haml :create
end

post '/create' do
  login_required
  p = Project.find(params[:project][:id])
  p.user = current_user
  p.name = params[:project][:name]
  p.description = params[:project][:description]
  p.temp = false
  p.save

  redirect "/#{current_user.username}/#{p.slug}"
end

post '/upload' do

  content_type :json

  project = if params[:project] then
    Project.find(params[:project])
  else
    Project.create :name => Time.now.strftime("Untitled %x %X"), :temp => true
  end

  project.save

  iteration = project.iterations.first(:order => "created_at desc") || project.iterations.create(:order => 1)
  iteration.save

  alternative = iteration.alternatives.create :name => params[:"asset.name"], :filename => params[:"asset.name"]

  alternative.asset = File.new(params[:"asset.path"])
  alternative.save!

  {:project_id => project.id, :alternative_id => alternative.id}.to_json

end

# /jpbougie/project-birch/
# /jpbougie/project-birch/a0234a0
# /jpbougie/project-birch/iteration-1/a0234a0

# project view
# an iteration can be given, otherwise the last one will be used
[ "/:user/:project/iteration-:iteration", 
  "/:user/:project"].each do |path|
  get path do
    @user = User.find_by_username params[:user]
    not_found("User does not exist") if @user.nil?
  
    @project = @user.projects.first(:conditions => {:slug => params[:project]})
    not_found("Project could not be found") if @project.nil?
  
    @iteration = unless params[:iteration].nil?
      @project.iterations.first(:conditions => {:order => params[:iteration].to_i })
    else
      @project.iterations.first(:order => "created_at desc")
    end
  
    not_found("Iteration could not be found") if @iteration.nil?

    haml :project
  end
end

# view an alternative
[ "/:user/:project/iteration-:iteration/:alternative",
  "/:user/:project/:alternative" ].each do |path|

  get path do
    @user = User.find_by_username params[:user]
    not_found("User does not exist") if @user.nil?
  
    @project = @user.projects.first(:conditions => {:slug => params[:project]})
    not_found("Project could not be found") if @project.nil?
  
    @iteration = unless params[:iteration].nil?
      @project.iterations.first(:conditions => {:order => params[:iteration].to_i })
    else
      @project.iterations.first(:order => "created_at desc")
    end
  
    @alternative = @iteration.alternatives.find(params[:alternative])
    not_found("Alternative could not be found") if @alternative.nil?
  
    haml :alternative
  end
end