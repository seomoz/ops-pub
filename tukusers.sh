#! /bin/bash

USERS="avery.crespi
carlos.westman
corbin.graham
daphne.mui
dima.zhuravel
djoslin
goutam.sahoo
hahn.miao
jason
jesse.brown
justis
kamal.abdulwahab
maksym.bykovskyy
michael.greenwell
moz
namrata
seomoz
shravan.kumar
sivasankar.ganta
sushil.kumar
vinitmahedia"

# clean up old users
CURRENT_USERS=$(ls -1 /home)
for CURRENT_USER in $CURRENT_USERS; do
  echo $USERS|grep -w $CURRENT_USER 1>/dev/null
  if [ "$?" = 1 ]; then
    echo "Removing $CURRENT_USER"
    sudo userdel -r $CURRENT_USER
    if [ -e /home/$CURRENT_USER ]; then
      sudo rm -rf /home/$CURRENT_USER
    fi
  fi
done

# If user does not existm add them.
for USER in $USERS; do
  if [ ! -e /home/$USER ]; then
    echo "Adding $USER"
    sudo useradd -m $USER -s /bin/bash -G sudo
    curl -s https://raw.githubusercontent.com/seomoz/ops-pub/master/pub_ids/pubid.$USER |\
      sudo tee -a /home/$USER/.ssh/authorized_keys -a /home/seomoz/.ssh/authorized_keys
  fi
done
