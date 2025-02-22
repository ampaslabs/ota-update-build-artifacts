#!/bin/bash

NAME=myapp
VERSION=1.0.0
BUILD_DIR=${NAME}_${VERSION}

# create the artifact build directory
mkdir $BUILD_DIR
cp myapp/myapp $BUILD_DIR/.
cp update.sh $BUILD_DIR/.

tar -czvf "${BUILD_DIR}.tar.gz" $BUILD_DIR

# clean up
rm -rf $BUILD_DIR