#!/bin/bash -e

# Input parameters
export RES_REPO=$1
export ARCHITECTURE="x86_64"
export OS="Ubuntu_14.04"
export ARTIFACTS_BUCKET="s3://shippable-artifacts"
export VERSION=master

# reqExec
export REQ_EXEC_PATH=$(shipctl get_resource_state $RES_REPO)
export REQ_EXEC_PACKAGE_PATH="$REQ_EXEC_PATH/package/$ARCHITECTURE/$OS"

# Binaries
export REQ_EXEC_BINARY_DIR="/tmp/reqExec"
export REQ_EXEC_BINARY_TAR="/tmp/reqExec-$VERSION-$ARCHITECTURE-$OS.tar.gz"
export S3_BUCKET_BINARY_DIR="$ARTIFACTS_BUCKET/reqExec/$VERSION/"

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

create_binaries_dir() {
  echo "Cleaning up $REQ_EXEC_BINARY_DIR..."
  rm -rf $REQ_EXEC_BINARY_DIR
  mkdir $REQ_EXEC_BINARY_DIR
}

build_reqExec() {
  pushd $REQ_EXEC_PATH
    echo "Packaging reqExec..."
    $REQ_EXEC_PACKAGE_PATH/package.sh

    echo "Copying dist..."
    cp -r dist $REQ_EXEC_BINARY_DIR
  popd
}

push_to_s3() {
  echo "Pushing to S3..."
  tar -zcvf "$REQ_EXEC_BINARY_TAR" -C "$REQ_EXEC_BINARY_DIR" .
  aws s3 cp --acl public-read "$REQ_EXEC_BINARY_TAR" "$S3_BUCKET_BINARY_DIR"
}

main() {
  check_input
  create_binaries_dir
  build_reqExec
  push_to_s3
}

main
