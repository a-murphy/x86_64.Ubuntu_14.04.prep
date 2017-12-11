#!/bin/bash -e

export RUN_TYPE=$1
export CURR_JOB="tag_push_"$RUN_TYPE

set_job_context() {
  eval `ssh-agent -s`
  ps -eaf | grep ssh
  which ssh-agent


  export UP_TAG_NAME="master"
  export RES_VER="rel_prod"
  export RES_VER_NAME=$(shipctl get_resource_version_name $RES_VER)
  export RES_GH_SSH="avi_gh_ssh"
  export RES_GH_SSH_META=$(shipctl get_resource_meta $RES_GH_SSH)

  # TODO: Remove this after avi_gh_ssh is added to dry-dock-aarch64 organisation
  export AARCH64_GH_SSH="aarch64_gh_ssh"
  export AARCH64_GH_SSH_META=$(shipctl get_resource_meta $AARCH64_GH_SSH)

  export RES_CONF_REPO="config_repo"
  export RES_CONF_REPO_STATE=$(shipctl get_resource_state $RES_CONF_REPO)

  echo ""
  echo "============= Begin info for JOB $CURR_JOB======================"
  echo "CURR_JOB=$CURR_JOB"
  echo "RES_VER=$RES_VER"
  echo "RES_VER_NAME=$RES_VER_NAME"
  echo "UP_TAG_NAME=$UP_TAG_NAME"
  echo "RES_GH_SSH=$RES_GH_SSH"
  echo "RES_GH_SSH_META=$RES_GH_SSH_META"
  echo "============= End info for JOB $CURR_JOB======================"
  echo ""

  echo "Creating a state file for $CURR_JOB"
  shipctl post_resource_state $CURR_JOB versionName $RES_VER_NAME
}

