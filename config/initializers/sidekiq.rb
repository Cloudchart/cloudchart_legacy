# Sidekiq configuration
require "kiqstand"
require "redis/namespace"
yaml = YAML.load(File.read(File.join(Rails.root, "/config/sidekiq.yml")))

Sidekiq.configure_server do |config|
  config.poll_interval = 5
  config.server_middleware do |chain|
    chain.add Kiqstand::Middleware
  end
  config.redis = ConnectionPool.new(size: yaml[:redis][:server_size], timeout: 1) {
    Redis::Namespace.new(yaml[:redis][:namespace], redis: Redis.connect(url: yaml[:redis][:url], timeout: 10))
  }
end

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: yaml[:redis][:client_size], timeout: 1) {
    Redis::Namespace.new(yaml[:redis][:namespace], redis: Redis.connect(url: yaml[:redis][:url], timeout: 10))
  }
end
