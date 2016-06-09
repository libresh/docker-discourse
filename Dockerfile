FROM rails:4.1

WORKDIR /usr/src/app

ENV DISCOURSE_VERSION=1.4.7 \
    RAILS_ENV=production \
    RUBY_GC_MALLOC_LIMIT=90000000 \
    DISCOURSE_DB_HOST=postgres \
    DISCOURSE_REDIS_HOST=redis \
    DISCOURSE_SERVE_STATIC_ASSETS=true

RUN apt-get update && apt-get install -y --no-install-recommends imagemagick libxml2 \
 && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/discourse/discourse/archive/v${DISCOURSE_VERSION}.tar.gz \
  | tar -xz -C /usr/src/app --strip-components 1 \
 && bundle config build.nokogiri --use-system-libraries \
 && bundle install --deployment --without test --without development

EXPOSE 3000
CMD ["rails", "server"]
