require 'sinatra/base'

module Sinatra
  module Project
    def self.registered(app)
      app.get '/create' do
        login_required
        haml :create
      end

      app.post '/create' do
        login_required
        p = Project.find(params[:project][:id])
        p.user = current_user
        p.name = params[:project][:name]
        p.description = params[:project][:description]
        p.temp = false
        p.save

        redirect "/#{current_user.username}/#{p.slug}"
      end

      app.post '/upload' do

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
        app.get path do
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

        app.get path do
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
    end
  end
  register Project
end

