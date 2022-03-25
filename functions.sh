#!/bin/bash

function prompt_key_upload_verification {
  echo "⚠ Please ensure you have uploaded your public key"
  echo "   to https://$1/-/profile/keys"
  echo
  read -p "Press enter to continue..."
}

function prompt_public_key_creation {
  echo "⚠ Would you like to create public key?"
  select yn in "Yes" "No";
  do
  case $yn in
  Yes)
    ssh-keygen -t ed25519 -C "$USER@jindogroup.com"; 
    break;;
  No)
    echo "⚠ Please create public key (in new terminal)"
    echo "   i.e. run: ssh-keygen -t ed25519 -C \"$USER@jindogroup.com\""
    read -p "   before you continue..."
    break;;
  *)
    echo "✘ Invalid choice."
    echo
    prompt_public_key_creation
    break
  ;;
  esac
  done
  echo
}

function use_ssh_insteadof_https {
  git config --global url.ssh://git@$1.insteadOf https://$1
}

function prefer_ssh_for_repo {
  if grep -q $1 ~/.gitconfig; then
    echo "✓ Already using ssh instead of https for $1"
  else 
    use_ssh_insteadof_https $1
  fi
}

function replace_nix_repo_imports {
  MATCH=$1
  REPLACE=$2
  git grep -l "$MATCH" | xargs sed -i "s|$MATCH/|$REPLACE/akitascreen-|g"
}

function prompt_username {
  local REPO_HOST=$AKITA_REPO_HOST
  local USERNAME=$1
  echo $AKITA_REPO_HOST
  if [[ -z "$USERNAME" ]] ; then 
    echo -n "☕ Username: " && read USERNAME
    if [[ -z "$USERNAME" ]] ; then
      echo "✘ invalid"
      echo 
      echo "https://$REPO_HOST"
      prompt_username $USERNAME
    fi
  else
    echo "☕ Username: $USERNAME ✓"
  fi
  echo $USERNAME
}

function prompt_password {
  local REPO_HOST=$AKITA_REPO_HOST
  local PASSWORD=$1
  if [[ -z "$PASSWORD" ]] ; then 
    echo -n "✍ Password: " && read -s PASSWORD
    if [[ -z "$PASSWORD" ]] ; then
      echo "✘ invalid"
      echo 
      echo "https://$REPO_HOST"
      prompt_password $PASSWORD
    fi
  else
    echo "✍ Password ✓"
  fi
  echo $PASSWORD
}

function prompt_check_prerequisite_software {
  echo "Ensure you have the following software installed"
  echo "- git (https://git-scm.com/downloads)"
  echo "- golang 1.15+ (https://go.dev/doc/install)"
  echo "- docker, docker-compose (https://docs.docker.com/get-docker/)"
  echo
  read -p "Press enter to continue..."
}

function prompt_code_root {
  try_again_error_message="Try again. Enter alternative code root"
  local CODE_ROOT=$1
  local JINDO_REPO_GROUP=$2
  local NEW_CODE_ROOT=""
  echo -n "🔥 Leave blank to use: [$CODE_ROOT]: " && read NEW_CODE_ROOT
  if [[ -z "$NEW_CODE_ROOT" ]] ; then 
    echo
  else
    if ! [[ -x "$NEW_CODE_ROOT" ]] ; then
        echo "✘ User '$USER' cannot write to $NEW_CODE_ROOT."
        echo
        echo $try_again_error_message
        prompt_code_root
    fi
    if [ ! -d "$NEW_CODE_ROOT" ]; then
      mkdir -p $NEW_CODE_ROOT
      if [ $? -ne 0 ] ; then
        echo "✘ Failed to create $NEW_CODE_ROOT"
        echo $try_again_error_message
        prompt_code_root
      else
        CODE_ROOT=$NEW_CODE_ROOT
      fi
    else
      CODE_ROOT=$NEW_CODE_ROOT
    fi
  fi
  
  # verify code root choice
  echo "⚠ Your code will be witten to the directory '$CODE_ROOT/$JINDO_REPO_GROUP'. Continue?"
  select yn in "Yes" "No";
  do
  case $yn in
  Yes)
    echo "✓ Code Root: $CODE_ROOT"
    break;;
  No)
    prompt_code_root
    break;;
  *)
    echo "✘ Invalid choice."
    echo
    echo $try_again_error_message
    prompt_code_root
    break
  ;;
  esac
  done
  echo $CODE_ROOT
}