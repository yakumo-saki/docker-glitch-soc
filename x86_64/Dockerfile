FROM ruby:3.0-bullseye

ENV NODE_VER="18.15.0"
ENV NODE_PLATFORM="linux-x64"

ENV NODE_OPTIONS=--openssl-legacy-provider

ENV DIR_LIB="/usr/lib/x86_64-linux-gnu"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Completely same all arches after this line
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Add more PATHs to the PATH
ENV PATH="${PATH}:/opt/ruby/bin:/opt/node/bin:/opt/mastodon/bin"

# whois contains mkpasswd
RUN echo "*** phase 1 install nodejs" && \
    apt-get update && \
    apt-get -y --no-install-recommends install \
        tini \
        wget python whois \
        git libicu-dev libidn11-dev \
        libpq-dev libprotobuf-dev protobuf-compiler \
        libssl1.1 libpq5 imagemagick ffmpeg \
        libicu67 libidn11 libyaml-0-2 \
        file ca-certificates tzdata libreadline8 \
        libjemalloc-dev libjemalloc2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    cd ~ && \
    wget -q https://nodejs.org/download/release/v${NODE_VER}/node-v${NODE_VER}-${NODE_PLATFORM}.tar.gz && \
    tar xf node-v$NODE_VER-${NODE_PLATFORM}.tar.gz && \
    rm node-v$NODE_VER-${NODE_PLATFORM}.tar.gz && \
    mv node-v$NODE_VER-${NODE_PLATFORM} /opt/node  

# Use jemalloc
ENV LD_PRELOAD=${DIR_LIB}/libjemalloc.so.2

# install node.js
RUN echo "*** install yarn, bundler etc..." && \
    npm install -g yarn && \
    gem install bundler && \
    echo "done"

# Create the mastodon user
ARG UID=991
ARG GID=991
RUN echo "Etc/UTC" > /etc/localtime && \
    echo "not exec ln -s /opt/jemalloc/lib/* /usr/lib/" && \
    addgroup --gid $GID mastodon && \
    useradd -l -m -u $UID -g $GID -d /opt/mastodon mastodon && \
    echo "mastodon:$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 24 | mkpasswd -s -m sha-256)" | chpasswd && \
    echo "done"

COPY --chown=mastodon:mastodon ./mastodon /opt/mastodon

# create override dir to replace files
RUN mkdir /opt/mastodon/public/override && \
    chown -R mastodon:mastodon /opt/mastodon

# Install mastodon runtime deps
RUN ln -s /opt/mastodon /mastodon && \
    rm -rvf /var/cache && \
    rm -rvf /var/lib/apt/lists/* && \
    cd /opt/mastodon && \
    bundle config set without 'development test' && \
    bundle env && \
    bundle install -j$(nproc) --no-deployment

# 20210214
# due to rdf gem's some files are not readable from others
RUN chmod -R o+r /usr/local/bundle/gems/

# Set the run user
USER mastodon

# Tell rails to serve static files
ENV RAILS_SERVE_STATIC_FILES="true"
ENV RAILS_ENV="production"
ENV NODE_ENV="production"

RUN cd && \
    yarn install --pure-lockfile && \
    yarn cache clean && \ 
    npx browserslist@latest --update-db && \
    cd && \
    export OTP_SECRET=precompile_placeholder && \
    export SECRET_KEY_BASE=precompile_placeholder && \
    bundle exec rake assets:precompile

# Set the work dir and the container entry point
WORKDIR /opt/mastodon
ENTRYPOINT ["tini", "--"]
