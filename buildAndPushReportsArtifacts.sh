#!/bin/bash -e

# Input parameters
export RES_REPO=$1
export ARCHITECTURE="x86_64"
export OS="Ubuntu_14.04"
export ARTIFACTS_BUCKET="s3://shippable-artifacts"
export VERSION=master

# Reports Path
export MICRO_PATH=$(shipctl get_resource_state $RES_REPO)
export GOPATH="$MICRO_PATH/gol"
export REPORTS_PATH="$MICRO_PATH/gol/src/github.com/Shippable/reports"
export REPORTS_PACKAGE_PATH="$REPORTS_PATH/package/$ARCHITECTURE/$OS"

# Binary
export REPORTS_BINARY_DIR="/tmp"
export REPORTS_BINARY_FILE="reports"
export REPORTS_BINARY_TAR="reports-$VERSION-$ARCHITECTURE-$OS.tar.gz"
export S3_BUCKET_BINARY_DIR="$ARTIFACTS_BUCKET/reports/$VERSION/"

check_input() {
  if [ -z "$ARCHITECTURE" ]; then
    echo "Missing input parameter ARCHITECTURE"
    exit 1
  fi

  if [ -z "$OS" ]; then
    echo "Missing input parameter OS"
    exit 1
  fi

  if [ -z "$ARTIFACTS_BUCKET" ]; then
    echo "Missing input parameter ARTIFACTS_BUCKET"
    exit 1
  fi
}

build_reports() {
  pushd $REPORTS_PATH
    echo "Packaging reports..."
    $REPORTS_PACKAGE_PATH/package.sh
  popd

  pushd $GOPATH
    echo "Copying binary..."
    cp "bin/$REPORTS_BINARY_FILE" $REPORTS_BINARY_DIR
  popd
}

push_to_s3() {
  pushd $REPORTS_BINARY_DIR
    echo "Pushing to S3..."
    tar -zcvf "$REPORTS_BINARY_TAR" "$REPORTS_BINARY_FILE"
    aws s3 cp --acl public-read "$REPORTS_BINARY_TAR" "$S3_BUCKET_BINARY_DIR"
  popd
}

main() {
  check_input
  build_reports
  push_to_s3
}

main
