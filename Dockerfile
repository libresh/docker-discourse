FROM rails

WORKDIR /usr/src/app

ENV DISCOURSE_VERSION 1.4.5

RUN apt-get update && apt-get install -y --no-install-recommends imagemagick libxml2 \
 && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/discourse/discourse/archive/v${DISCOURSE_VERSION}.tar.gz \
  | tar -xz -C /usr/src/app --strip-components 1 \
 && bundle config build.nokogiri --use-system-libraries \
 && bundle install --deployment --without test --without development

ENV RAILS_ENV production
ENV RUBY_GC_MALLOC_LIMIT 90000000
ENV DISCOURSE_DB_HOST postgres
ENV DISCOURSE_REDIS_HOST redis
ENV DISCOURSE_SERVE_STATIC_ASSETS true

EXPOSE 3000
CMD ["rails", "server"]
