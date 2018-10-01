#!/bin/bash

# test for root
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


# Full path to the MegaRaid CLI binary
BC="/usr/bin/bc"
MegaCli="/usr/sbin/megacli"
SmartCTL="/usr/sbin/smartctl"
AptUpdate=0

if [ ! -e $MegaCli ]; then
    CODENAME=`grep CODENAME /etc/lsb-release |cut -d"=" -f2`
    echo "deb http://hwraid.le-vert.net/ubuntu $CODENAME main" >> /etc/apt/sources.list
    wget -O - http://hwraid.le-vert.net/debian/hwraid.le-vert.net.gpg.key | sudo apt-key add -
    AptUpdate=1
    $APT update
    $APT -y install megacli
fi

if [ ! -e $SmartCTL ] || [ ! -e $BC ] ; then
    if [ "$AptUpdate" = 0 ]; then
      $APT update
    fi
    $APT install smartmontools heirloom-mailx bc
fi

DEVICES=$($MegaCli -PDList -aALL|grep ^Device\ Id|awk '{print $3}')

for DEVICE in $DEVICES; do
  INFO=$($SmartCTL -d megaraid,$DEVICE /dev/sda --all|grep -E 'overall-health|Power_On_Hours|Wear_Leveling_Count|Total_LBAs_Written|Size:|Model:|Capacity:|"Sector Size:"')
  if [ "$(echo "$INFO" | grep -c "Wear_Leveling_Count")" -eq 1 ]; then
    SECTOR=$(echo "$INFO" | grep Sector | awk '{print $3}')
    MODEL=$(echo "$INFO" | grep Model | awk '{for(i=3; i<=NF; ++i) printf "%s ", $i; print ""}')
    AGE=$(echo "$INFO" | grep Power_On | awk '{print $10/8760}')
    AGE=$(echo "scale=2; $AGE" |bc)
    WEAR=$(echo "$INFO" | grep Wear_Leveling | awk '{print $4}')
    LBAW=$(echo "$INFO" | grep Total_LBAs | awk '{print $10}')
    TBW=$(echo "scale=1; $LBAW*$SECTOR/1099511627776" | bc)
    echo "Device:$DEVICE, Age:$AGE years, Wear(0=bad,100=good):$WEAR, TB_written:$TBW"
    echo "  Model: $MODEL"
  else
    echo "Device:$DEVICE is not and SSD"
  fi
done
