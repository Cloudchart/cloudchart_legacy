class ConvertUserIdToAccesses < Mongoid::Migration
  def self.up
    Chart.all.each do |chart|
      user_id = chart.try(:user_id) rescue nil
      if user_id
        User.find(user_id).access!(chart, :owner!)
        say "##{chart.id}: #{user_id} is owner"
      else
        say "##{chart.id}: already has owner"
      end
    end
    
    Chart.all.unset :user_id
  end
  
  def self.down
  end
end