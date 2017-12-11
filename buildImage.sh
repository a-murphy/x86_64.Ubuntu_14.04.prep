#!/bin/bash -e

export CONTEXT=$1
export HUB_ORG="drydock"
export TAG_NAME="master"

set_context() {
  export CURR_JOB="build_"$CONTEXT
  export RES_REPO=$CONTEXT"_repo"
  export RES_REPO_UP=$(shipctl to_uppercase $RES_REPO)
  export RES_REPO_COMMIT=$(eval echo "$"$RES_REPO_UP"_COMMIT")
  export IMAGE_NAME=$(echo $CONTEXT | awk '{print tolower($0)}')
  export RES_IMAGE_OUT=$CONTEXT"_img"
  export BLD_IMG=$HUB_ORG/$IMAGE_NAME:$TAG_NAME

  echo "BUILD_NUMBER=$BUILD_NUMBER"
  echo "CONTEXT=$CONTEXT"
  echo "HUB_ORG=$HUB_ORG"
  echo "TAG_NAME=$TAG_NAME"

  echo "CURR_JOB=$CURR_JOB"
  echo "RES_REPO=$RES_REPO"
  echo "RES_REPO_UP=$RES_REPO_UP"
  echo "RES_REPO_COMMIT=$RES_REPO_COMMIT"
  echo "IMAGE_NAME=$IMAGE_NAME"
  echo "RES_IMAGE_OUT=$RES_IMAGE_OUT"
  echo "BLD_IMG=$BLD_IMG"
}

create_image() {
  pushd $(shipctl get_resource_state $RES_REPO)
    echo "Starting Docker build & push for $BLD_IMG"
    sudo docker build -t=$BLD_IMG --pull .
    echo "Pushing $BLD_IMG"
    sudo docker push $BLD_IMG
    echo "Completed Docker build & push for $BLD_IMG"
  popd
}

create_out_state() {
  echo "Creating a state file for $RES_IMAGE_OUT"
  echo versionName=$TAG_NAME > "$JOB_STATE/$RES_IMAGE_OUT.env"
  echo IMG_REPO_COMMIT_SHA=$RES_REPO_COMMIT >> "$JOB_STATE/$RES_IMAGE_OUT.env"
  echo BUILD_NUMBER=$BUILD_NUMBER >> "$JOB_STATE/$RES_IMAGE_OUT.env"

  echo "Creating a state file for $CURR_JOB"
  echo versionName=$TAG_NAME > "$JOB_STATE/$CURR_JOB.env"
  echo IMG_REPO_COMMIT_SHA=$RES_REPO_COMMIT >> "$JOB_STATE/$CURR_JOB.env"
}

main() {
  set_context
  create_image
  create_out_state
}

main
