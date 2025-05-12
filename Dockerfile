FROM ruby:3.1.2

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install specific Nokogiri version with native extensions
RUN gem install nokogiri -v '1.18.8' --platform=ruby

# Add Gemfile and install gems
COPY Gemfile Gemfile.lock ./

# Install gems for production
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 20 --retry 5

# Copy the application
COPY . .

# Precompile assets if needed
RUN if grep -q "assets:precompile" Rakefile; then \
      SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rake assets:precompile; \
    fi

# Expose port
EXPOSE 8080

# Start the server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "8080"]