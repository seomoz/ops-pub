#! /bin/bash

# Configure AWS MAS Account host to log to devo relay.
# Cleans up some legacy stuff.
# curl -s https://raw.githubusercontent.com/seomoz/ops-pub/master/devo-config.sh|bash

TEAMTAG=legacy

if [[ $EUID -ne 0 ]]; then
  sudo -i
fi

if [ ! -e /etc/rsyslog.d ]; then
  echo "/etc/rsyslog.d not found"
  exit 1
fi

devo8 () {
cat > /etc/rsyslog.d/00-devo.conf <<DATA
module(
    load="imfile"
    mode="inotify"
)

module(
    load="immark"
    interval="60"
)

module(load="imjournal" ratelimit.interval="0")

global(
    workDirectory="/var/spool/rsyslog"
)
DATA

cat > /etc/rsyslog.d/49-devo.conf <<DATA2
template(
    name = "box-unix"
    type = "string"
    string = "<%PRI%>%timegenerated% %HOSTNAME%[$TEAMTAG] box.unix.%syslogtag% %msg%"
)

action(
    type="omfwd"
    template="box-unix"
    queue.type="LinkedList"
    queue.filename="boxq1"
    queue.saveonshutdown="on"
    action.resumeRetryCount="-1"
    Target="10.40.2.22"
    Port="13000"
    Protocol="tcp"
)
DATA2
}

devo5 () {
cat > /etc/rsyslog.d/49-devo.conf <<DATA2
\$template box-unix,"<%PRI%>%TIMESTAMP:::date-rfc3339% %HOSTNAME%[$TEAMTAG] box.unix.%syslogtag:1:32%%msg:::sp-if-no-1st-sp%%msg%"

*.* @@10.40.2.22:13000;box-unix
DATA2
}

RSYSLOGV=`rsyslogd -v|head -n1|awk {'print substr($2,1,1)'}`
if [[ $RSYSLOGV -eq 8 ]]; then
  devo8
elif [[ $RSYSLOGV -eq 5 || $RSYSLOGV -eq 7 ]]; then
  devo5
else
  echo "rsyslog not v5, v8, or not installed"
  exit 1
fi

OLDFILES="05-auth.conf
10-mozstash::emitter-forward-to-collector.conf
11-mozcookbook_devops_logging.conf
22-alert-logic.conf"

for FILE in $OLDFILES; do
  if [ -e /etc/rsyslog.d/$FILE ]; then
    rm /etc/rsyslog.d/$FILE
  fi
done

service rsyslog restart

logger "$(hostname) installed"

if [ -e /var/alertlogic ]; then
  if [ -e /usr/bin/apt ]; then
    apt purge -y al-agent
  else
    aptitude purge -y al-agent
  fi
  rm -rf /var/alertlogic
fi

if [ -e /opt/dataloop ]; then
  if [ -e /usr/bin/apt ]; then
    apt purge -y dataloop-agent
  else
    aptitude purge -y dataloop-agent
  fi
  rm -rf /opt/dataloop /var/log/dataloop /etc/dataloop
fi

if [ -e /etc/zabbix ]; then
  if [ -e /usr/bin/apt ]; then
    apt purge -y zabbix-agent
  else
    aptitude purge -y zabbix-agent
  fi
fi

if [ -e /opt/chef ]; then
  if [ -e /usr/bin/apt ]; then
    apt purge -y chef
  else
    aptitude purge -y chef
  fi
  rm -rf /opt/chef /var/log/chef /etc/chef
fi
