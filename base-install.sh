#!/bin/bash

# Fail on error!
set -e

# ---
# Replication of what DJoslin put into https://sites.google.com/a/seomoz.org/it-operations/documentation/software/installation/base-system-layout,
# but in script format so that we can just run this instead of cut'n'paste

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

if [ -e /usr/bin/aptitude ]; then
  APT=/usr/bin/aptitude
elif [ -e /usr/bin/apt ]; then
  APT=/usr/bin/apt
else
  echo "can't find apt or aptitude" 1>&2
  exit 1
fi

# Some nice functions to make colorful outputs. :)
color() {
  echo -e "\033[0;$1m$2\033[0m"
}
red() {
  color 31 "$1"
}
green() {
  color 32 "$1"
}
yellow() {
  color 33 "$1"
}

if [ -f /tmp/ran_base_install.flag ]; then
  red "Hey, you're re-running this without cleaning up.  That's sketchy.  You shouldn't do that. ;)  I'm not idempotent."
  exit
fi

# And flag that we've run.
touch /tmp/ran_base_install.flag

# Update packages
yellow "Updating/installing packages"
$APT update
$APT -y upgrade
$APT -y install ntp ntpdate screen curl build-essential git-core dstat git htop sysstat zip xfsprogs 


yellow "Setting editor to VI globally"
#globally set editor to vi
update-alternatives --set editor /usr/bin/vim.tiny

yellow "Set up sudo"
#visudo  #uncomment the  %sudo line. Make look like "%sudo ALL=NOPASSWD: ALL"
# or
perl -pi -e 's/\%sudo.+$/\%sudo ALL=NOPASSWD: ALL/' /etc/sudoers || true

yellow "Set up SKEL directory "
mkdir -p /etc/skel/.ssh
chmod 700 /etc/skel/.ssh
touch /etc/skel/.ssh/authorized_keys
chmod 644 /etc/skel/.ssh/authorized_keys

# Sysadmins to install!  Make sure to adjust as appropriate
SYSADMIN_LIST="djoslin rob phildebrand justis"

yellow "Set up users"
for USER in $SYSADMIN_LIST; do
  green ">>> Adding sysadmin $USER"
  useradd -m $USER -s /bin/bash -G adm,sudo || true
  green ">>>>>> Adding ssh key"
  wget -qO-  https://raw.githubusercontent.com/seomoz/ops-pub/master/pub_ids/pubid.$USER >> /home/$USER/.ssh/authorized_keys
  chown $USER:$USER /home/$USER/.ssh/authorized_keys
done

echo
red " * * * "
green "YOU ARE DONE.  Test everything now."
yellow " * * * "
