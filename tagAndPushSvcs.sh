#!/bin/bash -e

export HUB_ORG=$1
export GH_ORG=$2
export SVCS_LIST=$3
export CURR_JOB="tag_push_core"
export UP_TAG_NAME="master"
export RES_VER="rel_prod"
export RES_GH_SSH="core_gh_ssh"

set_job_context() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent

  export RES_VER_NAME=$(shipctl get_resource_version_name $RES_VER)

  echo ""
  echo "============= Begin info for JOB $CURR_JOB======================"
  echo "CURR_JOB=$CURR_JOB"
  echo "RES_VER=$RES_VER"
  echo "RES_VER_NAME=$RES_VER_NAME"
  echo "UP_TAG_NAME=$UP_TAG_NAME"
  echo "RES_GH_SSH=$RES_GH_SSH"
  echo "HUB_ORG=$HUB_ORG"
  echo "GH_ORG=$GH_ORG"
  echo "============= End info for JOB $CURR_JOB======================"
  echo ""

  echo "Creating a state file for $CURR_JOB"
  shipctl post_resource_state $CURR_JOB versionName $RES_VER_NAME
}

add_ssh_key() {
  pushd $(shipctl get_resource_meta $RES_GH_SSH)
    echo "Extracting GH SSH Key"
    echo "-----------------------------------"
    cat "integration.json"  | jq -r '.privateKey' > gh_ssh.key
    chmod 600 gh_ssh.key
    ssh-add gh_ssh.key
    echo "Completed Extracting GH SSH Key"
    echo "-----------------------------------"
  popd
}

pull_tag_image() {
  export IMAGE_NAME=$CONTEXT_IMAGE
  export RES_IMAGE=$CONTEXT"_img"
  export PULL_IMG=$HUB_ORG/$IMAGE_NAME:$UP_TAG_NAME
  export PUSH_IMG=$HUB_ORG/$IMAGE_NAME:$RES_VER_NAME
  export PUSH_LAT_IMG=$HUB_ORG/$IMAGE_NAME:latest

  echo ""
  echo "============= Begin info for IMG $RES_IMAGE======================"
  echo "IMAGE_NAME=$IMAGE_NAME"
  echo "RES_IMAGE=$RES_IMAGE"
  echo "PULL_IMG=$PULL_IMG"
  echo "PUSH_IMG=$PUSH_IMG"
  echo "============= End info for IMG $RES_IMAGE======================"
  echo ""

  echo "Starting Docker tag and push for $IMAGE_NAME"
  sudo docker pull $PULL_IMG

  echo "Tagging $PUSH_IMG"
  sudo docker tag $PULL_IMG $PUSH_IMG

  echo "Tagging $PUSH_LAT_IMG"
  sudo docker tag $PULL_IMG $PUSH_LAT_IMG

  echo "Pushing $PUSH_IMG"
  sudo docker push $PUSH_IMG
  echo "Completed Docker tag & push for $PUSH_IMG"

  echo "Pushing $PUSH_LAT_IMG"
  sudo docker push $PUSH_LAT_IMG
  echo "Completed Docker tag & push for $PUSH_LAT_IMG"

  echo "Completed Docker tag and push for $IMAGE_NAME"
}

tag_push_repo(){
  export SSH_PATH="git@github.com:$GH_ORG/$CONTEXT_REPO.git"
  export RES_REPO=$CONTEXT"_repo"
  export RES_REPO_META=$(shipctl get_resource_meta $RES_REPO)
  export RES_REPO_STATE=$(shipctl get_resource_state $RES_REPO)

  echo ""
  echo "============= Begin info for REPO $RES_REPO======================"
  echo "SSH_PATH=$SSH_PATH"
  echo "RES_REPO=$RES_REPO"
  echo "RES_REPO_META=$RES_REPO_META"
  echo "RES_REPO_STATE=$RES_REPO_STATE"
  echo "IMG_REPO_COMMIT_SHA=$IMG_REPO_COMMIT_SHA"
  echo "============= End info for REPO $RES_REPO======================"
  echo ""

  pushd $RES_REPO_META
    export IMG_REPO_COMMIT_SHA=$(shipctl get_json_value version.json 'version.propertyBag.shaData.commitSha')
  popd

  pushd $RES_REPO_STATE
    git remote add up $SSH_PATH
    git remote -v
    git checkout master

    git pull --tags
    git checkout $IMG_REPO_COMMIT_SHA

    if git tag -d $RES_VER_NAME; then
      echo "Removing existing tag"
      git push --delete up $RES_VER_NAME
    fi

    echo "Tagging repo with $RES_VER_NAME"
    git tag $RES_VER_NAME
    echo "Pushing tag $RES_VER_NAME"
    git push up $RES_VER_NAME
  popd

  shipctl put_resource_state $CURR_JOB $CONTEXT"_COMMIT_SHA" $IMG_REPO_COMMIT_SHA
}

process_services() {
  for c in `cat $SVCS_LIST`; do
    export CONTEXT=$c
    export CONTEXT_IMAGE=$c
    export CONTEXT_REPO=$c

    echo ""
    echo "============= Begin info for CONTEXT $CONTEXT======================"
    echo "CONTEXT=$CONTEXT"
    echo "CONTEXT_IMAGE=$CONTEXT_IMAGE"
    echo "CONTEXT_REPO=$CONTEXT_REPO"
    echo "============= End info for CONTEXT $CONTEXT======================"
    echo ""

    pull_tag_image
    tag_push_repo
  done
}

main() {
  set_job_context
  add_ssh_key
  process_services
}

main
