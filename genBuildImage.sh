#!/bin/bash -e

export HUB_ORG="374168611083.dkr.ecr.us-east-1.amazonaws.com"

set_context() {
  export RES_REPO=$CONTEXT"_repo"
  export RES_IMAGE_OUT=$CONTEXT"_img"
  export IMAGE_NAME=$(echo $CONTEXT | awk '{print tolower($0)}')
  export TAG_NAME="master"

  export RES_REPO_COMMIT=$(shipctl get_resource_version_key "$RES_REPO" "shaData.commitSha")
  export BLD_IMG=$HUB_ORG/$IMAGE_NAME:$TAG_NAME

  echo "CONTEXT=$CONTEXT"
  echo "IMAGE_NAME=$IMAGE_NAME"
  echo "RES_REPO=$RES_REPO"
  echo "RES_IMAGE_OUT=$RES_IMAGE_OUT"
  echo "HUB_ORG=$HUB_ORG"
  echo "TAG_NAME=$TAG_NAME"
  echo "BLD_IMG=$BLD_IMG"
  echo "BUILD_NUMBER=$BUILD_NUMBER"
  echo "RES_REPO_COMMIT=$RES_REPO_COMMIT"
}

create_image() {
  pushd $(shipctl get_resource_state $RES_REPO)
    echo "Starting Docker build & push for $BLD_IMG"
    sudo docker build -t=$BLD_IMG --pull --no-cache .
    echo "Pushing $BLD_IMG"
    sudo docker push $BLD_IMG
    echo "Completed Docker build & push for $BLD_IMG"
  popd
}

create_out_state() {
  echo "Creating a state file for $RES_IMAGE_OUT"

  shipctl post_resource_state_multi "$RES_IMAGE_OUT" \
  "versionName=$TAG_NAME \
  IMG_REPO_COMMIT_SHA=$RES_REPO_COMMIT \
  BUILD_NUMBER=$BUILD_NUMBER"
}

main() {
  echo "JOB_TRIGGERED_BY_NAME="$JOB_TRIGGERED_BY_NAME
  declare -a images_to_build=()

  IFS='_' read -ra ARR <<< "$JOB_TRIGGERED_BY_NAME"
  if [ "${ARR[0]}" == "microbase" ]; then
    images_to_build=("api" "www" "mktg" "nexec")
  else
    images_to_build=("${ARR[0]}")
  fi

  for image in "${images_to_build[@]}"
  do
    echo "building $image"
    export CONTEXT=$image

    set_context
    create_image
    create_out_state
  done
}

main
