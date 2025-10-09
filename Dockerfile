FROM ruby:3.2.2

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Add Gemfile and install gems
COPY Gemfile Gemfile.lock ./

# Install gems for production
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 20 --retry 5

# Copy the application
COPY . .

# Copy and set up entrypoint
COPY bin/docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh

# Expose port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# Start the server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "8080"]