#!/usr/bin/env bash
set -e

echo "Executing easy-sshd-ubuntu-1604 entrypoint script"

if [! -e "/root/.secret-ssh-keys/ssh-key.pub"]; then
  echo "Public key not found at /root/.secret-ssh-keys/ssh-key.pub"
  exit 1;
fi

if [! -e "/root/.secret-ssh-keys/ssh-key"]; then
  echo "Private key not found at /root/.secret-ssh-keys/ssh-key.pub"
  exit 1;
fi

cp /root/.secret-ssh-keys/ssh-key.pub /root/.ssh/authorized_keys
cp /root/.secret-ssh-keys/ssh-key /root/.ssh/ssh-key
chmod 600 /root/.ssh/authorized_keys
chmod 600 /root/.ssh/ssh-key

cp /etc/resolv.conf /tmp/resolv.conf
sed -i -e "/^search/s/$/ `hostname -f | cut -d '.' -f 2-`/" /tmp/resolv.conf
cp /tmp/resolv.conf /etc/resolv.conf
rm /tmp/resolv.conf

echo "CanonicalizeHostname yes" >> /root/.ssh/config
echo "CanonicalDomains "`hostname -f | cut -d '.' -f 2-`" "`hostname -f | cut -d '.' -f 3-` >> /root/.ssh/config
ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'|awk -F. '{print "Host " $1"."$2"*.*"}' >> /root/.ssh/config
echo "  StrictHostKeyChecking no" >> /root/.ssh/config
echo "  UserKnownHostsFile=/dev/null" >> /root/.ssh/config
echo "  IdentityFile ~/.ssh/ssh-key" >> /root/.ssh/config
echo "Host *."`hostname -f | cut -d '.' -f 3-` >> /root/.ssh/config
echo "  StrictHostKeyChecking no" >> /root/.ssh/config
echo "  UserKnownHostsFile=/dev/null" >> /root/.ssh/config
echo "  IdentityFile ~/.ssh/ssh-key" >> /root/.ssh/config

/usr/sbin/sshd -D
