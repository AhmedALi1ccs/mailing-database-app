#!/bin/bash
set -e

echo "Skipping migrations - database managed manually"
echo "Starting Rails server..."

exec "$@"