namespace :mongo do
  desc "Remove and create MongoDB indexes"
  task indexes: :environment do
    Rake::Task["db:mongoid:remove_indexes"].invoke
    Rake::Task["db:mongoid:create_indexes"].invoke
  end
end