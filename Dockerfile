# syntax=docker/dockerfile:1.18

# START CONFIG ARGS ------------------------------

ARG NODE_VERSION="lts-trixie-slim"
ARG RUBY_YJIT_ENABLE="1"

# Resulting version string is vX.X.X-MASTODON_VERSION_PRERELEASE+MASTODON_VERSION_METADATA
# Example: v4.3.0-nightly.2023.11.09+pr-123456
# Overwrite existence of 'alpha.X' in version.rb [--build-arg MASTODON_VERSION_PRERELEASE="nightly.2023.11.09"]
#ARG MASTODON_VERSION_PRERELEASE=""
# Append build metadata or fork information to version.rb [--build-arg MASTODON_VERSION_METADATA="pr-123456"]
ARG MASTODON_VERSION_METADATA="!!!!!!REPLACE_VER_METADATA!!!!!!"
# Will be available as Mastodon::Version.source_commit
ARG SOURCE_COMMIT="!!!!!!REPLACE_SOURCE_COMMIT!!!!!!"

# END CONFIG ARGS --------------------------------


# get ruby from moritzheiber's jemalloc image
FROM ghcr.io/moritzheiber/ruby-jemalloc:3.4.4-slim AS ruby

# -------------------------------------------
# build webpack and assets
# -------------------------------------------
FROM node:${NODE_VERSION} AS build

COPY --link --from=ruby /opt/ruby /opt/ruby

ENV DEBIAN_FRONTEND="noninteractive" \
    PATH="${PATH}:/opt/ruby/bin" \
    RUBY_YJIT_ENABLE="1"

SHELL ["/bin/bash", "-o", "pipefail", "-o", "errexit", "-c"]

WORKDIR /opt/mastodon
COPY ./mastodon/Gemfile* ./mastodon/package.json ./mastodon/yarn.lock /opt/mastodon/

# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential \
        ca-certificates \
        git \
        g++ \
        gcc \
        libidn11-dev \
        libpq-dev \
        libjemalloc-dev \
        libgdbm-dev \
        libvips42 \
        libreadline8 \
        python3 \
        shared-mime-info \
        zlib1g-dev \
        # from mastodon's builder: dockerfile:L137
        autoconf \
        automake \
        build-essential \
        cmake \
        git \
        libgdbm-dev \
        libglib2.0-dev \
        libgmp-dev \
        libicu-dev \
        libidn-dev \
        libpq-dev \
        libssl-dev \
        libtool \
        libyaml-dev \
        meson \
        nasm \
        pkg-config \
        shared-mime-info \
        xz-utils \
        # libvips components
        libcgif-dev \
        libexif-dev \
        libexpat1-dev \
        libgirepository1.0-dev \
        libheif-dev \
        libhwy-dev \
        libimagequant-dev \
        libjpeg62-turbo-dev \
        liblcms2-dev \
        libspng-dev \
        libtiff-dev \
        libwebp-dev \
        # ffmpeg components
        libdav1d-dev \
        liblzma-dev \
        libmp3lame-dev \
        libopus-dev \
        libsnappy-dev \
        libvorbis-dev \
        libvpx-dev \
        libx264-dev \
        libx265-dev \
        ;

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
# Libvips
# -------------------------------------------
# Create temporary libvips specific build layer from build layer
FROM build AS libvips

# libvips version to compile, change with [--build-arg VIPS_VERSION="8.15.2"]
# renovate: datasource=github-releases depName=libvips packageName=libvips/libvips
ARG VIPS_VERSION=8.17.3
# libvips download URL, change with [--build-arg VIPS_URL="https://github.com/libvips/libvips/releases/download"]
ARG VIPS_URL=https://github.com/libvips/libvips/releases/download

WORKDIR /usr/local/libvips/src
# Download and extract libvips source code
ADD ${VIPS_URL}/v${VIPS_VERSION}/vips-${VIPS_VERSION}.tar.xz /usr/local/libvips/src/
RUN tar xf vips-${VIPS_VERSION}.tar.xz;

WORKDIR /usr/local/libvips/src/vips-${VIPS_VERSION}

# Configure and compile libvips
RUN \
  meson setup build --prefix /usr/local/libvips --libdir=lib -Ddeprecated=false -Dintrospection=disabled -Dmodules=disabled -Dexamples=false; \
  cd build; \
  ninja; \
  ninja install;

# -------------------------------------------
# ffmpeg
# -------------------------------------------
FROM build AS ffmpeg

# ffmpeg version to compile, change with [--build-arg FFMPEG_VERSION="7.0.x"]
# renovate: datasource=repology depName=ffmpeg packageName=openpkg_current/ffmpeg
ARG FFMPEG_VERSION=8.0
# ffmpeg download URL, change with [--build-arg FFMPEG_URL="https://ffmpeg.org/releases"]
ARG FFMPEG_URL=https://github.com/FFmpeg/FFmpeg/archive/refs/tags

WORKDIR /usr/local/ffmpeg/src
# Download and extract ffmpeg source code
ADD ${FFMPEG_URL}/n${FFMPEG_VERSION}.tar.gz /usr/local/ffmpeg/src/
RUN tar xf n${FFMPEG_VERSION}.tar.gz && mv FFmpeg-n${FFMPEG_VERSION} ffmpeg-${FFMPEG_VERSION};

