class RemovePersonsFromCharts < Mongoid::Migration
  def self.up
    Chart.all.unset(:persons)
  end
  
  def self.down
  end
end
