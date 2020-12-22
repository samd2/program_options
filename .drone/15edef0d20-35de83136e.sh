#!/bin/bash

set -ex
export TRAVIS_BUILD_DIR=$(pwd)
export TRAVIS_BRANCH=$DRONE_BRANCH
export TRAVIS_OS_NAME=${DRONE_JOB_OS_NAME:-linux}
export VCS_COMMIT_ID=$DRONE_COMMIT
export GIT_COMMIT=$DRONE_COMMIT
export DRONE_CURRENT_BUILD_DIR=$(pwd)
export PATH=~/.local/bin:/usr/local/bin:$PATH

echo '==================================> BEFORE_INSTALL'

. .drone/before-install.sh

echo '==================================> INSTALL'

export SELF=`basename $DRONE_REPO`
cd ..
git clone -b $TRAVIS_BRANCH --depth 1 https://github.com/boostorg/boost.git boost-root
cd boost-root
git submodule update -q --init tools/boostdep
git submodule update -q --init tools/build
git submodule update -q --init tools/inspect
cp -r $TRAVIS_BUILD_DIR/* libs/$SELF
export BOOST_ROOT="`pwd`"
export PATH="`pwd`":$PATH
python tools/boostdep/depinst/depinst.py $SELF --include example
./bootstrap.sh
./b2 headers

echo '==================================> BEFORE_SCRIPT'

. $DRONE_CURRENT_BUILD_DIR/.drone/before-script.sh

echo '==================================> SCRIPT'

pushd /tmp && git clone https://github.com/linux-test-project/lcov.git && cd lcov && sudo make install && which lcov && lcov --version && popd
cd libs/$SELF
ci/codecov.sh

echo '==================================> AFTER_SUCCESS'

. $DRONE_CURRENT_BUILD_DIR/.drone/after-success.sh
