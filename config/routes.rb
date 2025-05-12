# config/routes.rb
require 'sidekiq/web'

# Configure Sidekiq web UI with session middleware
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: '_mailing_database_app_session'

Rails.application.routes.draw do
  get "/up", to: proc { [200, {}, ["OK"]] }
  namespace :api do
    namespace :v1 do
      resources :mailed do
        collection do
          post :import
          get :export
        end
      end
      get '/test', to: proc { [200, {'Content-Type' => 'text/plain'}, ['Rails API is working!']] }
      # Search route
      get '/search', to: 'mailed#search'
    end
  end
  
  # Mount Sidekiq web UI
  mount Sidekiq::Web => '/sidekiq'
  
  # Root route
  root 'homepage#index'
  
  # Catch-all route
  get '*path', to: 'homepage#index', constraints: lambda { |req| 
    !req.xhr? && req.format.html? && !req.path.start_with?('/api/')
  }
end
