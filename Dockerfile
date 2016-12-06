FROM rails

WORKDIR /usr/src/app

ENV DISCOURSE_VERSION=1.7.0.beta3 \
    RAILS_ENV=production \
    RUBY_GC_MALLOC_LIMIT=90000000 \
    RUBY_GLOBAL_METHOD_CACHE_SIZE=131072 \
    DISCOURSE_DB_HOST=postgres \
    DISCOURSE_REDIS_HOST=redis \
    DISCOURSE_SERVE_STATIC_ASSETS=true \
    GIFSICLE_VERSION=1.87 \
    PNGQUANT_VERSION=2.4.1

RUN curl --silent --location https://deb.nodesource.com/setup_4.x | bash - \
 && apt-get update && apt-get install -y --no-install-recommends \
      autoconf \
      ghostscript \
      gsfonts \
      imagemagick \
      jhead \
      jpegoptim \
      libbz2-dev \
      libfreetype6-dev \
      libjpeg-dev \
      libjpeg-turbo-progs \
      libtiff-dev \
      libxml2 \
      nodejs \
      optipng \
      pkg-config \
 && cd /tmp \
 && curl -O http://www.lcdf.org/gifsicle/gifsicle-$GIFSICLE_VERSION.tar.gz \
 && tar zxf gifsicle-$GIFSICLE_VERSION.tar.gz \
 && cd gifsicle-$GIFSICLE_VERSION \
 && ./configure && make install && cd ..\
 && wget https://github.com/pornel/pngquant/archive/$PNGQUANT_VERSION.tar.gz \
 && tar zxf $PNGQUANT_VERSION.tar.gz \
 && cd pngquant-$PNGQUANT_VERSION \
 && ./configure && make && make install \
 && npm install svgo uglify-js -g \
 && rm -fr /tmp/* \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --branch v${DISCOURSE_VERSION} https://github.com/discourse/discourse.git . \
 && git remote set-branches --add origin tests-passed \
 && bundle config build.nokogiri --use-system-libraries \
 && bundle install --deployment --without test --without development


# install discourse plugins
# assumptions: no spaces in URLs (urlencoding is a thing)
# 
# this expects a git-cloneable link
ARG DISCOURSE_ADDITIONAL_PLUGINS=
RUN if [ "$DISCOURSE_ADDITIONAL_PLUGINS" != "" ]; then \
        cd plugins/; \
        for PACKAGE_LINK in $DISCOURSE_ADDITIONAL_PLUGINS; do \
            git clone "$PACKAGE_LINK"; \
        done; \
    fi

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
