FROM heroku/cedar:14

# Install dependencies
RUN \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
  automake build-essential curl \
  gobject-introspection gtk-doc-tools libglib2.0-dev libjpeg-turbo8-dev libpng12-dev libwebp-dev libtiff5-dev libexif-dev libxml2-dev swig libmagickwand-dev


# Build libvips
WORKDIR /tmp
ENV LIBVIPS_VERSION_MAJOR 7
ENV LIBVIPS_VERSION_MINOR 42
ENV LIBVIPS_VERSION_PATCH 3
ENV LIBVIPS_VERSION $LIBVIPS_VERSION_MAJOR.$LIBVIPS_VERSION_MINOR.$LIBVIPS_VERSION_PATCH
RUN \
  curl -O http://www.vips.ecs.soton.ac.uk/supported/$LIBVIPS_VERSION_MAJOR.$LIBVIPS_VERSION_MINOR/vips-$LIBVIPS_VERSION.tar.gz && \
  tar zvxf vips-$LIBVIPS_VERSION.tar.gz && \
  cd vips-$LIBVIPS_VERSION && \
  ./configure --enable-debug=no --enable-docs=no --without-python --without-orc --without-fftw --without-gsf $1 && \
  make && \
  make install && \
  ldconfig

# Environment vars
ENV NODE_ENGINE 0.12.3
RUN mkdir -p /app/heroku/node

# Setup node js
RUN curl -s https://s3pository.heroku.com/node/v$NODE_ENGINE/node-v$NODE_ENGINE-linux-x64.tar.gz | tar --strip-components=1 -xz -C /app/heroku/node
ENV PATH /app/heroku/node/bin:$PATH

# cleanup
RUN apt-get remove -y automake build-essential && \
   apt-get autoremove -y && \
   apt-get autoclean && \
   apt-get clean && \
   rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /app/.profile.d
RUN echo "export PATH=\"/app/src/phantomjs/bin:/app/heroku/node/bin:/app/bin:/app/src/node_modules/.bin:\$PATH\"" > /app/.profile.d/nodejs.sh
RUN echo "cd /app/src" >> /app/.profile.d/nodejs.sh
WORKDIR /app/src

RUN useradd -d /app -m app
USER app
WORKDIR /app

ENV HOME /app
ENV PORT 3000

#RUN mkdir -p /app/.profile.d

WORKDIR /app/src

ONBUILD COPY . /app/src
ONBUILD EXPOSE 3000
