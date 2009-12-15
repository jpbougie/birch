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
    
    def project_url(project, append=nil, iteration=nil)
      array = ["", project.user.username, project.slug]
      array << "iteration-#{iteration.order}" if iteration
      array << append if append
      array.join("/")
    end
    
    def alternative_url(alternative, project=nil, iteration=nil, permalink=false)
      # params can be passed so we don't have to recalculate them
      iteration ||= alternative.iteration
      project_url(project || alternative.iteration.project, alternative.id, (!iteration.current? || permalink) ? iteration : nil)
    end
    
    def distance_of_time(from, to=nil)
      to ||= Time.now
      delta = to.to_i - from.to_i
      
      case delta
        when 0..60    then "less than a minute"
        when 60..119  then "a minute"
        when 61..3599 then "#{delta / 1.minute} minutes"
        else case (delta / 1.hour)
          when 1 then "an hour"
          when 2..23 then "#{delta / 1.hour} hours"
          else case (delta / 1.day)
            when 1 then "a day"
            when 2..7 then "#{delta / 1.day} days"
            else case (delta / 7.days)
              when 1 then "a week"
              when 2..4 then "#{delta / 7.days} weeks"
              else case (delta / 1.month)
                when 1 then "a month"
                else "#{delta / 1.month} months"
              end
            end
          end
        end
      end
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
        p = ::Project.find(params[:project][:id])
        p.user = current_user
        p.name = params[:project][:name]
        p.description = params[:project][:description]
        p.temp = false
        p.save
                
        Dam::Stream["project/#{p.id}"].instantiate!

        redirect project_url(p)
      end


      # this route can be called in 3 different situation:
      # - a new project, in which case no param is given
      #   in this case, we create a new project and a new iteration
      # - adding files to an existing iteration, which will always be the latest
      #   the project id is given, but no iteration id
      # - a new iteration on an existing project, in which case a pending iteration id is given
      #   both the project id and pending iteration id are given
      app.post '/upload' do

        content_type :json

        project = if params[:project] then
          ::Project.find(params[:project])
        else
          ::Project.create :name => Time.now.strftime("Untitled %x %X"), :temp => true
        end

        project.save

        iteration = if params[:iteration] then
          PendingIteration.find(params[:iteration])
        else
          project.iterations.first(:order => "created_at desc") || project.iterations.create(:order => 1)
        end

        alternative = Alternative.create :name => params[:"asset.name"], :filename => params[:"asset.name"], :iteration_id => iteration.id

        alternative.asset = File.new(params[:"asset.path"])
        alternative.save!
        
        Dam::Stream["alternative/#{alternative.id}"].instantiate!

        {:project_id => project.id, :alternative_id => alternative.id}.to_json

      end
      
      app.get "/:user/:project/iterate" do
        login_required

        @project = get_project_or_404(params[:user], params[:project])

        #only the owner can start another iteration
        halt(403) unless current_user == @project.user
        
        @iteration = PendingIteration.create :project => @project
        
        haml :iterate
      end
      
      app.post "/:user/:project/iterate" do
        login_required

        @project = get_project_or_404(params[:user], params[:project])

        #only the owner can start another iteration
        halt(403) unless current_user == @project.user
        
        @iteration = PendingIteration.find params[:iteration][:id]
        
        iteration = @iteration.activate!
        
        Dam::Stream["iteration/#{iteration.id}"].instantiate!
        
        redirect project_url(@project)
      end
      
      app.get "/:user/:project/iterations" do
        login_required
        @project = get_project_or_404(params[:user], params[:project])

        halt(403) unless authorized_for_project? current_user, @project
        
        haml :iterations
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

          haml :project, :locals => {:bodyid => "project-section"}
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
          
          comment = Comment.new(:user => current_user, :body => params[:body], :created_at => Time.now)
          
          @iteration.comments << comment
          @iteration.save
          
          Dam.post(:comment_posted, :comment => comment, :project => @project)
          
          redirect project_url(@project)
          
        end
      end
      
      
      get "/:user/:project/invite" do
        login_required
        @project = get_project_or_404(params[:user], params[:project])
        halt(403) unless authorized_for_project? current_user, @project
        
        haml :invite
      end
      
      post "/:user/:project/invite" do
        login_required
        @project = get_project_or_404(params[:user], params[:project])
        halt(403) unless authorized_for_project? current_user, @project
        
        Invitation.import(@project, params[:body])
        
        redirect project_url(@project)
      end
      
      get "/invite/:secret" do
        @invitation = Invitation.first(:conditions => {:secret => params[:secret]})
        
        if @invitation
          # if the e-mail is already attached to an account, use that one
          # otherwise, show the login form
          if @user = User.find_by_email(@invitation.email)
            # add the user to the project
            p = @invitation.project
            p.collaborators << @user
            p.save!
            
            if @user == current_user
              redirect project_url(p)
            else
              redirect "/login?next=" + project_url(p)
            end
          else
            # signup and come back to this page
            redirect "/signup?email=#{@invitation.email}&next=/invite/#{params[:secret]}"
          end
        else
          halt 404
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
          
          @activities = Dam::Stream["alternative/#{@alternative.id}"].all

          haml :alternative, :locals => {:bodyid => "alternative-section"}
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
          
          comment = Comment.new(:user => current_user, :body => params[:body], :created_at => Time.now)
          
          @alternative.comments << comment
          @alternative.save
          
          Dam.post(:comment_posted, :comment => comment, :project => @project)
          
          redirect alternative_url(@alternative, project=@project, iteration=@iteration)
        end
        
        app.post [path, 'like'].join("/") do
          @project = get_project_or_404(params[:user], params[:project])
          halt(403) unless authorized_for_project? current_user, @project

          @iteration = unless params[:iteration].nil?
            @project.iterations.first(:conditions => {:order => params[:iteration].to_i })
          else
            @project.iterations.first(:order => "created_at desc")
          end

          @alternative = @iteration.alternatives.find(params[:alternative])
          not_found("Alternative could not be found") if @alternative.nil?
          
          unless @alternative.likes.include? current_user.id
            @alternative.likes << current_user.id
            @alternative.save
            Dam.post(:alternative_liked, :user => current_user, :alternative => @alternative, :created_at => Time.now)
          end
          
          redirect alternative_url(@alternative, project=@project, iteration=@iteration)
        end
        
        app.get [path, 'annotations'].join("/") do
          @project = get_project_or_404(params[:user], params[:project])
          halt(403) unless authorized_for_project? current_user, @project

          @iteration = unless params[:iteration].nil?
            @project.iterations.first(:conditions => {:order => params[:iteration].to_i })
          else
            @project.iterations.first(:order => "created_at desc")
          end

          @alternative = @iteration.alternatives.find(params[:alternative])
          not_found("Alternative could not be found") if @alternative.nil?
          
          content_type :json
          @alternative.annotations.to_json
        end
        
        app.post [path, 'annotations'].join("/") do
          @project = get_project_or_404(params[:user], params[:project])
          halt(403) unless authorized_for_project? current_user, @project

          @iteration = unless params[:iteration].nil?
            @project.iterations.first(:conditions => {:order => params[:iteration].to_i })
          else
            @project.iterations.first(:order => "created_at desc")
          end

          @alternative = @iteration.alternatives.find(params[:alternative])
          not_found("Alternative could not be found") if @alternative.nil?
          
          elements = Yajl::Parser.parse(request.body)
          puts elements.inspect
          elements.collect! {|elem| elem["_type"].constantize.new(elem)}
          
          annotation = Annotation.new(:user => current_user, :elements => elements)
          
          @alternative.annotations << annotation
          @alternative.save
          
          Dam.post(:annotation_created, :annotation => annotation)
          
          redirect alternative_url(@alternative, project=@project, iteration=@iteration) 
        end
        
        app.get [path, 'annotations', ':annotation'].join("/") do
          @project = get_project_or_404(params[:user], params[:project])
          halt(403) unless authorized_for_project? current_user, @project

          @iteration = unless params[:iteration].nil?
            @project.iterations.first(:conditions => {:order => params[:iteration].to_i })
          else
            @project.iterations.first(:order => "created_at desc")
          end

          @alternative = @iteration.alternatives.find(params[:alternative])
          not_found("Alternative could not be found") if @alternative.nil?
          
          content_type :json
          @alternative.annotations.find(params[:annotation]).to_json
        end
      end
    end
  end
  helpers ProjectHelpers
  register Project
end

