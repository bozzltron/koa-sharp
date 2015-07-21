FROM heroku/cedar:14

# Install dependencies
RUN \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
  automake build-essential curl \
  gobject-introspection gtk-doc-tools libglib2.0-dev libjpeg-turbo8-dev libpng12-dev libwebp-dev libtiff5-dev libexif-dev libxml2-dev swig libmagickwand-dev

# Build libvips
RUN mkdir -p /app/heroku/libvips
WORKDIR /app/heroku/libvips
ENV LIBVIPS_VERSION_MAJOR 8
ENV LIBVIPS_VERSION_MINOR 0
ENV LIBVIPS_VERSION_PATCH 2
ENV LIBVIPS_VERSION $LIBVIPS_VERSION_MAJOR.$LIBVIPS_VERSION_MINOR.$LIBVIPS_VERSION_PATCH
RUN \
  curl -O http://www.vips.ecs.soton.ac.uk/supported/$LIBVIPS_VERSION_MAJOR.$LIBVIPS_VERSION_MINOR/vips-$LIBVIPS_VERSION.tar.gz && \
  tar zvxf vips-$LIBVIPS_VERSION.tar.gz && \
  cd vips-$LIBVIPS_VERSION && \
  ./configure --enable-debug=no --without-python --without-orc --without-fftw --without-gsf $1 && \
  make && \
  make install && \
  ldconfig

# Install NodeJS
RUN mkdir -p /app/heroku/node

# Setup node js
ENV NODE_ENGINE 0.12.3
RUN curl -s https://s3pository.heroku.com/node/v$NODE_ENGINE/node-v$NODE_ENGINE-linux-x64.tar.gz | tar --strip-components=1 -xz -C /app/heroku/node
ENV PATH /app/heroku/node/bin:$PATH

# Configure path
RUN mkdir -p /app/.profile.d
RUN echo "export PATH=\"/app/src/node_modules/sharp/build/Release:/app/heroku/node/bin:/app/bin:/app/src/node_modules/.bin:\$PATH\"" > /app/.profile.d/nodejs.sh
RUN echo "cd /app/src" >> /app/.profile.d/nodejs.sh

# Pre compile node modules
WORKDIR /app/src
RUN npm install sharp

# Clean up
WORKDIR /
RUN apt-get remove -y curl automake && \
    apt-get autoremove -y && \
    apt-get autoclean && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV PORT 3000
EXPOSE 3000

WORKDIR /app/src

ONBUILD COPY . /app/src
ONBUILD RUN npm install -d
