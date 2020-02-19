#!/bin/bash

#diagnose this script
#set -x

branch=
wipbranch=

#########################################################
# beginPair
# Create and checkout branch and branch-wip as appropriate
# so that you are ready to pair. Both partners should invoke this
#
beginPair(){

  # b1.0 Information message

  echo "INFO: -init ${branch}"
  echo "INFO: You have requested to pair on branch '${branch}'."
  echo "INFO: This script will create branch '${branch}' and a working branch '${wipbranch}' if they do not already exist."
  echo "INFO:"
  echo "INFO: Instructions:"
  echo "INFO: Your partner should also call 'zpair.sh -init ${branch}'"
  echo "INFO: You should both commit changes to the working branch '${wipbranch}' using standard 'git push' and 'git pull'"
  echo "INFO: Once pairing session is complete, call 'zpair.sh -pub ${branch}' to squash and commit to ${branch}."


  # b2.0 Attempt to create or checkout the branch

  git fetch origin ${branch} > /dev/null 2>&1
  git checkout -b ${branch} --track origin/${branch} -q > /dev/null 2>&1
  result="$?"
  if [[ "${result}" -ne "0" ]] ; then
     echo "DEBUG: branch '${branch}' already exists, just checkout"
     git checkout -b ${branch} -q > /dev/null 2>&1
  fi

  # b3 Attempt to create or checkout the wip branch

  git fetch origin ${wipbranch} > /dev/null 2>&1
  git checkout -b ${wipbranch} --track origin/${wipbranch} -q > /dev/null 2>&1
  result="$?"
  if [[ "${result}" -ne "0" ]] ; then
     echo "DEBUG: wip-branch '${wipbranch}' already exists, just checkout"

     git checkout -b ${wipbranch} -q > /dev/null 2>&1

     if [[ "${result}" -ne "0" ]] ; then

       # b4 If wipbranch already exists ... because response to checkout was not zero
       #     now reset branch and tidy up wipbranch (if it has been used in previous pair session)

       echo "INFO: Not first use of this wip-branch '${wipbranch}'."
       echo "DEBUG:   Will reset ${wipbranch} to ${branch} by issuing 'reset --hard origin/${branch}'"
       git fetch
       # Won't reset if we haven't yet pushed origin/branch - maybe need to check if it exists first?
       git reset --hard origin/${branch}
       git push -f origin ${wipbranch}

     else
       # b5: Setup wip-branch for first time
       #
       echo "INFO: Setup wip-branch ${wipbranch} for first time"
       echo "DEBUG: set upstream to origin/${wipbranch}"
       git push --set-upstream origin ${wipbranch} > /dev/null 2>&1
       #git branch --set-upstream-to=origin/${wipbranch} ${wipbranch}
     fi

  fi

  # b5 Ensure the wip branch is on remote origin

  git push origin ${wipbranch}
  git pull origin ${wipbranch}

  echo "INFO: Ready to pair. You are on branch '${wipbranch}'"
  echo "INFO: Use 'git push' and 'git pull' to ping/pong between remote pair partners on this branch"
  echo "INFO: "
  echo "INFO: When ready to publish, invoke this script zpair.sh with '-pub', which will interactively squash your commits and then publish to ${branch} and reset ${branch-wip} ready for your next pairing session"
  echo " "

  git status
}

#########################################################
# publishToBranch
#
# Will publish commits from wipbranch to branch, and cleanup wipbranch ready for next pairing
#
publishToBranch(){
  echo "INFO: publishing to ${branch}, you will be prompted to interactively 'rebase squash' before push"

  # p1: Switch to branch and add the commits from wipbranch
  git checkout $branch
  git rebase $wipbranch
  if [[ "$?" -ne "0" ]] ; then
    echo "failed during rebase"
    exit -1
  fi

  # p2: Now offer the chance to squash all commits since branch
  git rebase -i ${branch}
  if [[ "$?" -ne "0" ]] ; then
    echo "failed interactive rebase squash"
    exit -1
  fi

  # p3: Finally push branch, to publish it
  git push origin ${branch}
}

# h1 Handle command line options
# and invoke appropriate function

if [ "$#" != "2" ]; then
  echo "Zpair command options:"
  echo " "
  echo "zpair [ -init || -pub ] <branch>"
  echo " "
  echo "-init <branch>   Initialises this pairing session, by creating <branch> and <branch-wip> if they don't exist, and checkout <branch-wip>"
  echo " "
  echo "-pub <branch>    Publishes changes committed on <branch-wip>, to <branch>.  First rebases interactively to offer the opportunity to squash commits"
  exit 0
fi

branch=$2
wipbranch="${branch}-wip"

if [ "$1" == "-pub" ]; then
    publishToBranch
else
    beginPair
fi
