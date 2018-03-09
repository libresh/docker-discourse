FROM ruby:2.4.1

ENV RAILS_ENV=production \
    RUBY_GC_MALLOC_LIMIT=90000000 \
    RUBY_GLOBAL_METHOD_CACHE_SIZE=131072 \
    DISCOURSE_DB_HOST=postgres \
    DISCOURSE_REDIS_HOST=redis \
    DISCOURSE_SERVE_STATIC_ASSETS=true \
    GIFSICLE_VERSION=1.88 \
    PNGQUANT_VERSION=2.8.0 \
    DISCOURSE_VERSION=1.9.4 \
    DISCOURSE_VERSION=1.9.0.beta15 \
    BUILD_DEPS="\
      autoconf \
      jhead \
      libbz2-dev \
      libfreetype6-dev \
      libjpeg-dev \
      libjpeg-turbo-progs \
      libtiff-dev \
      pkg-config"


RUN addgroup --gid 1000 discourse \
 && adduser --system --uid 1000 --ingroup discourse --shell /bin/bash discourse \
 && cd /home/discourse \
 && mkdir -p ./tmp/sockets \
 && git clone --branch v${DISCOURSE_VERSION} https://github.com/discourse/discourse.git \
 && chown -R discourse:discourse . \
 && curl --silent --location https://deb.nodesource.com/setup_8.x | bash - \
 && apt-get update && apt-get install -y --no-install-recommends \
      ${BUILD_DEPS} \
      ghostscript \
      gsfonts \
      imagemagick \
      jpegoptim \
      libxml2 \
      nodejs \
      optipng \
 && npm install svgo uglify-js@"<3" -g \
 && cd /tmp \
 && curl -O http://www.lcdf.org/gifsicle/gifsicle-$GIFSICLE_VERSION.tar.gz \
 && tar zxf gifsicle-$GIFSICLE_VERSION.tar.gz \
 && cd gifsicle-$GIFSICLE_VERSION \
 && ./configure && make install \
 && cd /tmp \
 && rm gifsicle-$GIFSICLE_VERSION.tar.gz \
 && rm -rf gifsicle-$GIFSICLE_VERSION \
 && git clone -b $PNGQUANT_VERSION --single-branch https://github.com/pornel/pngquant \
 && cd pngquant \
 && make && make install \
 && rm -rf pngquant \
 && cd /home/discourse/discourse \
 && git remote set-branches --add origin tests-passed \
 && sed -i 's/daemonize true/daemonize false/g' ./config/puma.rb \
 && bundle config build.nokogiri --use-system-libraries \
 && bundle install --deployment --without test --without development \
 && cd /tmp \
 && curl -O https://get.enterprisedb.com/postgresql/postgresql-9.5.9-1-linux-x64-binaries.tar.gz \
 && tar zxf postgresql-9.5.9-1-linux-x64-binaries.tar.gz \
 && mv ./pgsql/bin/* /usr/local/bin/ \
 && rm postgresql-9.5.9-1-linux-x64-binaries.tar.gz \
 && rm -rf ./pgsql \
 && apt-get remove -y --purge ${BUILD_DEPS} \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /home/discourse/discourse

USER discourse

CMD bundle exec rails server -b 0.0.0.0
