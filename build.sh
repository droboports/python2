#!/usr/bin/env bash

### bash best practices ###
# exit on error code
set -o errexit
# exit on unset variable
set -o nounset
# return error of last failed command in pipe
set -o pipefail
# expand aliases
shopt -s expand_aliases
# print trace
set -o xtrace

### logfile ###
timestamp="$(date +%Y-%m-%d_%H-%M-%S)"
logfile="logfile_${timestamp}.txt"
echo "${0} ${@}" > "${logfile}"
# save stdout to logfile
exec 1> >(tee -a "${logfile}")
# redirect errors to stdout
exec 2> >(tee -a "${logfile}" >&2)

### environment variables ###
source crosscompile.sh
export NAME="python2"
export DEST="/mnt/DroboFS/Shares/DroboApps/${NAME}"
export DEPS="/mnt/DroboFS/Shares/DroboApps/${NAME}deps"
export CFLAGS="$CFLAGS -Os -fPIC"
export CXXFLAGS="$CXXFLAGS $CFLAGS"
export CPPFLAGS="-I${DEPS}/include"
export LDFLAGS="${LDFLAGS:-} -Wl,-rpath,${DEST}/lib -L${DEST}/lib"
export PKG_CONFIG_LIBDIR="${DEPS}/lib/pkgconfig"
alias make="make -j8 V=1 VERBOSE=1"

# $1: file
# $2: url
# $3: folder
_download_tgz() {
  [[ ! -f "download/${1}" ]] && wget -O "download/${1}" "${2}"
  [[ -d "target/${3}" ]] && rm -v -fr "target/${3}"
  [[ ! -d "target/${3}" ]] && tar -zxvf "download/${1}" -C target
}

# $1: folder
# $2: url
_download_git() {
  [[ -d "target/${1}" ]] && rm -v -fr "target/${1}"
  [[ ! -d "target/${1}" ]] && git clone "${2}" "target/${1}"
}

### ZLIB ###
_build_zlib() {
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd target/"${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib"
make
make install
rm -v "${DEST}/lib"/*.a
popd
}

### BZIP ###
_build_bzip() {
local VERSION="1.0.6"
local FOLDER="bzip2-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://bzip.org/1.0.6/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd target/"${FOLDER}"
sed -i -e "s/all: libbz2.a bzip2 bzip2recover test/all: libbz2.a bzip2 bzip2recover/" Makefile
make -f Makefile-libbz2_so CC=${CC} AR=${AR} RANLIB=${RANLIB} CFLAGS="${CFLAGS} -fpic -fPIC -Wall -D_FILE_OFFSET_BITS=64"
ln -s libbz2.so.1.0.6 libbz2.so
cp -avR *.h "${DEPS}/include/"
cp -avR *.so* "${DEST}/lib/"
popd
}

### OPENSSL ###
_build_openssl() {
local OPENSSL_VERSION="1.0.1i"
local OPENSSL_FOLDER="openssl-${OPENSSL_VERSION}"
local OPENSSL_FILE="${OPENSSL_FOLDER}.tar.gz"
local OPENSSL_URL="http://www.openssl.org/source/${OPENSSL_FILE}"

_download_tgz "${OPENSSL_FILE}" "${OPENSSL_URL}" "${OPENSSL_FOLDER}"
pushd target/"${OPENSSL_FOLDER}"
./Configure --prefix="${DEPS}" \
  --openssldir="${DEST}/etc/ssl" \
  --with-zlib-include="${DEPS}/include" \
  --with-zlib-lib="${DEPS}/lib" \
  shared zlib-dynamic threads linux-armv4 -DL_ENDIAN ${CFLAGS} ${LDFLAGS}
sed -i -e "s/-O3//g" Makefile
make -j1
make install_sw
mkdir -p "${DEST}"/libexec
cp -avR "${DEPS}/bin/openssl" "${DEST}/libexec/"
cp -avR "${DEPS}/lib"/* "${DEST}/lib/"
rm -fvr "${DEPS}/lib"
rm -fv "${DEST}/lib"/*.a
sed -i -e "s|^exec_prefix=.*|exec_prefix=${DEST}|g" "${DEST}"/lib/pkgconfig/openssl.pc
popd
}

### NCURSES ###
_build_ncurses() {
local VERSION="5.9"
local FOLDER="ncurses-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://ftp.gnu.org/gnu/ncurses/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd target/"${FOLDER}"
./configure --host=arm-none-linux-gnueabi --prefix="${DEPS}" --libdir="${DEST}/lib" --datadir="${DEST}/share" --with-shared --enable-rpath
make
make install
rm -v "${DEST}/lib"/*.a
popd
}

### SQLITE ###
_build_sqlite() {
local VERSION="3080600"
local FOLDER="sqlite-autoconf-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://sqlite.org/2014/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd target/"${FOLDER}"
./configure --host=arm-none-linux-gnueabi --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static
make
make install
popd
}

### PYTHON2 ###
_build_python() {
local VERSION="2.7.8"
local FOLDER="Python-${VERSION}"
local FILE="${FOLDER}.tgz"
local URL="https://www.python.org/ftp/python/2.7.8/${FILE}"
export _PYTHON_HOST_PLATFORM="linux-armv7l"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"

# compile native versions of python and Parser/pgen
[[ -d "target/${FOLDER}-native" ]] && rm -v -fr "target/${FOLDER}-native"
cp -avR "target/${FOLDER}" "target/${FOLDER}-native"
#sudo apt-get install zlib1g-dev
( source uncrosscompile.sh
  pushd target/"${FOLDER}-native"
  ./configure
  make )

pushd target/"${FOLDER}"
cp -avR "../${FOLDER}-native/python" hostpython
./configure --host=arm-none-linux-gnueabi --build="$(uname -p)" --prefix="${DEST}" --enable-shared PYTHON_FOR_BUILD="${PWD}/hostpython" ac_cv_have_long_long_format=yes ac_cv_buggy_getaddrinfo=no ac_cv_file__dev_ptmx=yes ac_cv_file__dev_ptc=no CPPFLAGS="${CPPFLAGS} -I${DEPS}/include/ncurses"
make || true
cp -v "../${FOLDER}-native/Parser/pgen" Parser/pgen
make
make -j1 install PYTHON_FOR_BUILD="${PWD}/../${FOLDER}-native/python"
popd
}

### BUILD ###
_build() {
  _build_zlib
  _build_bzip
  _build_openssl
  _build_ncurses
  _build_sqlite
  _build_python
  _package
}

_create_tgz() {
  local appname="$(basename ${PWD})"
  local appfile="${PWD}/${appname}.tgz"

  if [[ -f "${appfile}" ]]; then
    rm -v "${appfile}"
  fi

  pushd "${DEST}"
  tar --verbose --create --numeric-owner --owner=0 --group=0 --gzip --file "${appfile}" *
  popd
}

_package() {
  cp -v -aR src/dest/* "${DEST}"/
  find "${DEST}" -name "._*" -print -delete
  _create_tgz
}

_clean() {
  rm -v -fr "${DEPS}"
  rm -v -fr "${DEST}"
  rm -v -fr target/*
}

_dist_clean() {
  _clean
  rm -v -f logfile*
  rm -v -fr download/*
}

case "${1:-}" in
  clean)     _clean ;;
  distclean) _dist_clean ;;
  package)   _package ;;
  "")        _build ;;
  *)         _build_${1} ;;
esac
