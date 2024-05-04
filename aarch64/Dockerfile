# syntax=docker/dockerfile:1.4
ARG NODE_VERSION="lts-bookworm-slim"
ARG RUBY_YJIT_ENABLE="1"

FROM ghcr.io/moritzheiber/ruby-jemalloc:3.2.3-slim as ruby
FROM node:${NODE_VERSION} as build

COPY --link --from=ruby /opt/ruby /opt/ruby

ENV DEBIAN_FRONTEND="noninteractive" \
    PATH="${PATH}:/opt/ruby/bin" \
    RUBY_YJIT_ENABLE=${RUBY_YJIT_ENABLE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /opt/mastodon
COPY ./mastodon/Gemfile* ./mastodon/package.json ./mastodon/yarn.lock /opt/mastodon/
COPY ./mastodon/.yarn/patches/* /opt/mastodon/.yarn/patches/

# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential \
        ca-certificates \
        git \
        g++ \
        gcc \
        libicu-dev \
        libidn-dev \
        libpq-dev \
        libjemalloc-dev \
        libgdbm-dev \
        libgmp-dev \
        libssl-dev \
        libyaml-0-2 \
        libyaml-dev \
        ca-certificates \
        libreadline8 \
        python3 \
        shared-mime-info \
        zlib1g-dev

RUN bundle config set --local deployment 'true' && \
    bundle config set --global frozen "true" && \
    bundle config set --global cache_all "false" && \
    bundle config set --local without 'development test' && \
    bundle config set silence_root_warning true && \
    bundle install -j"$(nproc)"

RUN corepack enable && \
    yarn workspaces focus --all --production && \
    yarn install --network-timeout 600000 

# -------------------------------------------
FROM node:${NODE_VERSION}

ENV MASTODON_VERSION_METADATA="!!!!!!REPLACE_VER_METADATA!!!!!!"
ENV MALLOC_CONF="narenas:2,background_thread:true,thp:never,dirty_decay_ms:1000,muzzy_decay_ms:0"

ARG UID="991"
ARG GID="991"

COPY --link --from=ruby /opt/ruby /opt/ruby

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND="noninteractive" \
    PATH="${PATH}:/opt/ruby/bin:/opt/mastodon/bin" \
    RAILS_ENV="production" \
    NODE_ENV="production" \
    RAILS_SERVE_STATIC_FILES="true" \
    BIND="0.0.0.0"

# Ignoreing these here since we don't want to pin any versions and the Debian image removes apt-get content after use
# hadolint ignore=DL3008,DL3009
RUN apt-get update && \
    echo "Etc/UTC" > /etc/localtime && \
    groupadd -g "${GID}" mastodon && \
    useradd -l -u "$UID" -g "${GID}" -m -d /opt/mastodon mastodon && \
    apt-get -y --no-install-recommends install whois \
        curl \
        wget \
        procps \
        libssl3 \
        libpq5 \
        imagemagick \
        ffmpeg \
        libjemalloc2 \
        libicu72 \
        libidn12 \
        libyaml-0-2 \
        file \
        ca-certificates \
        tzdata \
        libreadline8 \
        tini && \
    ln -s /opt/mastodon /mastodon

# Note: no, cleaning here since Debian does this automatically
# See the file /etc/apt/apt.conf.d/docker-clean within the Docker image's filesystem

COPY --chown=mastodon:mastodon ./mastodon /opt/mastodon
COPY --chown=mastodon:mastodon --from=build /opt/mastodon /opt/mastodon

# Precompile assets
WORKDIR /opt/mastodon

RUN \
    corepack enable && \ 
    yarn workspaces focus --all --production && \
    ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=precompile_placeholder \
    ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=precompile_placeholder \
    ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=precompile_placeholder \
    OTP_SECRET=precompile_placeholder \
    SECRET_KEY_BASE=precompile_placeholder \
    ./bin/rails assets:precompile

RUN \
    # Pre-create and chown system volume to Mastodon user
    mkdir -p /opt/mastodon/public/system && \
    chown mastodon:mastodon /opt/mastodon/public/system && \
    # Set Mastodon user as owner of tmp folder
    chown -R mastodon:mastodon /opt/mastodon/tmp

# Set the run user
USER mastodon

# Set the work dir and the container entry point
EXPOSE 3000 4000
ENTRYPOINT ["/usr/bin/tini", "--"]
