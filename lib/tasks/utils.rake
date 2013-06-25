namespace :utils do
  desc "Regenerate charts"
  task regenerate: :environment do
    Chart.all.each { |chart|
      updated_at = chart.updated_at
      chart.to_xdot!
      chart.to_png!
      chart.set(:updated_at, updated_at)
    }
  end
  
  namespace :mongo do
    desc "Remove and create MongoDB indexes"
    task reindex: :environment do
      Rake::Task["db:mongoid:remove_indexes"].invoke
      Rake::Task["db:mongoid:create_indexes"].invoke
    end
  end
  
  namespace :search do
    desc "Remove and create Elasticsearch indexes"
    task reindex: :environment do
      ENV["CLASS"] = "Person"
      ENV["FORCE"] = "true"
      Rake::Task["tire:import:model"].execute
      ENV["CLASS"] = "Vacancy"
      ENV["FORCE"] = "true"
      Rake::Task["tire:import:model"].execute
    end
  end
end
