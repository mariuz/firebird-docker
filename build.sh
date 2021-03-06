#!/bin/bash
set -e
CPUC=$(awk '/^processor/{n+=1}END{print n}' /proc/cpuinfo)

apt-get update
apt-get install -qy --no-install-recommends \
    libatomic1 \
    libicu63 \
    libncurses6 \
    libtomcrypt1 \
    libtommath1
apt-get install -qy --no-install-recommends \
    ca-certificates \
    curl \
    g++ \
    gcc \
    libicu-dev \
    libncurses-dev \
    libtomcrypt-dev \
    libtommath-dev \
    make \
    unzip \
    xz-utils \
    zlib1g-dev
if [ -d "/home/fixes/pre_fetch/$(dpkg --print-architecture)" ]; then
    find "/home/fixes/pre_fetch/$(dpkg --print-architecture)" -type f -exec '{}' \;
fi
if [ -d "/home/fixes/pre_fetch/all" ]; then
    find "/home/fixes/pre_fetch/all" -type f -exec '{}' \;
fi
mkdir -p /home/firebird
cd /home/firebird
curl -L -o firebird-source.tar.xz -L \
    "${FBURL}"
tar --strip=1 -xf firebird-source.tar.xz
if [ -d "/home/fixes/pre_build/$(dpkg --print-architecture)" ]; then
    find "/home/fixes/pre_build/$(dpkg --print-architecture)" -type f -exec '{}' \;
fi
if [ -d "/home/fixes/pre_build/all" ]; then
    find "/home/fixes/pre_build/all" -type f -exec '{}' \;
fi
./configure \
    --prefix=${PREFIX}/ --with-fbbin=${PREFIX}/bin/ --with-fbsbin=${PREFIX}/bin/ --with-fblib=${PREFIX}/lib/ \
    --with-fbinclude=${PREFIX}/include/ --with-fbdoc=${PREFIX}/doc/ --with-fbudf=${PREFIX}/UDF/ \
    --with-fbsample=${PREFIX}/examples/ --with-fbsample-db=${PREFIX}/examples/empbuild/ --with-fbhelp=${PREFIX}/help/ \
    --with-fbintl=${PREFIX}/intl/ --with-fbmisc=${PREFIX}/misc/ --with-fbplugins=${PREFIX}/ \
    --with-fbconf="${VOLUME}/etc/" --with-fbmsg=${PREFIX}/ \
    --with-fblog="${VOLUME}/log/" --with-fbglock=/var/firebird/run/ \
    --with-fbsecure-db="${VOLUME}/system"
make -j${CPUC}
make silent_install
cd /
rm -rf /home/firebird
if [ -d "/home/fixes/post_build/$(dpkg --print-architecture)" ]; then
    find "/home/fixes/post_build/$(dpkg --print-architecture)" -type f -exec '{}' \;
fi
if [ -d "/home/fixes/post_build/all" ]; then
    find "/home/fixes/post_build/all" -type f -exec '{}' \;
fi
find ${PREFIX} -name .debug -prune -exec rm -rf {} \;
apt-get purge -qy --auto-remove \
    ca-certificates \
    curl \
    g++ \
    gcc \
    libicu-dev \
    libncurses5-dev \
    libtommath-dev \
    make \
    unzip \
    xz-utils \
    zlib1g-dev
rm -rf /var/lib/apt/lists/*

mkdir -p "${PREFIX}/skel/"

# This allows us to initialize a random value for sysdba password
mv "${VOLUME}/system/security4.fdb" "${PREFIX}/skel/security4.fdb"

# Cleaning up to restrict access to specific path and allow changing that path easily to
# something standard. See github issue https://github.com/jacobalberty/firebird-docker/issues/12
sed -i 's/^#DatabaseAccess/DatabaseAccess/g' "${VOLUME}/etc/firebird.conf"
sed -i "s~^\(DatabaseAccess\s*=\s*\).*$~\1Restrict ${DBPATH}~" "${VOLUME}/etc/firebird.conf"

mv "${VOLUME}/etc" "${PREFIX}/skel"
