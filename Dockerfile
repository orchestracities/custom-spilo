# Spilo base image for postgis + timescale
ARG PGVERSION=11
ARG DEMO=false

FROM registry.opensource.zalan.do/acid/spilo-11:1.6-p1 as builder

# Configuring locales
ENV DEBIAN_FRONTEND=noninteractive
ENV POSTGRES_USER=postgres

## UNPACK
RUN tar xpJf /a.tar.xz -C / > /dev/null

WORKDIR /home/postgres

# Define build packages

# Add libraries
RUN apt-get -y update

RUN apt-get -y --no-install-recommends install libpython2.7-minimal libpython2.7-stdlib python2.7 python2.7-minimal git-man git liberror-perl binutils binutils-common binutils-x86-64-linux-gnu cpp cpp-6 cpp-7 dpkg-dev g++ g++-7 gcc gcc-6-base gcc-7 gcc-7-base gir1.2-glib-2.0 gir1.2-harfbuzz-0.0 git-man gpg gpgconf icu-devtools iso-codes libapt-inst2.0 libasan3 libasan4 libassuan0 libatomic1 libbinutils libc-dev-bin libc6-dev libcc1-0 libcilkrts5 libdbus-1-3 libdpkg-perl libelf1 liberror-perl libexpat1 libexpat1-dev libfreetype6 libgcc-6-dev libgcc-7-dev libgirepository-1.0-1 libglib2.0-0 libglib2.0-bin libglib2.0-data libglib2.0-dev libglib2.0-dev-bin libgomp1 libgraphite2-3 libgraphite2-dev libharfbuzz-dev libharfbuzz-gobject0 libharfbuzz-icu0 libharfbuzz0b libicu-dev libicu-le-hb-dev libicu-le-hb0 libiculx60 libisl19 libitm1 liblsan0 libmpc3 libmpx2 libpcre16-3 libpcre3-dev libpcre32-3 libpcrecpp0v5 libpng16-16 libpython-stdlib libpython2.7 libpython2.7-dev libquadmath0 libstdc++-6-dev libstdc++-7-dev libtsan0 libubsan0 linux-libc-dev patch python python-apt-common python-minimal python-pkg-resources python3-apt python3-dbus python3-gi python3-software-properties software-properties-common python2.7 python-setuptools gcc-6 g++-6 git make pkg-config libpq-dev python2.7-dev build-essential libssl-dev libffi-dev libxml2-dev libxslt1-dev zlib1g-dev postgresql-server-dev-11 postgresql-common gdal-bin libgdal-dev
RUN apt-get -y --no-install-recommends install ruby2.5-dev postgresql-plpython-11

#carto version

# https://github.com/CartoDB/cartodb-postgresql version
ENV CARTODB_POSTGRESQL_VERSION=0.28.1
# https://github.com/CartoDB/crankshaft version
ENV CRANKSHAFT_VERSION=master
# https://github.com/CartoDB/data-services
ENV DATASERVICES_VERSION=0.0.2
# https://github.com/CartoDB/dataservices-api
ENV DATASERVICESAPI_VERSION=0.35.1-server
# https://github.com/CartoDB/observatory-extension
ENV OBSERVATORY_VERSION=1.9.0

# CartoDB main postgresql extensions
RUN git clone \
  --branch ${CARTODB_POSTGRESQL_VERSION} \
  --depth 1 git://github.com/CartoDB/cartodb-postgresql.git \
  && cd cartodb-postgresql \
  && make all install \
  && cd /home/postgres  \
  && rm -rf cartodb-postgresql

# Crankshaft extensions
RUN curl https://bootstrap.pypa.io/get-pip.py | python && \
  pip install --user numpy && \
  pip install --user scipy && \
  git clone \
    --branch ${CRANKSHAFT_VERSION} \
    --depth 1 git://github.com/CartoDB/crankshaft.git \
  && cd crankshaft \
  && make install \
  # Numpy gets upgraded after scikit-learn is installed
  # make sure scikit-learn is compatible with currently installed numpy, by reinstalling
  && pip install --force-reinstall --no-cache-dir scikit-learn==0.14.1 \
  && cd /home/postgres \
  && rm -rf crankshaft

# Add Dataservices / geocoder
RUN git clone \
  --branch ${DATASERVICES_VERSION} \
  --depth 1 git://github.com/CartoDB/data-services.git \
  && cd data-services/geocoder/extension \
  && PGUSER=$POSTGRES_USER make all install \
  && cd /home/postgres \
  && rm -rf data-services

