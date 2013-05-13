class ConfirmExistingUsers < Mongoid::Migration
  def self.up
    User.update_all confirmed_at: Time.new
  end
end
