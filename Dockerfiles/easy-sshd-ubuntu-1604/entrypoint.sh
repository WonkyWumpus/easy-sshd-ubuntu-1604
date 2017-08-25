#!/usr/bin/env bash
set -e

echo "Executing easy-sshd-ubuntu-1604 entrypoint script"

if [ ! -e "/root/.secret-easy-keys/easy-key.pub" ]; then
  echo "ERROR: Public key not found at /root/.secret-easy-keys/easy-key.pub"
  exit 1;
fi

if [ ! -e "/root/.secret-easy-keys/easy-key" ]; then
  echo "ERROR: Private key not found at /root/.secret-easy-keys/easy-key.pub"
  exit 1;
fi

echo "Copying key files and setting permissions"
cp /root/.secret-easy-keys/easy-key.pub /root/.ssh/authorized_keys
cp /root/.secret-easy-keys/easy-key /root/.ssh/easy-key
chmod 600 /root/.ssh/authorized_keys
chmod 600 /root/.ssh/easy-key

echo "Adding domain names to dns resolution"
cp /etc/resolv.conf /tmp/resolv.conf
sed -i -e "/^search/s/$/ `hostname -f | cut -d '.' -f 2-`/" /tmp/resolv.conf
cp /tmp/resolv.conf /etc/resolv.conf
rm /tmp/resolv.conf

echo "Changing ssh config file for ease of connections using key files"
echo "CanonicalizeHostname yes" >> /root/.ssh/config
echo "CanonicalDomains "`hostname -f | cut -d '.' -f 2-`" "`hostname -f | cut -d '.' -f 3-` >> /root/.ssh/config
ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'|awk -F. '{print "Host " $1"."$2"*.*"}' >> /root/.ssh/config
echo "  StrictHostKeyChecking no" >> /root/.ssh/config
echo "  UserKnownHostsFile=/dev/null" >> /root/.ssh/config
echo "  IdentityFile ~/.ssh/easy-key" >> /root/.ssh/config
echo "Host *."`hostname -f | cut -d '.' -f 3-` >> /root/.ssh/config
echo "  StrictHostKeyChecking no" >> /root/.ssh/config
echo "  UserKnownHostsFile=/dev/null" >> /root/.ssh/config
echo "  IdentityFile ~/.ssh/easy-key" >> /root/.ssh/config

echo "Launching sshd"
/usr/sbin/sshd -D
