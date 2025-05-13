# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Add your GitHub Pages domain to the allowed origins
    origins ['http://localhost:3000', 'https://ahmedali1ccs.github.io']
    
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Content-Type', 'Content-Disposition'], # Important for file downloads
      credentials: false
  end
end