FROM public.ecr.aws/docker/library/ruby:3.3.8-slim

ENV APP_DIR=/var/www/ror_ecommerce
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true
ENV SECRET_KEY_BASE=dummy

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

COPY . .

RUN grep -q 'gem "mysql2"' Gemfile || echo 'gem "mysql2"' >> Gemfile

RUN bundle install

RUN cp config/settings.yml.example config/settings.yml || touch config/settings.yml

RUN sed -i 's/config.active_storage.service = :amazon/config.active_storage.service = :local/g' config/environments/production.rb || true && \
    sed -i 's/config.eager_load = true/config.eager_load = false/g' config/environments/production.rb || true && \
    sed -i 's/config.force_ssl = true/config.force_ssl = false/g' config/environments/production.rb || true && \
    sed -i 's/config.assets.compile = false/config.assets.compile = true/g' config/environments/production.rb || true && \
    sed -i '/searchkick/d' app/models/product.rb || true

RUN mkdir -p \
    storage \
    tmp/storage \
    tmp/pids \
    tmp/cache \
    public/assets \
    log

RUN touch log/production.log

RUN rm -rf tmp/cache/*

RUN RAILS_ENV=production SECRET_KEY_BASE=dummy bundle exec rails assets:clobber

RUN RAILS_ENV=production SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

RUN wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

RUN dpkg -i amazon-cloudwatch-agent.deb

RUN mkdir -p \
    /opt/aws/amazon-cloudwatch-agent/logs \
    /opt/aws/amazon-cloudwatch-agent/logs/state

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