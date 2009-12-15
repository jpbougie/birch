require 'sinatra/base'

module Sinatra
  module UserManagement
    def self.registered(app)
      app.get '/signup' do
        haml :sign_up
      end

      app.post '/signup' do
        @user = User.new params[:user]

        if @user.save
          Dam::Stream["user/#{@user.id}"].instantiate!
          login(@user)
          redirect(params[:next] || "/")
        else
          haml :sign_up
        end
      end

      app.get '/login' do
        haml :login
      end

      app.post '/login'  do
        user = authenticate(params[:username], params[:password])
        if user
          login(user)
          redirect(params[:next] || '/')
        else
          haml :login
        end
      end

      app.get '/logout' do
        logout
        redirect '/'
      end
  
    end
  end
  
  register UserManagement
end