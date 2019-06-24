#!/bin/bash

# Fail on error!
set -e


if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

echo nameserver 216.176.188.2 >> /etc/resolvconf/resolv.conf.d/head
sudo resolvconf -u
sed -i 's/dns-nameservers/#dns-nameservers/' /etc/network/interfaces
sed -i 's/dns-search/#dns-search/' /etc/network/interfaces


# Sysadmins to install!  Make sure to adjust as appropriate
SYSADMIN_LIST="djoslin rob justis adminuser"

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
aptitude update || true
aptitude -y upgrade
aptitude -y install ntp ntpdate screen curl chkconfig build-essential git-core dstat libcurl4-openssl-dev libicu-dev htop sysstat zip xfsprogs

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

yellow "Set up users"
for USER in $SYSADMIN_LIST; do
  green ">>> Adding sysadmin $USER"
  useradd -m $USER -s /bin/bash -G sudo || true
  green ">>>>>> Adding ssh key"
  wget -qO- static.seomoz.org/files/pub/pubid.$USER >> /home/$USER/.ssh/authorized_keys
  chown $USER:$USER /home/$USER/.ssh/authorized_keys
done
#root user
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 644 /root/.ssh/authorized_keys
wget -qO- static.seomoz.org/files/pub/pubid.adminuser >> /root/.ssh/authorized_keys

yellow "Set up NTP"
# Configure ntp
sed -i 's/server ntp.ubuntu.com/server 0.pool.ntp.org/' /etc/ntp.conf
sed -i '/^server 0.pool.ntp.org/a server 1.pool.ntp.org' /etc/ntp.conf
sed -i '/^server 1.pool.ntp.org/a server 2.pool.ntp.org' /etc/ntp.conf
sed -i '/^server 2.pool.ntp.org/a server pool.ntp.org' /etc/ntp.conf
/etc/init.d/ntp stop
ntpdate 0.pool.ntp.org
/etc/init.d/ntp start || true

yellow "Increase ulimits"
# Up the limits
cat >> /etc/security/limits.conf <<LIMITS
root hard nofile 100000
root soft nofile 100000
*    soft nofile 100000
*    hard nofile 100000
LIMITS
perl -pi -e 's/\# session    required   pam_limits.so/session    required   pam_limits.so/' /etc/pam.d/su || true
echo "session required pam_limits.so" >> /etc/pam.d/common-session
echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive

echo
red " * * * "
green "YOU ARE DONE."
yellow " * * * "
