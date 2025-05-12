# config/initializers/redis.rb

require 'redis'
require 'redis-namespace'

begin
  redis_url = ENV['REDIS_URL'] || "redis://#{ENV['REDIS_HOST'] || 'localhost'}:#{ENV['REDIS_PORT'] || 6379}/#{ENV['REDIS_DB'] || 0}"
  redis_client = Redis.new(url: redis_url)

  $redis = Redis::Namespace.new("mailing_database_app:#{Rails.env}", redis: redis_client)
  $redis.ping
  puts "Redis connection successful" if Rails.env.development?
rescue StandardError => e
  puts "⚠️ Failed to connect to Redis: #{e.message}" unless Rails.env.production?
end
