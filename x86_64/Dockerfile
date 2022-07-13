FROM ruby:3.0.4-bullseye

ENV NODE_VER="16.15.0"
ENV NODE_PLATFORM="linux-x64"

ENV INIT_VER="1.2.5"
ENV INIT_PLATFORM="x86_64"
ENV INIT_SUM="e874b55f3279ca41415d290c512a7ba9d08f98041b28ae7c2acb19a545f1c4df"

ENV DIR_LIB="/usr/lib/x86_64-linux-gnu"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Completely same all arches after this line
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Add more PATHs to the PATH
ENV PATH="${PATH}:/opt/ruby/bin:/opt/node/bin:/opt/mastodon/bin"

# whois contains mkpasswd
RUN echo "*** phase 1 install nodejs" && \
    apt-get update && \
    apt-get -y --no-install-recommends install \
        wget whois \
        git libicu-dev libidn11-dev \
        libpq-dev libprotobuf-dev protobuf-compiler \
        libssl1.1 libpq5 imagemagick ffmpeg \
        libicu67 libidn11 libyaml-0-2 \
        file ca-certificates tzdata libreadline8 \
        libjemalloc-dev && \
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
    useradd -m -u $UID -g $GID -d /opt/mastodon mastodon && \
    echo "mastodon:`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 24 | mkpasswd -s -m sha-256`" | chpasswd && \
    echo "done"

# add dumb-init
ADD https://github.com/Yelp/dumb-init/releases/download/v${INIT_VER}/dumb-init_${INIT_VER}_${INIT_PLATFORM} /dumb-init
RUN echo "$INIT_SUM  dumb-init" | sha256sum -c - && \
    chmod +x /dumb-init

COPY --chown=mastodon:mastodon ./build /opt/mastodon

# create override dir to replace files
RUN mkdir /opt/mastodon/public/override

# Install mastodon runtime deps
RUN ln -s /opt/mastodon /mastodon && \
    rm -rvf /var/cache && \
    rm -rvf /var/lib/apt/lists/* && \
    cd /opt/mastodon && \
    bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle config set silence_root_warning true && \
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
ENV BIND="0.0.0.0"

RUN cd && \
    yarn install --pure-lockfile && \
    yarn cache clean && \ 
    cd && \
    export OTP_SECRET=precompile_placeholder && \
    export SECRET_KEY_BASE=precompile_placeholder && \
    bundle exec rake assets:precompile

# Set the work dir and the container entry point
WORKDIR /opt/mastodon
ENTRYPOINT ["/dumb-init", "--"]
