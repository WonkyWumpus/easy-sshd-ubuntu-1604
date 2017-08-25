#!/usr/bin/env bash

echo "###"
echo "### WARNING"
echo "###"
echo "### This script will delete easy-keys stored in minikube and on your host machine."
echo "### It will also replace your kubernetes secret named easy-keys"
echo "### You could loose ssh access to existing containers"
echo "###"
echo ""
read -p "Do you wish to continue (Yy/Nn)? " -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "Generating and replacing keys and secret"
  mkdir -p $HOME/easy-keys
  eval $(minikube docker-env)
  minikube ssh "mkdir -p .ssh"
  minikube ssh "docker run wonkywumpus/keygen-ubuntu-1604:0.10 | tee >(head -n 1 > /home/docker/.ssh/easy-key.pub)|tail -n +2>/home/docker/.ssh/easy-key"
  minikube ssh ' (cat /home/docker/.ssh/easy-key.pub )'  > $HOME/easy-keys/easy-key.pub
  minikube ssh ' (cat /home/docker/.ssh/easy-key) '  > $HOME/easy-keys/easy-key
  minikube ssh 'chmod 600 /home/docker/.ssh/easy-key'
  kubectl delete secret easy-keys
  kubectl create secret generic easy-keys --from-file=$HOME/easy-keys
  echo "Complete"
  exit 0
fi

