# config/initializers/sidekiq.rb

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{REDIS_CONFIG[:host]}:#{REDIS_CONFIG[:port]}/#{REDIS_CONFIG[:db]}" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{REDIS_CONFIG[:host]}:#{REDIS_CONFIG[:port]}/#{REDIS_CONFIG[:db]}" }
end