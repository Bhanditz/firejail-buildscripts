#!/bin/sh -xe

export CI_OS="linux"

if [ "$CI_ARCH" = "amd64" ]; then
  export CFLAGS=-m64 CXXFLAGS=-m64 LDFLAGS=-m64
else
  export CFLAGS=-m32 CXXFLAGS=-m32 LDFLAGS=-m32
fi

7za | head -2
gcc -v

export FIREJAIL_VERSION=head
if [ -n "$CI_BUILD_TAG" ]; then
  export FIREJAIL_VERSION=$CI_BUILD_TAG
fi
export CI_VERSION=$CI_BUILD_REF_NAME

git clone https://github.com/netblue30/firejail.git firejail-repo
(cd firejail-repo && git checkout $CI_BUILD_REF_NAME && ./configure --disable-globalcfg && make -j3)
mv firejail-repo/src/firejail/firejail .

strip firejail
file firejail
7za a firejail.7z firejail

# set up a file hierarchy that ibrew can consume, ie:
#
# - dl.itch.ovh
#   - firejail
#     - linux-amd64
#       - LATEST
#       - v0.3.0
#         - firejail.7z
#         - firejail
#         - SHA1SUMS

BINARIES_DIR="binaries/$CI_OS-$CI_ARCH"
mkdir -p $BINARIES_DIR/$CI_VERSION
mv firejail.7z $BINARIES_DIR/$CI_VERSION
mv firejail $BINARIES_DIR/$CI_VERSION

(cd $BINARIES_DIR/$CI_VERSION && sha1sum * > SHA1SUMS)

if [ -n "$CI_BUILD_TAG" ]; then
  echo $CI_BUILD_TAG > $BINARIES_DIR/LATEST
fi

