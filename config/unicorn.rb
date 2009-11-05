# based on github's unicorn configuration
# unicorn -c /data/birch/current/config/unicorn.rb -E production -D
  
# 16 workers and 1 master
worker_processes 4
 
preload_app true
 
# Restart any workers that haven't responded in 30 seconds
timeout 30
 
# Listen on a Unix data socket
listen '/data/birch/current/tmp/sockets/unicorn.sock', :backlog => 2048
pid '/data/birch/current/tmp/pids/unicorn.pid'
 
##
# REE
 
# http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end
 
APP_ROOT = '/data/birch/current'
 
before_fork do |server, worker|
  ##
  # When sent a USR2, Unicorn will suffix its pidfile with .oldbin and
  # immediately start loading up a new version of itself (loaded with a new
  # version of our app). When this new Unicorn is completely loaded
  # it will begin spawning workers. The first worker spawned will check to
  # see if an .oldbin pidfile exists. If so, this means we've just booted up
  # a new Unicorn and need to tell the old one that it can now die. To do so
  # we send it a QUIT.
  #
  # Using this method we get 0 downtime deploys.
 
  old_pid = APP_ROOT + '/tmp/pids/unicorn.pid.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end
 
 
after_fork do |server, worker|
  ##
  # Unicorn master loads the app then forks off workers - because of the way
  # Unix forking works, we need to make sure we aren't using any of the parent's
  # sockets, e.g. db connection
  MongoMapper.connection = Mongo::Connection.new('localhost')
  
 
  ##
  # Unicorn master is started as root, which is fine, but let's
  # drop the workers to birch:birch
 
  begin
    uid, gid = Process.euid, Process.egid
    user, group = 'birch', 'birch'
    target_uid = Etc.getpwnam(user).uid
    target_gid = Etc.getgrnam(group).gid
    worker.tmp.chown(target_uid, target_gid)
    if uid != target_uid || gid != target_gid
      Process.initgroups(user, target_gid)
      Process::GID.change_privilege(target_gid)
      Process::UID.change_privilege(target_uid)
    end
  rescue => e
      raise e
    end
  end
end