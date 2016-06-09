FROM rails

WORKDIR /usr/src/app

ENV DISCOURSE_VERSION=1.6.0.beta7 \
    RAILS_ENV=production \
    RUBY_GC_MALLOC_LIMIT=90000000 \
    DISCOURSE_DB_HOST=postgres \
    DISCOURSE_REDIS_HOST=redis \
    DISCOURSE_SERVE_STATIC_ASSETS=true

RUN apt-get update && apt-get install -y --no-install-recommends imagemagick libxml2 \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --branch v${DISCOURSE_VERSION} https://github.com/discourse/discourse.git . \
 && git remote set-branches --add origin tests-passed \
 && bundle config build.nokogiri --use-system-libraries \
 && bundle install --deployment --without test --without development

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
