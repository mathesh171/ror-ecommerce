FROM public.ecr.aws/docker/library/ruby:3.3.8-slim AS builder

ENV APP_DIR=/var/www/ror_ecommerce \
    RAILS_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true \
    SECRET_KEY_BASE=dummy \
    ACTIVE_STORAGE_SERVICE=local \
    EAGER_LOAD=false \
    FORCE_SSL=false

WORKDIR ${APP_DIR}

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    default-libmysqlclient-dev \
    nodejs \
    pkg-config \
    libssl-dev \
    libyaml-dev \
    libffi-dev \
    zlib1g-dev \
    libxml2-dev \
    libxslt1-dev \
    && rm -rf /var/lib/apt/lists/*

RUN gem update --system && gem install bundler

COPY Gemfile Gemfile.lock ./

RUN bundle config set without 'development test' && \
    bundle config set deployment true && \
    bundle install

COPY . .

RUN mkdir -p storage tmp/storage tmp/cache tmp/pids public/assets log

RUN bundle exec rails assets:clobber && \
    bundle exec rails assets:precompile



FROM public.ecr.aws/docker/library/ruby:3.3.8-slim

ENV APP_DIR=/var/www/ror_ecommerce \
    RAILS_ENV=production \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true \
    ACTIVE_STORAGE_SERVICE=local \
    EAGER_LOAD=false \
    FORCE_SSL=false

WORKDIR ${APP_DIR}

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    default-libmysqlclient-dev \
    wget \
    && wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb \
    && dpkg -i amazon-cloudwatch-agent.deb \
    && rm amazon-cloudwatch-agent.deb \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder ${APP_DIR} ${APP_DIR}

COPY amazon-cloudwatch-agent.json \
/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

COPY nginx.conf \
/etc/nginx/sites-available/ror-ecommerce

RUN mkdir -p /opt/aws/amazon-cloudwatch-agent/logs/state && \
    rm -f /etc/nginx/sites-enabled/default && \
    ln -sf \
    /etc/nginx/sites-available/ror-ecommerce \
    /etc/nginx/sites-enabled/ror-ecommerce && \
    chmod +x /entrypoint.sh

EXPOSE 80

CMD ["/entrypoint.sh"]