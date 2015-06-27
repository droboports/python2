python2
=======

This is a set of scripts to package a DroboApp from scratch, i.e., download sources, unpackage, compile, install, and package in a TGZ file. The `master` branch contains the Drobo5N version, the `drobofs` branch contains the DroboFS version.

## I just want to install the DroboApp, what do I do?

Check the [releases](https://github.com/droboports/python2/releases) page. If there are no releases available, then you have to compile.

## How to compile

First make sure that you have a [working cross-compiling VM](https://github.com/droboports/droboports.github.io/wiki/Setting-up-a-VM).

Log in the VM, pick a temporary folder (e.g., `~/build`), and then do:

```
git clone https://github.com/droboports/python2.git
cd python2
./build.sh
ls -la *.tgz
```

Each invocation creates a log file with all the generated output.

* `./build.sh distclean` removes everything, including downloaded files.
* `./build.sh clean` removes everything but downloaded files.
* `./build.sh package` repackages the DroboApp, without recompiling.

## Build a cross-compiler

First, install the package `qemu-user-static`.

Then, make sure there are no residual files, and use the `BUILD_DEST` variable.
```
./build.sh clean
XPYTHON="${HOME}/xtools/python2/fs"
BUILD_DEST="${XPYTHON}" ./build.sh
cp -vfaR ./target/install/bin/* "${XPYTHON}/bin/"
cp -vfaR ./target/install/include/* "${XPYTHON}/include/"
```

And set the `QEMU_LD_PREFIX` to use the python cross-compiler.
```
. crosscompile.sh
QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc" "${XPYTHON}/bin/python" setup.py build_ext \
  --include-dirs="${XPYTHON}/include" --library-dirs="${XPYTHON}/lib" \
  --force build --force bdist_egg --dist-dir .
```

## Missing modules

```
Python build finished, but the necessary bits to build these modules were not found:
_tkinter           bsddb185           gdbm            
linuxaudiodev      ossaudiodev        readline        
sunaudiodev                                           
To find the necessary bits, look in setup.py in detect_modules() for the module's name.
```

## Sources

* zlib: http://zlib.net/
* bzip: http://bzip.org/
* openssl: http://www.openssl.org/
* ncurses: https://www.gnu.org/software/ncurses/
* sqlite: http://sqlite.org/
* bdb: http://www.oracle.com/technetwork/database/database-technologies/berkeleydb/overview/index.html
* libffi: https://sourceware.org/libffi/
* expat: http://expat.sourceforge.net/
* python: http://www.python.org/
* setuptools: https://pypi.python.org/pypi/setuptools
* pip: https://pypi.python.org/pypi/pip

<sub>**Disclaimer**</sub>

<sub><sub>Drobo, DroboShare, Drobo FS, Drobo 5N, DRI and all related trademarks are the property of [Data Robotics, Inc](http://www.drobo.com/). This site is not affiliated, endorsed or supported by DRI in any way. The use of information and software provided on this website may be used at your own risk. The information and software available on this website are provided as-is without any warranty or guarantee. By visiting this website you agree that: (1) We take no liability under any circumstance or legal theory for any DroboApp, software, error, omissions, loss of data or damage of any kind related to your use or exposure to any information provided on this site; (2) All software are made “AS AVAILABLE” and “AS IS” without any warranty or guarantee. All express and implied warranties are disclaimed. Some states do not allow limitations of incidental or consequential damages or on how long an implied warranty lasts, so the above may not apply to you.</sub></sub>
