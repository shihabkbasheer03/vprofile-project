#!/bin/bash
###KUBEMASTER###

# System Settings
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

lsmod | grep br_netfilter
lsmod | grep overlay

sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

# Installing CRI-O

sudo apt-get update -y
sudo apt-get install -y software-properties-common curl apt-transport-https ca-certificates gnupg

# Create the keyrings directory for apt keys
sudo mkdir -p -m 755 /etc/apt/keyrings

# Fetch and add CRI-O GPG key
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

# Add the CRI-O repository
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" | sudo tee /etc/apt/sources.list.d/cri-o.list

# Update and install CRI-O
sudo apt-get update -y
sudo apt-get install -y cri-o

# Enable and start CRI-O
sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl start crio.service

# Installing Kubeadm, Kubelet & Kubectl
KUBEVERSION=v1.30
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Fetch and add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the Kubernetes repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update and install Kubeadm, Kubelet & Kubectl
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Enable and start Kubelet
sudo systemctl enable --now kubelet

# Waiting for 12 seconds before initialization
sleep 12
echo "Waiting for 120 Seconds...."
echo "Let's initialize."

# Kubeadm initialization
IPADDR=192.168.33.2
POD_CIDR=10.244.0.0/16
NODENAME=kubemaster
kubeadm init --control-plane-endpoint=$IPADDR --pod-network-cidr=$POD_CIDR --node-name $NODENAME --ignore-preflight-errors Swap &>> /tmp/initout.log

# Wait for the kubeadm init process to complete
sleep 10

# Create the necessary directory for kubectl
cat /tmp/initout.log | grep -A2 mkdir | /bin/bash

# Give some time to finish the setup
sleep 10

# Output join command to be used by worker nodes
tail -2 /tmp/initout.log > /vagrant/cltjoincommand.sh
