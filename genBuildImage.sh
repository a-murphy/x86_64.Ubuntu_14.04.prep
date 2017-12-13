#!/bin/bash -e

export HUB_ORG="374168611083.dkr.ecr.us-east-1.amazonaws.com"

set_context() {

  export IMAGE_NAME=$(echo $CONTEXT | awk '{print tolower($0)}')
  export RES_REPO=$CONTEXT"_repo"
  export RES_IMAGE_OUT=$CONTEXT"_img"
  export TAG_NAME="master"

  export RES_REPO_STATE=$(shipctl get_resource_state $RES_REPO)
  export RES_REPO_UP=$(shipctl to_uppercase $RES_REPO)
  export RES_REPO_COMMIT=$(eval echo "$"$RES_REPO_UP"_COMMIT")
  export BLD_IMG=$HUB_ORG/$IMAGE_NAME:$TAG_NAME

  echo "CONTEXT=$CONTEXT"
  echo "IMAGE_NAME=$IMAGE_NAME"
  echo "RES_REPO=$RES_REPO"
  echo "RES_IMAGE_OUT=$RES_IMAGE_OUT"
  echo "HUB_ORG=$HUB_ORG"
  echo "TAG_NAME=$TAG_NAME"
  echo "RES_REPO_UP=$RES_REPO_UP"
  echo "RES_REPO_STATE=$RES_REPO_STATE"
  echo "BLD_IMG=$BLD_IMG"
  echo "BUILD_NUMBER=$BUILD_NUMBER"
  echo "RES_REPO_COMMIT=$RES_REPO_COMMIT"

}

create_image() {
  pushd $RES_REPO_STATE
    echo "Starting Docker build & push for $BLD_IMG"
    sudo docker build -t=$BLD_IMG --pull --no-cache .
    echo "Pushing $BLD_IMG"
    sudo docker push $BLD_IMG
    echo "Completed Docker build & push for $BLD_IMG"
  popd
}

create_out_state() {
  echo "Creating a state file for $RES_IMAGE_OUT"
  shipctl post_resource_state $RES_IMAGE_OUT versionName $TAG_NAME
  shipctl put_resource_state $RES_IMAGE_OUT IMG_REPO_COMMIT_SHA $RES_REPO_COMMIT
  shipctl put_resource_state $RES_IMAGE_OUT BUILD_NUMBER $BUILD_NUMBER
}

main() {
  echo "JOB_TRIGGERED_BY_NAME="$JOB_TRIGGERED_BY_NAME

  IFS='_' read -ra ARR <<< "$JOB_TRIGGERED_BY_NAME"
  export CONTEXT=${ARR[0]}

  set_context
  create_image
  create_out_state
}

main