WORKDIR /usr/local/ffmpeg/src/ffmpeg-${FFMPEG_VERSION}

# Configure and compile ffmpeg
RUN \
  ./configure \
  --prefix=/usr/local/ffmpeg \
  --toolchain=hardened \
  --disable-debug \
  --disable-devices \
  --disable-doc \
  --disable-ffplay \
  --disable-network \
  --disable-static \
  --enable-ffmpeg \
  --enable-ffprobe \
  --enable-gpl \
  --enable-libdav1d \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libsnappy \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libwebp \
  --enable-libx264 \
  --enable-libx265 \
  --enable-shared \
  --enable-version3 \
  ; \
  make -j$(nproc); \
  make install;

# -------------------------------------------
# Final image
# -------------------------------------------
FROM node:${NODE_VERSION}

ENV MASTODON_VERSION_METADATA="!!!!!!REPLACE_VER_METADATA!!!!!!"
ENV SOURCE_COMMIT="!!!!!!REPLACE_SOURCE_COMMIT!!!!!!"
ENV MALLOC_CONF="narenas:2,background_thread:true,thp:never,dirty_decay_ms:1000,muzzy_decay_ms:0"
ARG UID="991"
ARG GID="991"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND="noninteractive" \
    PATH="${PATH}:/opt/ruby/bin:/opt/mastodon/bin" \
    RAILS_ENV="production" \
    NODE_ENV="production" \
    RAILS_SERVE_STATIC_FILES="true" \
    BIND="0.0.0.0" \
    # Optimize jemalloc 5.x performance
    MALLOC_CONF="narenas:2,background_thread:true,thp:never,dirty_decay_ms:1000,muzzy_decay_ms:0" \
    # Enable libvips, should not be changed
    MASTODON_USE_LIBVIPS=true \
    # Sidekiq will touch tmp/sidekiq_process_has_started_and_will_begin_processing_jobs to indicate it is ready. This can be used for a readiness check in Kubernetes
    MASTODON_SIDEKIQ_READY_FILENAME=sidekiq_process_has_started_and_will_begin_processing_jobs \
    # Apply Mastodon version information
    MASTODON_VERSION_METADATA="${MASTODON_VERSION_METADATA}" \
    SOURCE_COMMIT="${SOURCE_COMMIT}"

COPY --link --from=ruby /opt/ruby /opt/ruby

COPY --chown=mastodon:mastodon ./mastodon /opt/mastodon
COPY --chown=mastodon:mastodon --from=build /opt/mastodon /opt/mastodon

# Copy libvips components to layer
COPY --from=libvips /usr/local/libvips/bin /usr/local/bin
COPY --from=libvips /usr/local/libvips/lib /usr/local/lib
# Copy ffmpeg components to layer
COPY --from=ffmpeg /usr/local/ffmpeg/bin /usr/local/bin
COPY --from=ffmpeg /usr/local/ffmpeg/lib /usr/local/lib

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
        libidn12 \
        libyaml-0-2 \
        libvips42 \
        file \
        ca-certificates \
        tzdata \
        libreadline8 \
        tini \
        libexpat1 \
        libglib2.0-0t64 \
        libicu76 \
        libidn12 \
        libpq5 \
        libreadline8t64 \
        libssl3t64 \
        libyaml-0-2 \
        # libvips components
        libcgif0 \
        libexif12 \
        libheif1 \
        libhwy1t64 \
        libimagequant0 \
        libjpeg62-turbo \
        liblcms2-2 \
        libspng0 \
        libtiff6 \
        libwebp7 \
        libwebpdemux2 \
        libwebpmux3 \
        # ffmpeg components
        libdav1d7 \
        libmp3lame0 \
        libopencore-amrnb0 \
        libopencore-amrwb0 \
        libopus0 \
        libsnappy1v5 \
        libtheora0 \
        libvorbis0a \
        libvorbisenc2 \
        libvorbisfile3 \
        libvpx9 \
        libx264-164 \
        libx265-215 \
        ;

# Smoketest media processors
RUN \
  ldconfig; \
  vips -v; \
  ffmpeg -version; \
  ffprobe -version;

# Note: no, cleaning here since Debian does this automatically
# See the file /etc/apt/apt.conf.d/docker-clean within the Docker image's filesystem

# Precompile assets

# Set the run user
WORKDIR /opt/mastodon

RUN \
    corepack enable && \ 
    corepack prepare --activate; \
    yarn workspaces focus --all --production && \
    ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=precompile_placeholder \
    ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=precompile_placeholder \
    ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=precompile_placeholder \
    OTP_SECRET=precompile_placeholder \
    SECRET_KEY_BASE=precompile_placeholder \
    ./bin/rails assets:precompile

RUN \
    bundle exec bootsnap precompile --gemfile app/ lib/;

RUN \
    # Pre-create and chown system volume to Mastodon user
    mkdir -p /opt/mastodon/public/system && \
    chown mastodon:mastodon /opt/mastodon/public/system && \
    # Set Mastodon user as owner of tmp folder
    chown -R mastodon:mastodon /opt/mastodon

USER mastodon

# Set the work dir and the container entry point
EXPOSE 3000 4000
ENTRYPOINT ["/usr/bin/tini", "--"]
