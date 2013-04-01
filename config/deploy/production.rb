set   :current_stage, "production"
set   :rails_env, current_stage
set   :deploy_to, "/home/#{project}/www/#{project}/"
set   :domain, "cloudorgchart.com"
role  :web, domain
role  :app, domain
role  :db, domain, primary: true
set   :branch, "master"
