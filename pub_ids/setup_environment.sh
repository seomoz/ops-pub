#!/bin/bash

# Allow users in "sudo" group to sudo without password
perl -pi -e 's/\%sudo\s+ALL=\(ALL:ALL\)\s+ALL/\%sudo ALL=NOPASSWD: ALL/' /etc/sudoers

# For ubuntu 10.04 and earlier, the command is slightly different
perl -pi -e 's/\%sudo\ ALL=\(ALL\)\ ALL/\%sudo\ ALL\=NOPASSWD\:\ ALL/i' /etc/sudoers

# Gather user login information and create accounts
USERS_LIST="`curl -q http://static.seomoz.org/files/pub/pubid_users`"
for USER in $USERS_LIST; do
  useradd -m $USER -s /bin/bash -G adm,sudo
  USER_DIR="/home/$USER"
  mkdir -p $USER_DIR/.ssh/
  sudo chown -R $USER:$USER $USER_DIR
  USER_PATH="wget -qO- static.seomoz.org/files/pub/pubid.$USER"
  USER_AUTH="/home/$USER/.ssh/authorized_keys"
  $USER_PATH >> $USER_AUTH
done
