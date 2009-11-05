set :user, "jpbougie"
set :port, 29209

set :application, "birch"
set :repository,  "git@github.com/jpbougie/birch.git"

set :scm, :git
set :branch, "master"
set :deploy_via, :remote_cache

default_run_options[:pty] = true
ssh_options[:forward_agent] = true


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
    run "#{try_sudo} unicorn -c #{deploy_to}/config/unicorn.rb -E production -D"
  end
  
  task :stop do
    run "#{try_sudo} kill -s QUIT `echo #{deploy_to}/tmp/pids/unicorn.pid`"
  end
  
  task :restart do
    run "#{try_sudo} kill -s HUP `echo #{deploy_to}/tmp/pids/unicorn.pid`"
  end
end