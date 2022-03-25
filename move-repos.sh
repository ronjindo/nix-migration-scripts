#!/bin/bash

AKITA_REPO_HOST='gitlab.nixdev.co'
JINDO_REPO_HOST='github.com/jindogroup'
AKITA_REPO_GROUP='lsport'
JINDO_REPO_GROUP='jindogroup'
CODE_ROOT="/code"
NIX_GITLAB_LOGIN=$1
NIX_GITLAB_PASSWORD=$2
GITHUB_TOKEN=$(head -n 1  ~/.github/token)
CURRENT_DIR=$(pwd)

source functions.sh

function process_repo {
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
  cd $2
  # git fetch --all
  # git pull --all
  git fetch --prune --tags origin
  # branches=()
  # eval "$(git for-each-ref --shell --format='branches+=(%(refname))' refs/heads/)"
  for branch in $(git branch -r); do
      # branch="${ref##*/}"
      if [[ ! -z $(echo $branch | grep jindo) ]] ; then
        echo "skipping $branch"
        continue 2
      fi
      echo "git checkout $branch"
      echo "-------------------------------------------------------------------------"
      echo $branch | sed 's/origin\///g'
      branch=$(echo $branch | sed 's/origin\///g')
      git checkout $branch
      git stash && git pull origin $branch --no-edit -X theirs
      echo "processing branch $branch"
      replace_nix_repo_imports "$AKITA_REPO_HOST/$AKITA_REPO_GROUP/cron-jobs" "$JINDO_REPO_HOST"
      replace_nix_repo_imports "$AKITA_REPO_HOST/$AKITA_REPO_GROUP/packages" "$JINDO_REPO_HOST"
      replace_nix_repo_imports "$AKITA_REPO_HOST/$AKITA_REPO_GROUP" "$JINDO_REPO_HOST"
      replace_nix_repo_imports "gitlab.nixdev.co" "github.com"
      if [[ `git status --porcelain` ]]; then
        git add .
        git commit -m "renamed imports"
      fi
      git push jindo $branch 
      git push --tags jindo $branch 
  done
  repo_name=akitascreen-$3
  repo_url="git@github.com:jindogroup/$repo_name.git"
  if [[ -z $(git remote -v | grep jindo) ]] ; then 
    echo "creating $repo_name" && \
    gh repo create jindogroup/$repo_name --private && \
    git remote add jindo $repo_url
  fi  
  echo remote...
  git remote -v | grep jindo
  echo "pushing jindo:$repo_name to git@github.com:jindogroup/$repo_name.git" && \
  git push --mirror jindo && \
  echo "git push --all" && \
  git push --all jindo && \
  echo "git push --tags" && \
  git push --tags jindo && echo 
  cd $CURRENT_DIR
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
}

############################################################

echo "AkitaScreen repo migrator"

# check for pre-requisite software
echo
prompt_check_prerequisite_software

# capture akita login details
echo
echo "Verifying login details for $AKITA_REPO_HOST"
NIX_GITLAB_LOGIN=`prompt_username $NIX_GITLAB_LOGIN | tail -n 1`
NIX_GITLAB_PASSWORD=`prompt_password $NIX_GITLAB_PASSWORD | tail -n 1`
echo `prompt_password $AKITA_REPO_HOST $NIX_GITLAB_PASSWORD`
mkdir -p $CODE_ROOT/$JINDO_REPO_GROUP

echo
echo "processing repositories ..."
for r in $(cat repos/base) ; 
  do process_repo $AKITA_REPO_HOST:$AKITA_REPO_GROUP/$r $CODE_ROOT/$JINDO_REPO_GROUP/$r $r ; done
process_repo $AKITA_REPO_HOST:$AKITA_REPO_GROUP/markup $CODE_ROOT/$JINDO_REPO_GROUP/web web

for g in "packages" "cron-jobs"; 
  do mkdir $CODE_ROOT/$JINDO_REPO_GROUP/$g; done

echo
echo "packages:"
for r in $(cat repos/packages) ; 
  do process_repo $AKITA_REPO_HOST:$AKITA_REPO_GROUP/packages/$r $CODE_ROOT/$JINDO_REPO_GROUP/$r $r; done

echo
echo "cron-jobs:"
for r in $(cat repos/cron-jobs) ; 
  do process_repo $AKITA_REPO_HOST:$AKITA_REPO_GROUP/cron-jobs/$r $CODE_ROOT/$JINDO_REPO_GROUP/$r $r; done

