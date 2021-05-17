FROM ruby:2.7.3

ENV NODE_VER="12.22.1"

ENV GITHUB_REPO=glitch-soc/mastodon
#ENV GITHUB_REPO=tootsuite/mastodon

# Add more PATHs to the PATH
ENV PATH="${PATH}:/opt/ruby/bin:/opt/node/bin:/opt/mastodon/bin"

# whois contains mkpasswd
RUN echo "*** phase 1 install nodejs" && \
    apt-get update && \
    apt-get -y --no-install-recommends install \
        wget python whois \
        git libicu-dev libidn11-dev \
        libpq-dev libprotobuf-dev protobuf-compiler \
        libssl1.1 libpq5 imagemagick ffmpeg \
        libicu63 libprotobuf17 libidn11 libyaml-0-2 \
        file ca-certificates tzdata libreadline7 && \
    apt-get install -y libjemalloc-dev libjemalloc2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    cd ~ && \
    wget -q https://nodejs.org/download/release/v$NODE_VER/node-v$NODE_VER-linux-x64.tar.gz && \
    tar xf node-v$NODE_VER-linux-x64.tar.gz && \
    rm node-v$NODE_VER-linux-x64.tar.gz && \
    mv node-v$NODE_VER-linux-x64 /opt/node  

# Use jemalloc
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

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
ENV INIT_VER="1.2.2"
ENV INIT_SUM="37f2c1f0372a45554f1b89924fbb134fc24c3756efaedf11e07f599494e0eff9"
ADD https://github.com/Yelp/dumb-init/releases/download/v${INIT_VER}/dumb-init_${INIT_VER}_amd64 /dumb-init
RUN echo "$INIT_SUM  dumb-init" | sha256sum -c -
RUN chmod +x /dumb-init

# Get gemfile from mastodon source
#ADD https://raw.githubusercontent.com/${GITHUB_REPO}/master/Gemfile /opt/mastodon/Gemfile
#ADD https://raw.githubusercontent.com/${GITHUB_REPO}/master/Gemfile.lock /opt/mastodon/Gemfile.lock

# git clone all sources
# and modify version
#RUN cd /opt && git clone --depth 1 https://github.com/${GITHUB_REPO}.git glitch  && \
#    cp -rf /opt/glitch/* /opt/mastodon/ && rm -rf /opt/glitch && \
#    sed -i /opt/mastodon/lib/mastodon/version.rb -e "s/\+glitch/\+glitch_`date '+%m%d'`/"  && \
COPY --chown=mastodon:mastodon ./build /opt/mastodon

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
    cd && \
    export OTP_SECRET=precompile_placeholder && \
    export SECRET_KEY_BASE=precompile_placeholder && \
    bundle exec rake assets:precompile

# Set the work dir and the container entry point
WORKDIR /opt/mastodon
ENTRYPOINT ["/dumb-init", "--"]