# Add data-services-api
RUN git clone \
  --branch ${DATASERVICESAPI_VERSION} \
  --depth 1 git://github.com/CartoDB/dataservices-api.git \
  && cd dataservices-api/server/extension \
  && PGUSER=$POSTGRES_USER make install \
  && cd ../lib/python/cartodb_services \
  && pip install -r requirements.txt && pip install . \
  && cd ../../../../client \
  && PGUSER=$POSTGRES_USER make install \
  && cd /home/postgres \
  && rm -rf dataservices-api

# Add observatory-extension
RUN git clone \
  --branch ${OBSERVATORY_VERSION} \
  --depth 1 git://github.com/CartoDB/observatory-extension.git \
  && cd observatory-extension \
  && PGUSER=$POSTGRES_USER make deploy \
  && cd /home/postgres \
  && rm -rf observatory-extension


ENV BUILD_PACKAGES="git-man git liberror-perl binutils binutils-common binutils-x86-64-linux-gnu"

RUN apt-get purge -y ${BUILD_PACKAGES}

ENV BUILD_PACKAGES="cpp cpp-6 cpp-7 dpkg-dev g++ g++-7 gcc gcc-6-base gcc-7 gcc-7-base gir1.2-glib-2.0 gir1.2-harfbuzz-0.0 git-man gpg gpgconf libbinutils libc-dev-bin libc6-dev libexpat1-dev"

RUN apt-get purge -y ${BUILD_PACKAGES}

ENV BUILD_PACKAGES="libfreetype6 libgcc-6-dev libgcc-7-dev libglib2.0-dev libglib2.0-dev-bin libgraphite2-dev libharfbuzz-dev libicu-dev libicu-le-hb-dev libpcre3-dev libpython2.7-dev libstdc++-6-dev"

RUN apt-get purge -y ${BUILD_PACKAGES}

ENV BUILD_PACKAGES="libstdc++-7-dev linux-libc-dev patch software-properties-common python2.7 gcc-6 g++-6 git make pkg-config libpq-dev python2.7-dev build-essential libssl-dev libffi-dev libxml2-dev libxslt1-dev zlib1g-dev postgresql-server-dev-11 libgdal-dev ruby2.5-dev"

RUN apt-get purge -y ${BUILD_PACKAGES}

#RUN apt-get -y --no-install-recommends install python3 postgresql-plpython-11
# Clean up
RUN apt-get autoremove -y \
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

ARG COMPRESS=false

WORKDIR /

RUN set -ex \
    && if [ "$COMPRESS" = "true" ]; then \
        apt-get update \
        && apt-get install -y busybox xz-utils \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /var/cache/debconf/* /usr/share/doc /usr/share/man /etc/rc?.d /etc/systemd \
        && ln -snf busybox /bin/sh \
        && files="/bin/sh" \
        && libs="$(ldd $files | awk '{print $3;}' | grep '^/' | sort -u) /lib/x86_64-linux-gnu/ld-linux-x86-64.so.* /lib/x86_64-linux-gnu/libnsl.so.* /lib/x86_64-linux-gnu/libnss_compat.so.*" \
        && (echo /var/run $files $libs | tr ' ' '\n' && realpath $files $libs) | sort -u | sed 's/^\///' > /exclude \
        && find /etc/alternatives -xtype l -delete \
        && save_dirs="usr lib var bin sbin etc/ssl etc/init.d etc/alternatives etc/apt" \
        && XZ_OPT=-e9v tar -X /exclude -cpJf a.tar.xz $save_dirs \
        && rm -fr /usr/local/lib/python* \
        && /bin/busybox sh -c "(find $save_dirs -not -type d && cat /exclude /exclude && echo exclude) | sort | uniq -u | xargs /bin/busybox rm" \
        && /bin/busybox --install -s \
        && /bin/busybox sh -c "find $save_dirs -type d -depth -exec rmdir -p {} \; 2> /dev/null"; \
    fi

FROM scratch
COPY --from=builder / /

LABEL maintainer="Martel Innovate"

ARG PGVERSION
ARG DEMO

EXPOSE 5432 8008 8080

ENV LC_ALL=en_US.utf-8 \
    PATH=$PATH:/usr/lib/postgresql/$PGVERSION/bin \
    PGHOME=/home/postgres \
    DEMO=$DEMO

ENV WALE_ENV_DIR=$PGHOME/etc/wal-e.d/env \
    PGROOT=$PGHOME/pgdata/pgroot \
    LOG_ENV_DIR=$PGHOME/etc/log.d/env

ENV PGDATA=$PGROOT/data \
    PGLOG=$PGROOT/pg_log

WORKDIR $PGHOME

CMD ["/bin/sh", "/launch.sh"]
