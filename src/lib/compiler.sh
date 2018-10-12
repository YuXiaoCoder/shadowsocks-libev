#!/usr/bin/env bash

SCRIPT=$(readlink -f $0)
CWD=$(dirname ${SCRIPT})
BASE=$(dirname ${CWD})

PCRE_VERSION="8.42"
MBEDTLS_VERSION="2.12.0"
SODIUM_VERSION="2018-09-09"
CARES_VERSION="1.14.0"
LIBEV_VERSION="4.24"
SS_VERSION="3.2.0"

if [[ "$(expr $(lsb_release -rs) \>\= '18.04')" == "1" ]]; then
    apt install -y gcc g++ make automake autoconf libtool asciidoc gettext xmlto
else
    echo "Unsupported operating system."
    exit 1
fi

if [[ ! -f "${CWD}/src/pcre-${PCRE_VERSION}.tar.bz2" ]]; then
    wget https://ftp.pcre.org/pub/pcre/pcre-${PCRE_VERSION}.tar.bz2 -P ${CWD}/src
fi

if [[ ! -f "${CWD}/src/mbedtls-${MBEDTLS_VERSION}-gpl.tgz" ]]; then
    wget https://tls.mbed.org/download/mbedtls-${MBEDTLS_VERSION}-gpl.tgz -P ${CWD}/src
fi

if [[ ! -f "${CWD}/src/libsodium-stable-${SODIUM_VERSION}.tar.gz" ]]; then
    wget https://download.libsodium.org/libsodium/releases/libsodium-stable-${SODIUM_VERSION}.tar.gz -P ${CWD}/src
fi

if [[ ! -f "${CWD}/src/c-ares-${CARES_VERSION}.tar.gz" ]]; then
    wget https://c-ares.haxx.se/download/c-ares-${CARES_VERSION}.tar.gz -P ${CWD}/src
fi

if [[ ! -f "${CWD}/src/libev-${LIBEV_VERSION}.tar.gz" ]]; then
    wget http://dist.schmorp.de/libev/libev-${LIBEV_VERSION}.tar.gz -P ${CWD}/src
fi

if [[ ! -f "${CWD}/src/shadowsocks-libev-${SS_VERSION}.tar.gz" ]]; then
    wget https://github.com/shadowsocks/shadowsocks-libev/releases/download/v${SS_VERSION}/shadowsocks-libev-${SS_VERSION}.tar.gz -P ${CWD}/src
fi

rm -rf /usr/local/ss-server
mkdir -p /usr/local/ss-server/src
tar -jxf ${CWD}/src/pcre-${PCRE_VERSION}.tar.bz2 -C /usr/local/ss-server/src
tar -zxf ${CWD}/src/mbedtls-${MBEDTLS_VERSION}-gpl.tgz -C /usr/local/ss-server/src
tar -zxf ${CWD}/src/libsodium-stable-${SODIUM_VERSION}.tar.gz -C /usr/local/ss-server/src
tar -zxf ${CWD}/src/c-ares-${CARES_VERSION}.tar.gz -C /usr/local/ss-server/src
tar -zxf ${CWD}/src/libev-${LIBEV_VERSION}.tar.gz -C /usr/local/ss-server/src
tar -zxf ${CWD}/src/shadowsocks-libev-${SS_VERSION}.tar.gz -C /usr/local/ss-server/src

mkdir -p /usr/local/ss-server/output
pushd /usr/local/ss-server/src/pcre-${PCRE_VERSION}
./configure --prefix=/usr/local/ss-server/output/pcre
make -j 4 && make install
popd

pushd /usr/local/ss-server/src/mbedtls-${MBEDTLS_VERSION}
make SHARED=1 CFLAGS=-fPIC -j 4 && make install DESTDIR=/usr/local/ss-server/output/mbedtls
popd

pushd /usr/local/ss-server/src/libsodium-stable
./configure --prefix=/usr/local/ss-server/output/sodium
make -j 4 && make install
popd

pushd /usr/local/ss-server/src/c-ares-${CARES_VERSION}
./configure --prefix=/usr/local/ss-server/output/c-ares
make -j 4 && make install
popd

pushd /usr/local/ss-server/src/libev-${LIBEV_VERSION}
./configure --prefix=/usr/local/ss-server/output/libev
make -j 4 && make install
popd

pushd /usr/local/ss-server/src/shadowsocks-libev-${SS_VERSION}
./configure \
--prefix /usr/local/ss-server/output/shadowsocks-libev \
--with-pcre=/usr/local/ss-server/output/pcre \
--with-mbedtls=/usr/local/ss-server/output/mbedtls \
--with-sodium=/usr/local/ss-server/output/sodium \
--with-cares=/usr/local/ss-server/output/c-ares \
--with-ev=/usr/local/ss-server/output/libev
make -j 4 && make install
popd

rm -rf ${CWD}/{pcre,mbedtls,sodium,c-ares,libev}
rm -rf ${BASE}/bin/{ss-local,ss-server}
cp -r /usr/local/ss-server/output/pcre/lib ${CWD}/pcre
cp -r /usr/local/ss-server/output/mbedtls/lib ${CWD}/mbedtls
cp -r /usr/local/ss-server/output/sodium/lib ${CWD}/sodium
cp -r /usr/local/ss-server/output/c-ares/lib ${CWD}/c-ares
cp -r /usr/local/ss-server/output/libev/lib ${CWD}/libev
cp -r /usr/local/ss-server/output/shadowsocks-libev/bin/{ss-local,ss-server} ${BASE}/bin

find ${CWD}/pcre \( -type f -o -type l \) ! -name 'libpcre.so*' -exec rm -f {} \;
find ${CWD}/mbedtls \( -type f -o -type l \) ! -name 'libmbedcrypto.so*' -exec rm -f {} \;
find ${CWD}/sodium \( -type f -o -type l \) ! -name 'libsodium.so*' -exec rm -f {} \;
find ${CWD}/c-ares \( -type f -o -type l \) ! -name 'libcares.so*' -exec rm -f {} \;
find ${CWD}/libev \( -type f -o -type l \) ! -name 'libev.so*' -exec rm -f {} \;

LIB_NAMES=('pcre' 'mbedtls' 'sodium' 'c-ares' 'libev')

for LIB_NAME in ${LIB_NAMES[@]}
do
    if [[ -d "${CWD}/${LIB_NAME}/pkgconfig" ]]; then
        rm -rf "${CWD}/${LIB_NAME}/pkgconfig"
    fi
done


