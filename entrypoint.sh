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
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1;"

echo "Starting Rails..."
bundle exec rails server -b 0.0.0.0 -p 3000 -e production &

echo "Starting Nginx..."
exec nginx -g "daemon off;"
