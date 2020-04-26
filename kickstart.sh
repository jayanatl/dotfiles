#!/bin/bash
###############################################################################
# Script to setup development environment in my workstation                   #
###############################################################################

# TODO:
# Generate local log file

# Exit incase of any error
set -e

[[ ${PWD} != ${HOME} ]] && {
  echo "Going HOME(${HOME})..."
  echo "Run 'popd' if something goes wrong"
  pushd ${HOME} >/dev/null
}

# Grab library and load it
curl -L https://raw.githubusercontent.com/jayanatl/dotfiles/jayan_centos7/bin/common.sh > /tmp/common.sh
source /tmp/common.sh || { echo Unable to load common.sh; exit 127; }

OS=$(this_os)
user_checks

#read -r -p "Do you want to reboot after completion: (n)? " REBOOT
#[[ $REBOOT =~ ^(y|Y)$ ]] && REBOOT=y || REBOOT=n

case ${OS} in
  Darwin | darwin)
    echo "Mac OS detected, Enterprise OS Team manages packages"
    xcode-select --install
    ;;

  centos | redhat | fedora)
    sudo yum install git zip tar gcc -y
    ;;

  fedora)
    sudo dnf install git zip tar gcc -y
    ;;
  
  *)
    echo "Sorry, OS: ${OS}, currently not supported by this script"
    exit 127
    ;;
esac


echo Setting up repo url
branch=${1:-"refactor_mac"}
gitRepo=${2:-"jayanatl/dotfiles"}

if [[ ${gitRepo} =~ ^http.*.git$ ]]; then
  repoUrl=${gitRepo}
else
  repoUrl="https://github.com/${gitRepo}.git"
fi
echo "Repo URL   : ${repoUrl}"
echo "Repo Branch: ${branch}"


echo Creating dotfiles_archive folder
DOTBKP=".dotfiles_backup"
mkdir -p "${DOTBKP}/repo"


echo Arciving old copy of dotfiles if present
if [ -d .dotfiles ]; then
  epoch=$(date +%s)
  echo "Creating .dotfiles repo backup: ${DOTBKP}/repo/dotfiles.${epoch}.zip"
  zip -r "${DOTBKP}/repo/dotfiles.${epoch}.zip" .dotfiles || { error Zip file creation filed, exiting; exit 127; }
  rm -rvf .dotfiles
fi

echo Settting up new local repo from repository
git clone ${repoUrl}
mv dotfiles .dotfiles
cd .dotfiles
sed -i.bak '/url/s|https://\(.*.com\)/|git@\1:|' .git/config
git checkout ${branch}

currentBranch=$(git rev-parse --abbrev-ref HEAD)
if [[ ${currentBranch} != ${branch} ]]; then
  echo Creating a branch from ${currentBranch}, for new changes
  new_br=${USER}_${HOSTNAME}
  git checkout -b ${new_br}
fi

# Start execution
for step in $(list_install_steps); do
    echo ${step}/install.sh
done

# Place for post install config?

# Return to the directory where execution started
((${POPD:-0})) && popd
