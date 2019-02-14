# Script by Gregory Casamento & Ivan Vucica
#
# from android documentation: 
# http://web.archive.org/web/20190210195102/
# https://developer.android.com/ndk/guides/cmake

export ANDROID_HOME="${HOME}"/Library/Android/sdk
export ANDROID_NDK_HOME=${ANDROID_HOME}/ndk-bundle
export ANDROID_CMAKE_ROOT=${ANDROID_HOME}/cmake/3.10.2.4988404
export CMAKE_TOOLCHAIN_FILE=${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake
export NINJA=${ANDROID_CMAKE_ROOT}/bin/ninja
export ROOT_DIR=`pwd`
export GSROOT=${ROOT_DIR}/src
export INSTALL_PREFIX=${ROOT_DIR}/GNUstep
export ANDROID_GNUSTEP_INSTALL_ROOT="${INSTALL_PREFIX}"
export SYSTEM_LIBRARY_DIR=${INSTALL_PREFIX}/System/Library/Libraries
export SYSTEM_HEADERS_DIR=${INSTALL_PREFIX}/System/Library/Headers

cd $ROOT_DIR

echo "### Setup build for libobjc2"
rm -rf "${GSROOT}"
mkdir -p "${GSROOT}"
rm -rf ${INSTALL_PREFIX}
mkdir ${INSTALL_PREFIX}
 
cd "${GSROOT}"
git clone https://github.com/gnustep/libobjc2
mkdir -p "${GSROOT}"/libobjc2/build

echo "### Build libobjc2"
cd "${GSROOT}"
${ANDROID_CMAKE_ROOT}/bin/cmake \
  -H"${GSROOT}"/libobjc2 \
  -B"${GSROOT}"/libobjc2/build \
  -G"Ninja" \
  -DANDROID_ABI=armeabi-v7a \
  -DANDROID_NDK=${ANDROID_NDK_HOME} \
  -DCMAKE_LIBRARY_OUTPUT_DIRECTORY="${GSROOT}"/libobjc2/build \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_MAKE_PROGRAM=${NINJA} \
  -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} \
  -DANDROID_NATIVE_API_LEVEL=23 \
  -DANDROID_TOOLCHAIN=clang \
  -DCMAKE_INSTALL_PREFIX="${ANDROID_GNUSTEP_INSTALL_ROOT}"

cd ${GSROOT}/libobjc2/build
sed 's/-Wl,--fatal-warnings//' build.ninja > build2.ninja && mv build2.ninja build.ninja

${NINJA} -j6
mkdir -p ${SYSTEM_LIBRARY_DIR}
mkdir -p ${SYSTEM_HEADERS_DIR}/objc

cp libobjc.so ${SYSTEM_LIBRARY_DIR}
cp -r ../objc/* ${SYSTEM_HEADERS_DIR}/objc
# cp -r ../objc/* ${SYSTEM_HEADERS_DIR}

if [ "$?" != "0" ]; then
    echo "### LIBOBJC2 BUILD FAILED!!!"
    exit 0
fi

echo "### Set toolchain vars..."
export TOOLCHAIN="${ANDROID_NDK_HOME}"/toolchains/llvm/prebuilt/darwin-x86_64
export CC="${TOOLCHAIN}"/bin/clang
export CXX="${TOOLCHAIN}"/bin/clang++
export OBJC="${TOOLCHAIN}"/bin/clang
export LD="${CC}"
export CFLAGS="--gcc-toolchain=${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/darwin-x86_64 --target=armv7-none-linux-androideabi23"
export OBJCFLAGS="${CFLAGS} -I${SYSTEM_HEADERS_DIR}"
export LDFLAGS="${CFLAGS} -L${SYSTEM_LIBRARY_DIR}"

#echo "### Build libffi"
#cd ${GSROOT}
#git clone http://github.com/libffi/libffi.git
# git clone https://android.googlesource.com/platform/external/libffi
#cd libffi
#./autogen.sh
#./configure --host=arm-linux-androideabi --enable-shared --prefix="${ANDROID_GNUSTEP_INSTALL_ROOT}"
#gnumake -j8 install

#echo "### Build libxml2"
#cd ${GSROOT}
#git clone https://github.com/GNOME/libxml2.git
#cd libxml2
#./autogen.sh
#./configure --host=arm-linux-androideabi --enable-shared --prefix="${ANDROID_GNUSTEP_INSTALL_ROOT}"
#gnumake -j8 install

echo "### Build make..."
cd "${GSROOT}"
git clone https://github.com/gnustep/tools-make
cd "${GSROOT}"/tools-make
./configure --host=arm-linux-androideabi --prefix="${ANDROID_GNUSTEP_INSTALL_ROOT}" --with-layout=gnustep OBJCFLAGS="${OBJCFLAGS} -integrated-as"
gnumake GNUSTEP_INSTALLATION_DOMAIN=SYSTEM install
if [ "$?" != "0" ]; then
    echo "### MAKE BUILD FAILED!!!"
    exit 0
fi
echo "### Source ${ANDROID_GNUSTEP_INSTALL_ROOT}/share/GNUstep/Makefiles/GNUstep.sh"
. "${ANDROID_GNUSTEP_INSTALL_ROOT}"/System/Library/Makefiles/GNUstep.sh


echo "### Setup build for base..."
cd "${GSROOT}"
git clone https://github.com/gnustep/libs-base
cd "${GSROOT}"/libs-base
pwd
sed 's/cross_objc2_runtime=0/cross_objc2_runtime=1/g' cross.config > cross.config2 && mv cross.config2 cross.config
cat cross.config

./configure --host=arm-linux-androideabi \
  --enable-nxconstantstring \
  --disable-invocations \
  --disable-iconv \
  --disable-tls \
  --disable-icu \
  --disable-xml \
  --disable-mixedabi \
  --disable-gdomap \
  --with-cross-compilation-info=./cross.config

echo "### Build base..."
sed 's/cross_objc2_runtime=0/cross_objc2_runtime=1/g' cross.config > cross.config2 && mv cross.config2 cross.config
gnumake LD="${LD}" LDFLAGS="${LDFLAGS} -nopie" -j6 messages=yes install
if [ "$?" != "0" ]; then
    echo "### BASE BUILD FAILED!!!"
    exit 0
fi
