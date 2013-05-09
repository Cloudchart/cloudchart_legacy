class Importer
  include Sidekiq::Worker
  sidekiq_options queue: :importer, unique: :all, expiration: 24*60*60, retry: true, backtrace: true
  
  def perform(id, provider)
    begin
      @user = User.find(id)
    rescue Mongoid::Errors::DocumentNotFound
      return false
    end
    
    @user.import!(provider)
  end
end
