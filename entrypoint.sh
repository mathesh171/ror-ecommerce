#!/bin/bash

set -e

cd /var/www/ror_ecommerce

: "${DB_HOST:?DB_HOST is required}"
: "${DB_USER:?DB_USER is required}"
: "${DB_PASS:?DB_PASS is required}"
: "${DB_NAME:?DB_NAME is required}"

if [ ! -f config/database.yml ]; then
cat > config/database.yml <<EOF
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
EOF
fi

wait_for_db() {
    echo "Checking RDS..."

    until mysql \
        -h "$DB_HOST" \
        -u "$DB_USER" \
        -p"$DB_PASS" \
        -e "SELECT 1;" >/dev/null 2>&1
    do
        echo "Waiting for RDS..."
        sleep 5
    done

    echo "Database is available."
}

wait_for_db

echo "Running database migrations..."
bundle exec rails db:migrate

echo "Running database seeds..."
bundle exec rails db:seed || true

echo "Preparing CloudWatch Agent..."

/opt/aws/amazon-cloudwatch-agent/bin/config-translator \
    -input /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -input-dir /opt/aws/amazon-cloudwatch-agent/etc \
    -output /tmp/cwagent.toml

if [ -f /tmp/cwagent.toml ]; then
    echo "Starting CloudWatch Agent..."

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent \
        -config /tmp/cwagent.toml &
else
    echo "CloudWatch Agent configuration generation failed."
fi

echo "Starting Rails..."

bundle exec rails server \
    -b 0.0.0.0 \
    -p 3000 \
    -e production &

echo "Starting Nginx..."

exec nginx -g "daemon off;"