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
make -f Makefile-libbz2_so CC="${CC}" AR="${AR}" RANLIB="${RANLIB}" CFLAGS="${CFLAGS} -fpic -fPIC -Wall -D_FILE_OFFSET_BITS=64"
ln -s libbz2.so.1.0.6 libbz2.so
cp -avR *.h "${DEPS}/include/"
cp -avR *.so* "${DEST}/lib/"
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.1i"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://www.openssl.org/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd target/"${FOLDER}"
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

### BDB ###
_build_bdb() {
local VERSION="5.3.28"
local FOLDER="db-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://download.oracle.com/berkeley-db/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}/build_unix"
../dist/configure --host=arm-none-linux-gnueabi --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static --enable-compat185 --enable-dbm
make
make install
popd
}

### LIBFFI ###
_build_libffi() {
local VERSION="3.1"
local FOLDER="libffi-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="ftp://sourceware.org/pub/libffi/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd target/"${FOLDER}"
./configure --host=arm-none-linux-gnueabi --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static
make
make install
mkdir -vp "${DEPS}/include/"
cp -v "${DEST}/lib/${FOLDER}/include"/* "${DEPS}/include/"
popd
}

### EXPAT ###
_build_expat() {
local VERSION="2.1.0"
local FOLDER="expat-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://switch.dl.sourceforge.net/project/expat/expat/2.1.0/${FILE}"

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

_download_tgz "${FILE}" "${URL}" "${FOLDER}"

[[ -d target/"${FOLDER}-native" ]] && rm -fvR target/"${FOLDER}-native"
cp -avR target/"${FOLDER}" target/"${FOLDER}-native"
( source uncrosscompile.sh
  pushd target/"${FOLDER}-native"
  ./configure
  make )

pushd target/"${FOLDER}"
export _PYTHON_HOST_PLATFORM="linux-armv7l"
rm -fvR Modules/_ctypes/libffi*
./configure --host=arm-none-linux-gnueabi --build="$(uname -p)" --prefix="${DEST}" --enable-shared --enable-ipv6 --enable-unicode --with-system-ffi --with-system-expat --with-dbmliborder=bdb:gdbm:ndbm \
  PYTHON_FOR_BUILD="_PYTHON_PROJECT_BASE=${PWD} _PYTHON_HOST_PLATFORM=${_PYTHON_HOST_PLATFORM} PYTHONPATH=${PWD}/build/lib.${_PYTHON_HOST_PLATFORM}-2.7:${PWD}/Lib:${PWD}/Lib/plat-linux2 ${PWD}/../${FOLDER}-native/python" \
  CPPFLAGS="${CPPFLAGS} -I${DEPS}/include/ncurses" LDFLAGS="${LDFLAGS} -L${PWD}"\
  ac_cv_have_long_long_format=yes ac_cv_buggy_getaddrinfo=no ac_cv_file__dev_ptmx=yes ac_cv_file__dev_ptc=no
make || true
cp -v "../${FOLDER}-native/Parser/pgen" Parser/pgen
make
cp -av "${PWD}/build/lib.${_PYTHON_HOST_PLATFORM}-2.7/"_sysconfigdata.* "${PWD}/build/"
make install PYTHON_FOR_BUILD="_PYTHON_PROJECT_BASE=${PWD} _PYTHON_HOST_PLATFORM=${_PYTHON_HOST_PLATFORM} PYTHONPATH=${PWD}/build ${PWD}/../${FOLDER}-native/python"
popd
}

### SETUPTOOLS ###
_build_setuptools() {
local VERSION="5.8"
local FOLDER="setuptools-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://pypi.python.org/packages/source/s/setuptools/${FILE}"
local XPYTHON="${PWD}/target/Python-2.7.8-native/python"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd target/"${FOLDER}"
PYTHONPATH="${DEST}/lib/python2.7/site-packages" "${XPYTHON}" setup.py \
  build --executable="${DEST}/bin/python2.7" \
  install --prefix="${DEST}" --force
for f in {easy_install,easy_install-2.7}; do
  sed -i -e "1 s|^.*$|#!${DEST}/bin/python2.7|g" "${DEST}/bin/$f"
done
popd
}

### PIP ###
_build_pip() {
local VERSION="1.5.6"
local FOLDER="pip-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://pypi.python.org/packages/source/p/pip/${FILE}"
local XPYTHON="${PWD}/target/Python-2.7.8-native/python"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd target/"${FOLDER}"
PYTHONPATH="${DEST}/lib/python2.7/site-packages" "${XPYTHON}" setup.py \
  build --executable="${DEST}/bin/python2.7" \
  install --prefix="${DEST}" --force
for f in {pip,pip2,pip2.7}; do
  sed -i -e "1 s|^.*$|#!${DEST}/bin/python2.7|g" "${DEST}/bin/$f"
done
popd
}

### BUILD ###
_build() {
  _build_zlib
  _build_bzip
  _build_openssl
  _build_ncurses
  _build_sqlite
  _build_bdb
  _build_libffi
  _build_expat
  _build_python
  _build_setuptools
  _build_pip
  _package
}
