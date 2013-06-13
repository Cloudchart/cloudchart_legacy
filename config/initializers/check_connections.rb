# Check mongodb connection
exceptions = []

begin
  Mongoid.default_session.collections
rescue => e
  exceptions << "Mongodb fail: #{e.to_s}"
end

begin
  Sidekiq.redis { |conn| conn.get("test") }
rescue => e
  exceptions << "Redis fail: #{e.to_s}"
end

begin
  open(Tire::Configuration.url)
rescue => e
  exceptions << "Elasticsearch fail: #{e.to_s}, host: #{Tire::Configuration.url}"
end

exceptions.each do |msg|
  Rails.logger.fatal msg
end

raise StandardError, "\n#{exceptions.join("\n")}" if exceptions.any?
