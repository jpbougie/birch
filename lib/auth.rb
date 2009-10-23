require 'sinatra/base'

helpers do
  def current_user
    User.find(session[:user]) if session[:user]
  end

  def signed_in?
    !!session[:user]
  end

  def authenticate(username, password)
    user = User.find_by_username username
    return user if user and user.hashed_password == User.encrypt(password, user.salt)
  end

  def login(user)
    session[:user] = user.id
  end

  def logout
    session[:user] = nil
  end

  def login_required
    redirect "/login" unless signed_in?
  end
end