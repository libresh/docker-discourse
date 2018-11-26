FROM ruby:2.5.3

ENV RAILS_ENV=production \
    DISCOURSE_DB_HOST=postgres \
    DISCOURSE_REDIS_HOST=redis \
    DISCOURSE_SERVE_STATIC_ASSETS=true \
    GIFSICLE_VERSION=1.91 \
    PNGQUANT_VERSION=2.12.1 \
    PNGCRUSH_VERSION=1.8.13 \
    DISCOURSE_VERSION=2.2.0.beta4 \
    PG_MAJOR=10 \
    BUILD_DEPS="\
      autoconf \
      advancecomp \
      libbz2-dev \
      libfreetype6-dev \
      libjpeg-dev \
      libjpeg-turbo-progs \
      libtiff-dev \
      pkg-config"

RUN curl http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" | \
        tee /etc/apt/sources.list.d/postgres.list

RUN curl --silent --location https://deb.nodesource.com/setup_8.x | bash - \
 && apt-get update && apt-get install -y --no-install-recommends \
      ${BUILD_DEPS} \
      ghostscript \
      gsfonts \
      imagemagick \
      jpegoptim \
      libxml2 \
      nodejs \
      optipng \
      jhead \
      postgresql-client-${PG_MAJOR} \
      postgresql-contrib-${PG_MAJOR} libpq-dev libreadline-dev

RUN npm install svgo uglify-js@"<3" -g

RUN mkdir /jemalloc-stable && cd /jemalloc-stable &&\
      wget https://github.com/jemalloc/jemalloc/releases/download/3.6.0/jemalloc-3.6.0.tar.bz2 &&\
      tar -xjf jemalloc-3.6.0.tar.bz2 && cd jemalloc-3.6.0 && ./configure --prefix=/usr && make && make install &&\
      cd / && rm -rf /jemalloc-stable

RUN mkdir /jemalloc-new && cd /jemalloc-new &&\
      wget https://github.com/jemalloc/jemalloc/releases/download/5.1.0/jemalloc-5.1.0.tar.bz2 &&\
      tar -xjf jemalloc-5.1.0.tar.bz2 && cd jemalloc-5.1.0 && ./configure --prefix=/usr --with-install-suffix=5.1.0 && make build_lib && make install_lib &&\
      cd / && rm -rf /jemalloc-new


RUN gem update --system

RUN gem install bundler --force \
 && rm -rf /usr/local/share/ri/2.5.2/system 

ADD install-imagemagick /tmp/install-imagemagick
RUN /tmp/install-imagemagick

# Validate install
RUN ruby -Eutf-8 -e "v = \`convert -version\`; %w{png tiff jpeg freetype}.each { |f| unless v.include?(f); STDERR.puts('no ' + f +  ' support in imagemagick'); exit(-1); end }"

ADD install-pngcrush /tmp/install-pngcrush
RUN /tmp/install-pngcrush

ADD install-gifsicle /tmp/install-gifsicle
RUN /tmp/install-gifsicle

ADD install-pngquant /tmp/install-pngquant
RUN /tmp/install-pngquant

RUN addgroup --gid 1000 discourse \
 && adduser --system --uid 1000 --ingroup discourse --shell /bin/bash discourse \
 && cd /home/discourse \
 && mkdir -p tmp/pids \
 && mkdir -p ./tmp/sockets \
 && git clone --branch v${DISCOURSE_VERSION} https://github.com/discourse/discourse.git \
 && chown -R discourse:discourse . \
 && cd /home/discourse/discourse \
 && git remote set-branches --add origin tests-passed \
 && sed -i 's/daemonize true/daemonize false/g' ./config/puma.rb \
 && bundle config build.nokogiri --use-system-libraries \
 && bundle install --deployment --verbose --without test --without development --retry 3 --jobs 4

RUN find /home/discourse/discourse/vendor/bundle -name tmp -type d -exec rm -rf {} +

# RUN apt-get remove -y --purge ${BUILD_DEPS} \
# && apt-get autoremove -y \
# && rm -rf /var/lib/apt/lists/*

RUN rm -rf /var/lib/apt/lists/*

WORKDIR /home/discourse/discourse

ENV RAILS_ENV=production \
    RUBY_GLOBAL_METHOD_CACHE_SIZE=131072 \
    RUBY_GC_HEAP_GROWTH_MAX_SLOTS=40000 \
    RUBY_GC_HEAP_INIT_SLOTS=400000 \
    RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR=1.5 \
    RUBY_GC_MALLOC_LIMIT=90000000 

USER discourse

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