add_ssh_key() {
  pushd "$RES_GH_SSH_META"
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

process_core_services() {
  for c in `cat coreServices.txt`; do
    export CONTEXT=$c
    export CONTEXT_IMAGE=$c
    export CONTEXT_REPO=$c
    export HUB_ORG=drydock
    export GH_ORG=dry-dock

    echo ""
    echo "============= Begin info for CONTEXT $CONTEXT======================"
    echo "CONTEXT=$CONTEXT"
    echo "HUB_ORG=$HUB_ORG"
    echo "GH_ORG=$GH_ORG"
    echo "CONTEXT_IMAGE=$CONTEXT_IMAGE"
    echo "CONTEXT_REPO=$CONTEXT_REPO"
    echo "============= End info for CONTEXT $CONTEXT======================"
    echo ""

    pull_tag_image
    tag_push_repo
  done
}

process_u14_services() {
  for c in `cat u14Services.txt`; do
    export CONTEXT=$c
    export CONTEXT_IMAGE=$c
    export CONTEXT_REPO=$c
    export HUB_ORG=drydock
    export GH_ORG=dry-dock

    echo ""
    echo "============= Begin info for CONTEXT $CONTEXT======================"
    echo "CONTEXT=$CONTEXT"
    echo "HUB_ORG=$HUB_ORG"
    echo "GH_ORG=$GH_ORG"
    echo "CONTEXT_IMAGE=$CONTEXT_IMAGE"
    echo "CONTEXT_REPO=$CONTEXT_REPO"
    echo "============= End info for CONTEXT $CONTEXT======================"
    echo ""

    pull_tag_image
    tag_push_repo
  done
}

process_u16_services() {
  for c in `cat u16Services.x86_64.txt`; do
    export CONTEXT=$c
    export CONTEXT_IMAGE=$c
    export CONTEXT_REPO=$c
    export HUB_ORG=drydock
    export GH_ORG=dry-dock

    echo ""
    echo "============= Begin info for CONTEXT $CONTEXT======================"
    echo "CONTEXT=$CONTEXT"
    echo "HUB_ORG=$HUB_ORG"
    echo "GH_ORG=$GH_ORG"
    echo "CONTEXT_IMAGE=$CONTEXT_IMAGE"
    echo "CONTEXT_REPO=$CONTEXT_REPO"
    echo "============= End info for CONTEXT $CONTEXT======================"
    echo ""

    pull_tag_image
    tag_push_repo
  done
}

process_repo_services() {
  for c in `cat repoServices.txt`; do
    export CONTEXT=$c
    export CONTEXT_REPO=$c
    export GH_ORG=Shippable

    echo ""
    echo "============= Begin info for CONTEXT $CONTEXT======================"
    echo "CONTEXT=$CONTEXT"
    echo "GH_ORG=$GH_ORG"
    echo "CONTEXT_REPO=$CONTEXT_REPO"
    echo "============= End info for CONTEXT $CONTEXT======================"
    echo ""

    tag_push_repo
  done
}

process_ship_ecr_services() {
  for c in `cat ecrServices.txt`; do
    export CONTEXT=$c
    export CONTEXT_IMAGE=$c
    export CONTEXT_REPO=$c
    export HUB_ORG=374168611083.dkr.ecr.us-east-1.amazonaws.com
    export GH_ORG=Shippable

    echo ""
    echo "============= Begin info for CONTEXT $CONTEXT======================"
    echo "CONTEXT=$CONTEXT"
    echo "HUB_ORG=$HUB_ORG"
    echo "GH_ORG=$GH_ORG"
    echo "CONTEXT_IMAGE=$CONTEXT_IMAGE"
    echo "CONTEXT_REPO=$CONTEXT_REPO"
    echo "============= End info for CONTEXT $CONTEXT======================"
    echo ""

    pull_tag_image
    tag_push_repo
  done
}

process_ship_dry_services() {
  for c in `cat dryServices.x86_64.txt`; do
    export CONTEXT=$c
    export CONTEXT_IMAGE=$c
    export CONTEXT_REPO=$c
    export HUB_ORG=drydock
    export GH_ORG=Shippable

    echo ""
    echo "============= Begin info for CONTEXT $CONTEXT======================"
    echo "CONTEXT=$CONTEXT"
    echo "HUB_ORG=$HUB_ORG"
    echo "GH_ORG=$GH_ORG"
    echo "CONTEXT_IMAGE=$CONTEXT_IMAGE"
    echo "CONTEXT_REPO=$CONTEXT_REPO"
    echo "============= End info for CONTEXT $CONTEXT======================"
    echo ""

    pull_tag_image
    tag_push_repo
  done
}

# TODO: Remove this after avi_gh_ssh is added to dry-dock-aarch64 organisation
add_aarch64_ssh_key() {
  ssh-add -D
  pushd "$AARCH64_GH_SSH_META"
    echo "Extracting AARCH64 GH SSH Key"
    echo "-----------------------------------"
    cat "integration.json"  | jq -r '.privateKey' > aarch64_gh_ssh.key
    chmod 600 aarch64_gh_ssh.key
    ssh-add aarch64_gh_ssh.key
    echo "Completed Extracting AARCH64 GH SSH Key"
    echo "-----------------------------------"
  popd
}

process_ship_aarch64_dry_services() {
  # TODO: Remove this after avi_gh_ssh is added to dry-dock-aarch64 organisation
  add_aarch64_ssh_key

  for c in `cat dryServices.aarch64.txt`; do
    export CONTEXT="aarch64_$c"
    export CONTEXT_IMAGE=$c
    export CONTEXT_REPO=$c
    export HUB_ORG=drydockaarch64
    export GH_ORG=dry-dock-aarch64

    echo ""
    echo "============= Begin info for CONTEXT $CONTEXT======================"
    echo "CONTEXT=$CONTEXT"
    echo "HUB_ORG=$HUB_ORG"
    echo "GH_ORG=$GH_ORG"
    echo "CONTEXT_IMAGE=$CONTEXT_IMAGE"
    echo "CONTEXT_REPO=$CONTEXT_REPO"
    echo "============= End info for CONTEXT $CONTEXT======================"
    echo ""

    pull_tag_image
    tag_push_repo
  done
}

process_aarch64_u16_services() {
  # TODO: Remove this after avi_gh_ssh is added to dry-dock-aarch64 organisation
  add_aarch64_ssh_key

  for c in `cat u16Services.aarch64.txt`; do
    export CONTEXT="aarch64_$c"
    export CONTEXT_IMAGE=$c
    export CONTEXT_REPO=$c
    export HUB_ORG=drydockaarch64
    export GH_ORG=dry-dock-aarch64

    echo ""
    echo "============= Begin info for CONTEXT $CONTEXT======================"
    echo "CONTEXT=$CONTEXT"
    echo "HUB_ORG=$HUB_ORG"
    echo "GH_ORG=$GH_ORG"
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

  pushd $RES_CONF_REPO_STATE
    if [ "$RUN_TYPE" = "core" ]; then
      echo "Executing process_core_services"
      process_core_services
    elif [ "$RUN_TYPE" = "u14" ]
    then
      echo "Executing process_u14_services"
      process_u14_services
    elif [ "$RUN_TYPE" = "u16" ]
    then
      echo "Executing process_u16_services"
      process_u16_services
    elif [ "$RUN_TYPE" = "repo" ]
    then
      echo "Executing process_repo_services"
      process_repo_services
    elif [ "$RUN_TYPE" = "ecr" ]
    then
      echo "Executing process_ship_ecr_services"
      process_ship_ecr_services
    elif [ "$RUN_TYPE" = "dry" ]
    then
      echo "Executing process_ship_dry_services"
      process_ship_dry_services
    elif [ "$RUN_TYPE" = "aarch64_dry" ]
    then
      echo "Executing process_ship_aarch64_dry_services"
      process_ship_aarch64_dry_services
    elif [ "$RUN_TYPE" = "aarch64_u16" ]
    then
      echo "Executing process_aarch64_u16_services"
      process_aarch64_u16_services
    fi
  popd
}

main
