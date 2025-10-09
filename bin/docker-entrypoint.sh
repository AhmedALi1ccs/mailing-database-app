#!/bin/bash
set -e

echo "Setting up database..."
bundle exec rails db:migrate:status 2>/dev/null || bundle exec rails db:schema:load
bundle exec rails db:migrate

echo "Starting Rails server..."
exec "$@"