#!/usr/bin/env bash
set -o errexit

# Update RubyGems to meet nokogiri requirements
gem update --system --no-document

# Install dependencies
bundle install

# Run database migrations
bundle exec rails db:migrate