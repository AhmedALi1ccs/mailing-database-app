#!/usr/bin/env bash
set -o errexit

# Update bundler first
gem update --system 3.3.22

# Remove Gemfile.lock and regenerate
rm -f Gemfile.lock

# Install dependencies
bundle install

# Run database migrations
bundle exec rails db:migrate