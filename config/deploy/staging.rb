set   :current_stage, "staging"
set   :rails_env, current_stage
set   :deploy_to, "/home/#{project}/www/#{project}-dev/"
set   :domain, "dev.cloudorgchart.com"
role  :web, domain
role  :app, domain
role  :db, domain, primary: true
role  :sidekiq, domain
set   :branch, "staging"
