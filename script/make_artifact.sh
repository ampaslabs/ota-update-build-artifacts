#!/bin/bash

CONFIG_VERSION=1.0.0
BUILD_DIR="script_$BUILD_VERSION"

# create the artifact build directory
mkdir $BUILD_DIR
cp myscript.sh .
cp myscript.py .
cp update.sh .

tar -czvf "$BUILD_DIR.tar.gz" $BUILD_DIR

# clean up
rm -rf $BUILD_DIR