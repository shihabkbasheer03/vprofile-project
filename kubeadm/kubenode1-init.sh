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

# Verify that the kernel modules are loaded
lsmod | grep br_netfilter
lsmod | grep overlay

# Verify sysctl settings
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

# Update package list and install CRI-O
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

# Create keyrings directory if it doesn't exist
sudo mkdir -p -m 755 /etc/apt/keyrings

# Fetch and add Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the Kubernetes repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package list and install Kubeadm, Kubelet & Kubectl
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

# Hold these packages at their current version
sudo apt-mark hold kubelet kubeadm kubectl

# Enable and start Kubelet
sudo systemctl enable --now kubelet

# Wait for 10 seconds to ensure services are up
sleep 10

# Execute the join command script (this should be present in the /vagrant directory)
if [ -f /vagrant/cltjoincommand.sh ]; then
  /bin/bash /vagrant/cltjoincommand.sh
else
  echo "/vagrant/cltjoincommand.sh not found, skipping join."
fi
