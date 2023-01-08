#!/bin/bash
# git submodule update --recursive
PROJECT_ROOT=$(pwd)

function build-helix() {
    cd submodules/helix-c
    mkdir build
    cd build
    cmake -DCMAKE_INSTALL_PREFIX=$PROJECT_ROOT/modules -DBUILD_SHARED_LIBS=OFF ..
    make
    make install
    cd ..
    rm -rf build
}

build-helix
