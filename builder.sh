#!/usr/bin/env bash

SCRIPT=$(readlink -f $0)
CWD=$(dirname ${SCRIPT})

PKG_NAME="shadowsocks-libev"
PKG_VER="3.2.0"
PKG_HOME="${CWD}/src"
DEB_HOME="${CWD}/deb"
rm -rf "${DEB_HOME}"

mkdir -p ${DEB_HOME}/usr/local/ss-server/lib

# Init DEB_HOME
cp -r ${PKG_HOME}/DEBIAN ${DEB_HOME}
cp -r ${PKG_HOME}/lib/{pcre,mbedtls,sodium,c-ares,libev} ${DEB_HOME}/usr/local/ss-server/lib
cp -r ${PKG_HOME}/conf ${DEB_HOME}/usr/local/ss-server
PKG_SIZE=$(du -sx --exclude 'DEBIAN' ${DEB_HOME} | awk '{print $1}')
sed -i "s/PKG_NAME/${PKG_NAME}/g" ${DEB_HOME}/DEBIAN/control
sed -i "s/PKG_VER/${PKG_VER}/g" ${DEB_HOME}/DEBIAN/control
sed -i "s/PKG_SIZE/${PKG_SIZE}/g" ${DEB_HOME}/DEBIAN/control

# make package
OUTPUT="${CWD}/output"
mkdir -p ${OUTPUT}
rm -f "${OUTPUT}/shadowsocks-libev-${PKG_VER}.deb"
dpkg -b ${DEB_HOME} "${OUTPUT}/${PKG_NAME}-${PKG_VER}.deb" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "make package ${PKG_NAME} failed"
    exit 1
fi
rm -rf ${DEB_HOME}

exit 0
