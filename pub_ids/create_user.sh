#!/bin/sh

NAME=$1

if [ -z "$NAME" ]; then
   echo "*** All parameters not supplied."
   exit -1
fi

sudo sh -c 'USERS_LIST="$1";for USER in $USERS_LIST; do useradd -m $USER -s /bin/bash -G sudo; wget -qO- static.seomoz.org/files/pub/pubid.$USER >> /home/$USER/.ssh/authorized_keys;done'
