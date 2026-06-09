#!/bin/bash

set -e

cd /var/www/ror_ecommerce

cat > config/database.yml <<DBEOF
default: &default
  adapter: mysql2
  encoding: utf8mb4
  pool: 5
  username: "${DB_USER}"
  password: "${DB_PASS}"
  host: "${DB_HOST}"
  port: 3306

production:
  <<: *default
  database: ${DB_NAME}
DBEOF

echo "Checking RDS..."
until mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1;" >/dev/null 2>&1
do
  echo "Waiting for RDS..."
  sleep 5
done

export RAILS_ENV=production
export RAILS_SERVE_STATIC_FILES=true

echo "Precompiling assets..."
bundle exec rails assets:precompile || true

echo "Starting Rails..."
bundle exec rails server \
  -b 0.0.0.0 \
  -p 3000 \
  -e production &

echo "Starting Nginx..."
exec nginx -g "daemon off;"