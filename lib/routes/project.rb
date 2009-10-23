require 'sinatra/base'

module Sinatra
  
  module ProjectHelpers
    def get_project_or_404(username, project_slug)
      user = User.find_by_username(username)
      not_found("User does not exist") if user.nil?
      
      project = user.projects.first(:conditions => {:slug => params[:project]})
      not_found("Project could not be found for user") if project.nil?
      
      project
    end
    
    def authorized_for_project?(user, project)
      (project.user == user) || (project.collaborators.include? user)
    end
  end
  
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
          login_required
          @project = get_project_or_404(params[:user], params[:project])

          halt(403) unless authorized_for_project? current_user, @project

          @iteration = unless params[:iteration].nil?
            @project.iterations.first(:conditions => {:order => params[:iteration].to_i })
          else
            @project.iterations.first(:order => "created_at desc")
          end

          not_found("Iteration could not be found") if @iteration.nil?

          haml :project
        end
      end
      
      # post a comment
      [ "/:user/:project/iteration-:iteration/comment",
        "/:user/:project/comment" ].each do |path|
        post path do
          login_required
          @project = get_project_or_404(params[:user], params[:project])
          halt(403) unless authorized_for_project? current_user, @project
          
          @iteration = unless params[:iteration].nil?
            @project.iterations.first(:conditions => {:order => params[:iteration].to_i })
          else
            @project.iterations.first(:order => "created_at desc")
          end
          
          @iteration.comments << Comment.new(:user => current_user, :body => params[:body], :created_at => Time.now)
          @iteration.save
          
          redirect "/#{params[:user]}/#{params[:project]}"
          
        end
      end

      # view an alternative
      [ "/:user/:project/iteration-:iteration/:alternative",
        "/:user/:project/:alternative" ].each do |path|

        app.get path do
          login_required
          @project = get_project_or_404(params[:user], params[:project])
          halt(403) unless authorized_for_project? current_user, @project

          @iteration = unless params[:iteration].nil?
            @project.iterations.first(:conditions => {:order => params[:iteration].to_i })
          else
            @project.iterations.first(:order => "created_at desc")
          end

          @alternative = @iteration.alternatives.find(params[:alternative])
          not_found("Alternative could not be found") if @alternative.nil?

          haml :alternative
        end
        
        app.post [path, 'comment'].join("/") do
          @project = get_project_or_404(params[:user], params[:project])
          halt(403) unless authorized_for_project? current_user, @project

          @iteration = unless params[:iteration].nil?
            @project.iterations.first(:conditions => {:order => params[:iteration].to_i })
          else
            @project.iterations.first(:order => "created_at desc")
          end

          @alternative = @iteration.alternatives.find(params[:alternative])
          not_found("Alternative could not be found") if @alternative.nil?
          
          @alternative.comments << Comment.new(:user => current_user, :body => params[:body], :created_at => Time.now)
          @alternative.save
          
          redirect "/#{@project.user.username}/#{@project.slug}/#{@alternative.id}"
        end
      end
      
      post "/:user/:project/invite" do
        @project = get_project_or_404(params[:user], params[:project])
      end
    end
  end
  helpers ProjectHelpers
  register Project
end

