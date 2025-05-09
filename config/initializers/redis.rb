# config/initializers/redis.rb

# Redis configuration
REDIS_CONFIG = {
  host: ENV['REDIS_HOST'] || 'localhost',
  port: ENV['REDIS_PORT'] || '6379',
  db: ENV['REDIS_DB'] || '0',
  namespace: "mailing_database_app:#{Rails.env}"
}

# Create a Redis connection
$redis = Redis::Namespace.new(REDIS_CONFIG[:namespace], redis: Redis.new(
  host: REDIS_CONFIG[:host],
  port: REDIS_CONFIG[:port],
  db: REDIS_CONFIG[:db]
))

# Test the connection
begin
  $redis.ping
  puts "Redis connection successful" if Rails.env.development?
rescue Redis::CannotConnectError
  puts "Failed to connect to Redis at #{REDIS_CONFIG[:host]}:#{REDIS_CONFIG[:port]}"
end
