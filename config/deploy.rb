set :user, "jpbougie"
set :port, 29209

set :application, "birch"
set :repository,  "git@github.com:jpbougie/birch.git"

set :scm, :git
set :branch, "master"

default_run_options[:pty] = true

role :web, "jpbougie.net"                          # Your HTTP server, Apache/etc
role :app, "jpbougie.net"                          # This may be the same as your `Web` server
role :db,  "jpbougie.net", :primary => true # This is where Rails migrations will run

set :deploy_to, "/data/#{application}"

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

# namespace :deploy do
#   task :start {}
#   task :stop {}
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end

namespace :deploy do
  task :start do
    run "cd #{current_path} && #{try_sudo} unicorn -c #{current_path}/config/unicorn.rb -E production -D #{current_path}/config.ru"
  end
  
  task :stop do
    run "#{try_sudo} kill -s QUIT `cat #{current_path}/tmp/pids/unicorn.pid`"
  end
  
  task :restart do
    run "#{try_sudo} kill -s HUP `cat #{current_path}/tmp/pids/unicorn.pid`"
  end
  
  task :link_sockets do
    run "ln -s #{shared_path}/sockets #{current_path}/tmp/sockets"
  end
  
  after "deploy:update", "deploy:link_sockets"
end