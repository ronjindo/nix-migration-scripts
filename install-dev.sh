#!/bin/bash

AKITA_REPO_HOST='gitlab.nixdev.co'
AKITA_REPO_GROUP='lsport'
CODE_ROOT="$HOME/code"
NIX_GITLAB_LOGIN=$1
NIX_GITLAB_PASSWORD=$2
CURRENT_DIR=$(pwd)

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

function clone_repo {
  if [ -d $2 ]; then
    if [[ $(ls $2) ]]; then
      echo "✓ $1"
    else
      rm -rf $2
      git clone git@$1.git $2
    fi
  else 
    echo
    git clone git@$1.git $2
  fi
}

function prompt_username {
  if [[ -z "$NIX_GITLAB_LOGIN" ]] ; then 
    echo -n "☕ Username: " && read NIX_GITLAB_LOGIN
    if [[ -z "$NIX_GITLAB_LOGIN" ]] ; then
      echo "✘ invalid"
      echo 
      echo "https://$AKITA_REPO_HOST"
      prompt_username
    fi
  else
    echo "☕ Username: $NIX_GITLAB_LOGIN ✓"
  fi
}

function prompt_password {
  if [[ -z "$NIX_GITLAB_PASSWORD" ]] ; then 
    echo -n "✍ Password: " && read -s NIX_GITLAB_PASSWORD
    if [[ -z "$NIX_GITLAB_PASSWORD" ]] ; then
      echo "✘ invalid"
      echo 
      echo "https://$AKITA_REPO_HOST"
      prompt_password
    fi
  else
    echo "✍ Password ✓"
  fi
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
  echo "⚠ Your code will be witten to the directory '$CODE_ROOT/$AKITA_REPO_GROUP'. Continue?"
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
}

############################################################

echo "AkitaScreen dev setup helper"

# check for pre-requisite software
echo
prompt_check_prerequisite_software

# check for SSH keys
echo
if [[ $(ls ~/.ssh | grep .pub) ]]; then
  echo "✓ Found public key(s):"
  ls ~/.ssh | grep .pub
  echo
  prompt_key_upload_verification $AKITA_REPO_HOST
else
  echo "✘ No public keys found at ~/.ssh/*.pub"
  echo
  prompt_public_key_creation
  prompt_key_upload_verification $AKITA_REPO_HOST
fi

# check that git uses ssh instead of https
echo
if [ -f ~/.gitconfig ]; then
  prefer_ssh_for_repo $AKITA_REPO_HOST
else 
  use_ssh_insteadof_https $AKITA_REPO_HOST
fi

# verify that code destination dir is set
echo
echo "What is your code root directory?"
echo "(i.e. where you usually write all your code)"
prompt_code_root

# capture akita login details
echo
echo "Verifying login details for $AKITA_REPO_HOST"
prompt_username
prompt_password

mkdir -p $CODE_ROOT/$AKITA_REPO_GROUP

echo
echo "cloning repositories ..."
for r in "backend" "db-consumer" "db-repository" "development-environment" "devops" "logger" "lsports-messages-proxy" "migrator" "pre-match-updates-db-updater" "queue-loader" "virtual-screen" "worker" ; 
  do clone_repo $AKITA_REPO_HOST:$AKITA_REPO_GROUP/$r $CODE_ROOT/$AKITA_REPO_GROUP/$r ; done
clone_repo $AKITA_REPO_HOST:$AKITA_REPO_GROUP/markup $CODE_ROOT/$AKITA_REPO_GROUP/web

for g in "packages" "cron-jobs"; 
  do mkdir $CODE_ROOT/$AKITA_REPO_GROUP/$g; done

echo
echo "packages:"
for r in "lsport-data-importer" "paypal-wrapper" ; 
  do clone_repo $AKITA_REPO_HOST:$AKITA_REPO_GROUP/packages/$r $CODE_ROOT/$AKITA_REPO_GROUP/packages/$r; done

echo
echo "cron-jobs:"
for r in "bookmaker-disabler" "change-user-subscriptions" "clear-recovery-password-tokens" "create-paypal-plans-products" "events-archiver" "import-bookmakers" "import-inplay-events" "import-leagues" "import-locations" "import-markets" "import-outright-leagues" "import-pre-match-events" "import-sports" "market-disabler" "navbar-generate" "order-inplay-events" "remove-canceled-events" ; 
  do clone_repo $AKITA_REPO_HOST:$AKITA_REPO_GROUP/cron-jobs/$r $CODE_ROOT/$AKITA_REPO_GROUP/cron-jobs/$r; done

echo
echo "writing worker override > $CODE_ROOT/$AKITA_REPO_GROUP/development-environment/docker-compose.override.yml"
cat >$CODE_ROOT/$AKITA_REPO_GROUP/development-environment/docker-compose.override.yml <<EOL
version: '3'

services:
  worker:
    build:
      args: 
        NIX_GITLAB_LOGIN: "${NIX_GITLAB_LOGIN}"
        NIX_GITLAB_PASSWORD: "${NIX_GITLAB_PASSWORD}"

  backend:
    build:
      args: 
        NIX_GITLAB_LOGIN: "${NIX_GITLAB_LOGIN}"
        NIX_GITLAB_PASSWORD: "${NIX_GITLAB_PASSWORD}"
  
  in-play-updates-db-updater:
    build:
      args: 
        NIX_GITLAB_LOGIN: "${NIX_GITLAB_LOGIN}"
        NIX_GITLAB_PASSWORD: "${NIX_GITLAB_PASSWORD}"
  
  pre-match-updates-db-updater:
    build:
      args: 
        NIX_GITLAB_LOGIN: "${NIX_GITLAB_LOGIN}"
        NIX_GITLAB_PASSWORD: "${NIX_GITLAB_PASSWORD}"
  
  lsports-messages-proxy:
    build:
      args: 
        NIX_GITLAB_LOGIN: "${NIX_GITLAB_LOGIN}"
        NIX_GITLAB_PASSWORD: "${NIX_GITLAB_PASSWORD}"
        
  virtual-screen:
    build:
      args: 
        NIX_GITLAB_LOGIN: "${NIX_GITLAB_LOGIN}"
        NIX_GITLAB_PASSWORD: "${NIX_GITLAB_PASSWORD}"
        
EOL

echo
echo "writing ~/.netrc file to locally resolve go: https://$AKITA_REPO_HOST/* packages"
cat >$HOME/.netrc <<EOL
machine $AKITA_REPO_HOST login ${NIX_GITLAB_LOGIN} password ${NIX_GITLAB_PASSWORD}
EOL

# cat $CODE_ROOT/$AKITA_REPO_GROUP/development-environment/docker-compose.override.yml

echo
echo "starting local development environment ..."
echo

cd $CODE_ROOT/$AKITA_REPO_GROUP/development-environment
NIX_GITLAB_LOGIN="$NIX_GITLAB_LOGIN" \
NIX_GITLAB_PASSWORD="$NIX_GITLAB_PASSWORD" \
docker-compose build && \
  docker-compose up -d && \
  echo "Running migrations" && \
  make migrage && \
docker-compose ps 