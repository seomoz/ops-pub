#!/bin/bash

# Fail on error!
set -e

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
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
apt update || true
apt -y upgrade
apt -y install ntp ntpdate screen curl build-essential git dstat htop sysstat zip pdns-recursor net-tools smartmontools

yellow "Setting editor to VI globally"
#globally set editor to vi
update-alternatives --set editor /usr/bin/vim.tiny

yellow "Set up sudo"
#visudo  #uncomment the  %sudo line. Make look like "%sudo ALL=NOPASSWD: ALL"
# or
perl -pi -e 's/\%sudo.+$/\%sudo ALL=NOPASSWD: ALL/' /etc/sudoers || true

yellow "Disable PW Logins"
# Disable ssh pw logins
perl -pi -e 's/yes/no/' /etc/ssh/sshd_config.d/50-cloud-init.conf

yellow "Set up SKEL directory "
mkdir -p /etc/skel/.ssh
chmod 700 /etc/skel/.ssh
touch /etc/skel/.ssh/authorized_keys
chmod 644 /etc/skel/.ssh/authorized_keys

yellow "Set up users"
SYSADMIN_LIST="djoslin justis adminuser"
for USER in $SYSADMIN_LIST; do
  green ">>> Adding sysadmin $USER"
  useradd -m $USER -s /bin/bash -G sudo || true
  green ">>>>>> Adding ssh key"
  wget -qO- https://raw.githubusercontent.com/seomoz/ops-pub/master/pub_ids/pubid.$USER >> /home/$USER/.ssh/authorized_keys
  chown $USER:$USER /home/$USER/.ssh/authorized_keys
done
#root user
#mkdir -p /root/.ssh
#chmod 700 /root/.ssh
#touch /root/.ssh/authorized_keys
#chmod 644 /root/.ssh/authorized_keys
#wget -qO-  https://raw.githubusercontent.com/seomoz/ops-pub/master/pub_ids/pubid.adminuser >> /root/.ssh/authorized_keys

yellow "Set up NTP"
timedatectl set-timezone America/Los_Angeles
systemctl stop ntp
ntpdate ntp.ubuntu.com
systemctl start ntp || true

yellow "Configure dns to use pdns-recorsor"
systemctl stop systemd-resolved
systemctl disable systemd-resolved.service
perl -pi -e 's/1.1.1.1/127.0.0.1/' /etc/netplan/50-cloud-init.yaml || true
rm /etc/resolv.conf
echo "nameserver 127.0.0.1" > /etc/resolv.conf
# netplan --debug apply
# netstat -lnp| grep :53

#rapid7
#wget https://infos.moz.com/agent_installer.sh
#bash ./agent_installer.sh install_start --token "us:6610b76e-23dd-490e-8c9b-181a182cfa04" --attributes "MOZ,IDINA-CRAWLER,PROD"

#crowdstrike
curl https://infos.moz.com/falcon-sensor_7.11.0-16407_amd64.deb -Os
apt install -y ./falcon-sensor_7.11.0-16407_amd64.deb
/opt/CrowdStrike/falconctl -s --cid=$CROWDSTRIKE_KEY
/opt/CrowdStrike/falconctl -s --tags="IDINA-CRAWLER,PROD"
systemctl start falcon-sensor


echo
red " * * * "
green "YOU ARE DONE. Reboot reccomended"
yellow " * * * "

#sudo reboot
