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
end