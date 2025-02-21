#!/bin/bash

BUILD_VERSION=1.0.0
BUILD_DIR="config_$BUILD_VERSION"

# create the artifact build directory
mkdir $BUILD_DIR
cp config.json .
cp update.sh .

tar -czvf "$BUILD_DIR.tar.gz" $BUILD_DIR

# clean up
rm -rf $BUILD_DIR