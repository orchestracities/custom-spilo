# Spilo base image for postgis + timescale
FROM registry.opensource.zalan.do/acid/spilo-11:1.6-p1

# Configuring locales
ENV CRANKSHAFT_VERSION=0.8.1
ENV CARTODB_POSTGRESQL_VERSION=0.3.0
ENV DATASERVICES_VERSION=master
ENV DATAERVICESAPI_VERSION=0.35.1-server
ENV OBSERVATORY_VERSION=develop
ENV CARTODB_VERSION=v4.29.0
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /home/postgres

RUN tar xpJf /a.tar.xz -C / > /dev/null

# Define build packages

RUN BUILD_PACKAGES="software-properties-common python2.7 python-setuptools gcc-6 g++-6 git make pkg-config libpq-dev python2.7-dev build-essential libssl-dev libffi-dev libxml2-dev libxslt1-dev zlib1g-dev"

# Add libraries
RUN apt-get -y update \
  && apt-get -y --no-install-recommends install apt-utils
RUN apt-get -y --no-install-recommends install $BUILD_PACKAGES \
  && apt-get -y --no-install-recommends install gdal-bin libgdal-dev

RUN apt-get -y --no-install-recommends install libpython2.7-minimal libpython2.7-stdlib python2.7 python2.7-minimal git-man git liberror-perl binutils binutils-common binutils-x86-64-linux-gnu cpp cpp-6 cpp-7 dpkg-dev g++ g++-7 gcc gcc-6-base gcc-7 gcc-7-base gir1.2-glib-2.0 gir1.2-harfbuzz-0.0 git-man gpg gpgconf icu-devtools iso-codes libapt-inst2.0 libasan3 libasan4 libassuan0 libatomic1 libbinutils libc-dev-bin libc6-dev libcc1-0 libcilkrts5 libdbus-1-3 libdpkg-perl libelf1 liberror-perl libexpat1 libexpat1-dev libfreetype6 libgcc-6-dev libgcc-7-dev libgirepository-1.0-1 libglib2.0-0 libglib2.0-bin libglib2.0-data libglib2.0-dev libglib2.0-dev-bin libgomp1 libgraphite2-3 libgraphite2-dev libharfbuzz-dev libharfbuzz-gobject0 libharfbuzz-icu0 libharfbuzz0b libicu-dev libicu-le-hb-dev libicu-le-hb0 libiculx60 libisl19 libitm1 liblsan0 libmpc3 libmpx2 libpcre16-3 libpcre3-dev libpcre32-3 libpcrecpp0v5 libpng16-16 libpython-stdlib libpython2.7 libpython2.7-dev libquadmath0 libstdc++-6-dev libstdc++-7-dev libtsan0 libubsan0 linux-libc-dev patch python python-apt-common python-minimal python-pkg-resources python3-apt python3-dbus python3-gi python3-software-properties
RUN apt-get -y --no-install-recommends install postgresql-server-dev-11 postgresql-common
RUN apt-get -y --no-install-recommends install ruby2.5-dev 

# Add crankshaft
RUN curl https://bootstrap.pypa.io/get-pip.py | python && \
  pip install --user numpy && \
  git clone https://github.com/CartoDB/crankshaft.git && \
  cd crankshaft && \
  git checkout $CRANKSHAFT_VERSION && \
  PGUSER=postgres make install && \
  cd .. && \
  rm -rf crankshaft

# Add cartodb-postgresql
RUN git clone https://github.com/CartoDB/cartodb-postgresql.git && \
  cd cartodb-postgresql/ && \
  git checkout $CARTODB_POSTGRESQL_VERSION && \
  PGUSER=postgres make all install && \
  cd .. && \
  rm -rf cartodb-postgresql

# Add data-services
RUN git clone https://github.com/CartoDB/data-services.git && \
  cd data-services/geocoder/extension && \
  git checkout $DATASERVICES_VERSION && \
  PGUSER=postgres make all install && \
  cd .. && \
  rm -rf data-services

# Add data-services-api
RUN git clone https://github.com/CartoDB/dataservices-api.git && \
  cd dataservices-api/server/extension && \
  PGUSER=postgres make install && \
  cd ../../client && \
  PGUSER=postgres make install && \
  cd ../..  && \
  rm -rf dataservices-api

# Add observatory-extension
RUN git clone --recursive https://github.com/CartoDB/observatory-extension.git && \
  cd observatory-extension && \
  git checkout $OBSERVATORY_VERSION && \
  PGUSER=postgres make deploy && \
  cd .. && \
  rm -rf observatory-extension

# Add cartodb
RUN git clone --recursive git://github.com/CartoDB/cartodb.git && \
  cd cartodb && \
  git checkout $CARTODB_VERSION && \
  cd lib/sql && \
  PGUSER=postgres make install && \
  cd ../../.. && \
  rm -rf cartodb

# Clean up
RUN apt-get purge -y ${BUILD_PACKAGES} \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
            /var/cache/debconf/* \
            /builddeps \
            /usr/share/doc \
            /usr/share/man \
            /usr/share/info \
            /usr/share/locale/?? \
            /usr/share/locale/??_?? \
            /usr/share/postgresql/*/man \
            /etc/pgbouncer/* \
            /usr/lib/postgresql/*/bin/createdb \
            /usr/lib/postgresql/*/bin/createlang \
            /usr/lib/postgresql/*/bin/createuser \
            /usr/lib/postgresql/*/bin/dropdb \
            /usr/lib/postgresql/*/bin/droplang \
            /usr/lib/postgresql/*/bin/dropuser \
            /usr/lib/postgresql/*/bin/pg_recvlogical \
            /usr/lib/postgresql/*/bin/pg_standby \
            /usr/lib/postgresql/*/bin/pltcl_* \
    && rm -rf /a.tar.xz \
    && find /var/log -type f -exec truncate --size 0 {} \;

# Fix access from localhost
# RUN sed -i 's+host    all             all                127.0.0.1/32       md5+host    all             all                127.0.0.1/32       trust+g' /home/postgres/postgres.yml \
#  && sed -i 's+host    all             all                ::1/128            md5+host    all             all                ::1/128            trust+g' /home/postgres/postgres.yml

