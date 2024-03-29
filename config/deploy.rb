require "capistrano_colors"
require "rvm/capistrano"
require "sidekiq/capistrano"
default_run_options[:pty] = true

# Application
set   :application, "cloudchart"
set   :project, "cloudchart"

## Stages
set :stages, %w(production staging)
set :default_stage, "staging"
require "capistrano/ext/multistage"

## Assets
set   :assets_role, :app
load "deploy/assets"

## Source
set   :scm, "git"
set   :repository, "git@github.com:Cloudchart/#{project}.git"
set   :repository_cache, "git"
set   :deploy_via, :remote_cache
set   :user, "cloudchart"

## Options
set   :use_sudo, false
set   :rvm_ruby_string, "ruby-2.0.0-p195@cloudchart"
set   :rvm_type, :user
set   :keep_releases, 3
set   :shared_children, shared_children + %w(tmp/sockets)
set   :sidekiq_role, :sidekiq

# Bundler
after "deploy:finalize_update", "bundler:install"
namespace :bundler do
  task :install, roles: :app do
    shared_dir = File.join(shared_path, "bundle")
    release_dir = File.join(current_release, ".bundle")
    run "mkdir -p #{shared_dir}; ln -s #{shared_dir} #{release_dir}" 
    run "cd #{current_release} && RAILS_ENV=#{rails_env} bundle install --without test"
  end
end

# Utils
namespace :mongo do
  desc "Remove and create MongoDB indexes"
  task :indexes, roles: :db do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec rake mongo:indexes"
  end
end

# Deployment
after "deploy:update", "deploy:cleanup"
after "deploy:update", "deploy:migrate"
after "deploy:setup", "deploy:initial"
namespace :deploy do
  # Initial
  task :initial do
    # Install rvm and add mongodb to sources before
    run "#{sudo} apt-get update && sudo apt-get upgrade -y"
    run "#{sudo} apt-get install git-core build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion pkg-config -y"
    run "#{sudo} apt-get install imagemagick libmagick9-dev libpq-dev sendmail -y"
    run "#{sudo} apt-get install nginx mongodb-10gen redis-server -y"
    run "#{sudo} apt-get install graphviz -y"
    run "#{sudo} ln -s #{current_path}/config/nginx.conf /etc/nginx/sites-enabled/cloudchart.conf"
  end

  # Restart
  task :start, roles: :web do 
    run "cd #{current_path} && bundle exec unicorn_rails -c #{current_path}/config/unicorn/#{rails_env}.rb -E #{rails_env} -D"
  end
  task :stop, roles: :web do 
    run "kill -s QUIT `cat #{current_path}/tmp/pids/unicorn.pid`; true"
  end
  task :reload, roles: :web do
    run "kill -s USR2 `cat #{current_path}/tmp/pids/unicorn.pid`; true"
  end
  task :restart, roles: :web do
    reload
  end
end
