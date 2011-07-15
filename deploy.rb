require "./config/boot"
require "hoptoad_notifier/capistrano"
# require "delayed/recipes"

set :application, "APP_NAME"
set :repository,  "GIT URL"
set :scm,         :git

set :use_sudo,    false

# tell git to clone only the latest revision and not the whole repository
set :git_shallow_clone, 1
set :keep_releases,     5

set :user,      "APP_NAME"
set :deploy_to, "/var/www/APP_NAME"
set :runner,    "APP_NAME"

set :rails_env, "production" #added for delayed job

# options necessary to make Ubuntu's SSH happy
ssh_options[:paranoid]      = false
ssh_options[:forward_agent] = true
default_run_options[:pty]   = true

role :app, "SERVER_IP_ADDRESS"                    # Your HTTP server, Apache/etc
role :web, "SERVER_IP_ADDRESS"                    # This may be the same as your `Web` server
role :db,  "SERVER_IP_ADDRESS", :primary => true  # This is where Rails migrations will run

# TASKS
task :create_database, :roles => :app do
  run "cd #{release_path} && rake db:create"
end

task :install_gems, :roles => :app do
  run "cd #{release_path} && bundle install --without development test"
end

task :link_assets_folder, :roles => :app do
  run "ln -s #{shared_path}/assets/ #{release_path}/public/"
end

task :seed, :roles => :app do
  run "cd #{release_path} && rake db:seed"
end

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts
namespace :deploy do
  desc "Starts unicorn directly"
  task :start, :roles => :app do
    run "unicorn_rails -c #{current_release}/config/unicorn.rb -E production -D"
  end

  desc "Stops unicorn directly"
  task :stop, :roles => :app do
    run "kill -QUIT `cat #{shared_path}/pids/unicorn.pid`"
  end

  desc "Restarts unicorn directly"
  task :restart, :roles => :app do
    run "kill -USR2 `cat #{shared_path}/pids/unicorn.pid`"
  end
end

after "deploy:update_code", "deploy:cleanup"
after "deploy:update_code", :install_gems
after "deploy:update_code", :link_assets_folder
after "deploy:update_code", :seed

# before "deploy:restart", "delayed_job:stop"
# after  "deploy:restart", "delayed_job:start"
# after "deploy:stop",  "delayed_job:stop"
# after "deploy:start", "delayed_job:start"

