require "bundler/capistrano"

default_run_options[:pty] = true # Must be set for the password prompt from git to work

set :application, "6m2"

# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
set :scm, :git
set :repository,  "https://github.com/decode/6m2.git"
set :branch, "master"
set :deploy_via, :remote_cache

role :web, "my-site"                          # Your HTTP server, Apache/etc
role :app, "my-site"                          # This may be the same as your `Web` server
role :db,  "my-site", :primary => true # This is where Rails migrations will run

set :deploy_to, "/var/www/my-site/"
set :user, "user"
set :use_sudo, true
# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    #run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

