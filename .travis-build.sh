#!/bin/bash
ROOT=$TRAVIS_BUILD_DIR/..

## Build Checker Framework
(cd $ROOT && git clone --depth 1  https://github.com/typetools/checker-framework.git)
# This also builds annotation-tools and jsr308-langtools
(cd $ROOT/checker-framework/ && ./.travis-build-without-test.sh downloadjdk)
export CHECKERFRAMEWORK=$ROOT/checker-framework

## Obtain annotated-jdk8u-jdk
(cd $ROOT && hg clone -q https://bitbucket.org/typetools/annotated-jdk8u-jdk)

## Jdk
## Compile all the packages for the following checkers:
if [[ "$1" == "formatter" ]]; then
  PROCESSORS=formatter ./crash-check.sh
elif [[ "$1" == "interning" ]]; then
  PROCESSORS=interning ./crash-check.sh
elif [[ "$1" == "lock" ]]; then
  PROCESSORS=lock ./crash-check.sh
elif [[ "$1" == "regex" ]]; then
  PROCESSORS=regex ./crash-check.sh
elif [[ "$1" == "signature" ]]; then
  PROCESSORS=signature ./crash-check.sh
elif [[ "$1" == "value" ]]; then
  PROCESSORS=org.checkerframework.common.value.ValueChecker ./crash-check.sh

## Spilt the jdk into two jobs.  The packages are grouped so that ~50% of the lines of code are in each job.
elif [[ "$1" == "index-sun" ]]; then
  PROCESSORS=index PACKAGES="sun" ./crash-check.sh
elif [[ "$1" == "index-com" ]]; then
  PROCESSORS=index PACKAGES="com" ./crash-check.sh
elif [[ "$1" == "index-javax" ]]; then
  PROCESSORS=index PACKAGES="javax" ./crash-check.sh
elif [[ "$1" == "index-java" ]]; then
  PROCESSORS=index PACKAGES="java" ./crash-check.sh
elif [[ "$1" == "index-jdk-org" ]]; then
  PROCESSORS=index PACKAGES="jdk org" ./crash-check.sh
elif [[ "$1" == "nullness-fbc-sun-javax" ]]; then
  PROCESSORS=nullness PACKAGES="sun javax" ./crash-check.sh
elif [[ "$1" == "nullness-fbc-java-com-jdk-org" ]]; then
  PROCESSORS=nullness PACKAGES="java com jdk org" ./crash-check.sh
elif [[ "$1" == "nullness-raw-sun-javax" ]]; then
  PROCESSORS=org.checkerframework.checker.nullness.NullnessRawnessChecker PACKAGES="sun javax" ./crash-check.sh
elif [[ "$1" == "nullness-raw-java-com-jdk-org" ]]; then
  PROCESSORS=org.checkerframework.checker.nullness.NullnessRawnessChecker PACKAGES="java com jdk org" ./crash-check.sh
else
  echo "Bad argument '$1' to travis-build.sh"
  false
fi

