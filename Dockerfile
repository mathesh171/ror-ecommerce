FROM public.ecr.aws/docker/library/ruby:3.3.8-slim

ENV APP_DIR=/var/www/ror_ecommerce

ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true
ENV SECRET_KEY_BASE=dummy

ENV ACTIVE_STORAGE_SERVICE=local
ENV EAGER_LOAD=false
ENV FORCE_SSL=false
ENV ASSETS_COMPILE=true

RUN apt-get update -y && apt-get install -y \
    git \
    curl \
    wget \
    nginx \
    build-essential \
    default-libmysqlclient-dev \
    default-mysql-client \
    nodejs \
    npm \
    pkg-config \
    libssl-dev \
    libyaml-dev \
    libffi-dev \
    zlib1g-dev \
    libxml2-dev \
    libxslt1-dev \
    libsqlite3-dev \
    procps \
    && rm -rf /var/lib/apt/lists/*

RUN gem update --system && gem install bundler

WORKDIR ${APP_DIR}

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . .

RUN mkdir -p \
    storage \
    tmp/storage \
    tmp/cache \
    tmp/pids \
    public/assets \
    log \
    /opt/aws/amazon-cloudwatch-agent/logs \
    /opt/aws/amazon-cloudwatch-agent/logs/state && \
    touch log/production.log && \
    rm -rf tmp/cache/*

RUN RAILS_ENV=production \
    SECRET_KEY_BASE=dummy \
    bundle exec rails assets:clobber && \
    bundle exec rails assets:precompile

RUN wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb && \
    dpkg -i amazon-cloudwatch-agent.deb && \
    rm -f amazon-cloudwatch-agent.deb

COPY amazon-cloudwatch-agent.json \
    /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

COPY nginx.conf /etc/nginx/sites-available/ror-ecommerce

RUN rm -f /etc/nginx/sites-enabled/default && \
    ln -sf /etc/nginx/sites-available/ror-ecommerce \
        /etc/nginx/sites-enabled/ror-ecommerce

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 80

CMD ["/entrypoint.sh"]