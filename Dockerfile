# Based on the Dockerfile from mastodon:v2.7.3
# git clone's mastodon's code from github, and patches it

FROM node:8.15.0-alpine as node
FROM ruby:2.6-alpine3.8

LABEL maintainer="https://github.com/tootsuite/mastodon" \
      description="Your self-hosted, globally interconnected microblogging community"

ARG UID=1055
ARG GID=1055

ENV PATH=/mastodon/bin:$PATH \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_ENV=production \
    NODE_ENV=production

ARG LIBICONV_VERSION=1.15
ARG LIBICONV_DOWNLOAD_SHA256=ccf536620a45458d26ba83887a983b96827001e92a13847b45e4925cc8913178

EXPOSE 3000 4000

WORKDIR /mastodon

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/npm /usr/local/bin/npm
COPY --from=node /opt/yarn-* /opt/yarn

RUN apk -U upgrade \
 && apk add -t build-dependencies \
    build-base \
    icu-dev \
    libidn-dev \
    libressl \
    libtool \
    libxml2-dev \
    libxslt-dev \
    postgresql-dev \
    protobuf-dev \
    python \
 && apk add \
    ca-certificates \
    ffmpeg \
    file \
    git \
    icu-libs \
    imagemagick \
    libidn \
    libpq \
    libxml2 \
    libxslt \
    protobuf \
    tini \
    tzdata \
 && update-ca-certificates \
 && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
 && ln -s /opt/yarn/bin/yarnpkg /usr/local/bin/yarnpkg \
 && mkdir -p /tmp/src /opt \
 && wget -O libiconv.tar.gz "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$LIBICONV_VERSION.tar.gz" \
 && echo "$LIBICONV_DOWNLOAD_SHA256 *libiconv.tar.gz" | sha256sum -c - \
 && tar -xzf libiconv.tar.gz -C /tmp/src \
 && rm libiconv.tar.gz \
 && cd /tmp/src/libiconv-$LIBICONV_VERSION \
 && ./configure --prefix=/usr/local \
 && make -j$(getconf _NPROCESSORS_ONLN)\
 && make install \
 && libtool --finish /usr/local/lib \
 && cd /mastodon \
 && rm -rf /tmp/* /var/cache/apk/*

RUN addgroup -g ${GID} ocfmastodon && adduser -h /mastodon -s /bin/sh -D -G ocfmastodon -u ${UID} ocfmastodon

# Changes begin here
RUN ls /mastodon

USER ocfmastodon

RUN git clone --branch 'v2.7.3' https://github.com/tootsuite/mastodon /mastodon

RUN mkdir -p /mastodon/public/system /mastodon/public/assets /mastodon/public/packs

VOLUME /mastodon/public/system

RUN bundle config build.nokogiri --usesystem-libraries --with-iconv-lib=/usr/local/lib --with-iconv-include=/usr/local/include \
 && bundle install -j$(getconf _NPROCESSORS_ONLN) --deployment --without test development \
 && yarn install --pure-lockfile --ignore-engines \
 && yarn cache clean

# Some minor patching
COPY patches/ocf_email.patch /mastodon
RUN git apply /mastodon/ocf_email.patch

# Changes end here

RUN OTP_SECRET=precompile_placeholder SECRET_KEY_BASE=precompile_placeholder bundle exec rails assets:precompile

ENTRYPOINT ["/sbin/tini", "--"]
