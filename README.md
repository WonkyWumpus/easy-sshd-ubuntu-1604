# easy-sshd-ubuntu-1604

## Overview

This project eases the deployment of Ubuntu 16.04 containers running sshd that can then be used much like fully-functional virtual machines.  The automation of key generation and distribution and some changes to dns resolution and ssh behavior allows users image to focus on high-level activities, instead of stuggling with dns and networking issues inside their cluster.  The dockerfiles here also avoid the bad practice of hard-coding passwords into your sshd containers.

The development and testing of this project has been on a VirtualBox-based minikube Kubernetes cluster hosted on OSX. Portions of the project will be useful in other Container orchestration environments, but modifications will be required.

This project takes advantage of the Kubernetes dns service to create entries that will allow us to address our containers via hostnames instead of the explicit service definitions that are expected from microservice based applications.  The key is creating a headless service and attaching to pods via the subdomain attribute in pods. The [DNS Pods and Services](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) section of the Kubernetes documentation explains the requirements:

>If there exists a headless service in the same namespace as the pod and with the same name as the subdomain, the cluster’s KubeDNS Server also returns an A record for the Pod’s fully qualified hostname.

The general flow to create your containers

1. Create Public/Private RSA key pair
2. Store key pair in minikube VM and on hostmachine
3. Create Kubernetes Secret named `easy-keys` containing key pair
4. Create Kubernetes headless service name `easy`
5. Create Ubuntu 16.04 single container Kubernets Pod(s)

The dockerfile for the Ubuntu images performs several steps at startup

1. Copy key pair that must be mounted at /root/.secret-easy-keys into ssh enviornment
2. Make changes to resolv.conf and .ssh/config to ease shortname resolution and key usage for ssh
3. Launchs sshd

It is important to note that your pods must define their subdomain is easy and they must mount the key pair secret into /root/.secret-easy-keys.  Sample .yaml files are provided.


## Instructions

If you are running minikube for your Kubernetes cluster there is a helpful script to generate your keys and drop them into the minikube VM, into your hostmachine at $HOME/.ssh/easy-key, and as a Kubernetes secrete named easy-keys.

`easy-sshd-ubuntu-1604/bin/minikube-build-keys-and-secret.sh`

Once this is done your can create your easy service

`kubectl create -f easy-sshd-ubuntu-1604/kube-yamls/easy-network-service.yaml`

Next run the sample .yaml to create five containers

`kubectl create -f easy-sshd-ubuntu-1604/kube-yamls/easy-5-machines.yaml`

You are up and running.  Test that you can connect from your minikube VM into the machines and between machines in the cluster.  From the minikube VM you will need to discover the IP of one of the machines and to pass the identify file manually.  Once inside a container on the cluster shortnames will work and the correct key will get passed automatically

`minikube ssh`

`kubectl describe pod m01|grep IP`

`ssh -i .ssh/easy-key root@<ip address returned from above command>`

`ssh root@m02`


## Errata and Future Enhancements

1. Version of minikube-build-keys-and-secret.sh work with all Kubernetes environments, not just minikube
2. minikube-build-keys-and-secret.bat for windows hosts
3. Avoid need to find IPs from minibue VM (maybe proper service defs and similar shortname configs inside VM itself). Maybe as a single jumpserver into the cluster.


