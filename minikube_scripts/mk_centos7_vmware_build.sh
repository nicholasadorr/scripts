# Building Minikube Lab on CentOS7 VM in VMWare Workstation 15.5

## To download VMWare Workstation Player for Windows:
#
#  https://www.vmware.com/go/getplayer-win

## To download VMWare Workstation Player for Linux:
#
#  https://www.vmware.com/go/getplayer-linux

## prior to vm launch
#
# Go to Virtual Machine Settings > Hardware > Processors > Virtualization engine then enable Virtualize Intel VT-x/EPT or AMD-V/RVI

## create sudo privs
visudo
<username> ALL=(ALL) NOPASSWD:ALL

## base yum installs
sudo yum install -y yum-utils conntrack socat lvm2 && sudo yum update

## install docker
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER && newgrp docker

## install kubectl
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
sudo systemctl enable kubelet

## switch to root
sudo su

## set docker daemon
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

## disable swap
swapoff -a
sed -i 's/^\(.*swap.*\)$/#\1/' /etc/fstab

## disable SELinux
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

## enable ip forwarding
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

## set containerd
cat > /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --systeme
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
systemctl restart containerd

## exit root
exit

## install minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
sudo mkdir -p /usr/bin/
sudo install minikube /usr/bin/

## start minikube
sudo minikube start --driver=none

## watch build in another terminal
watch -d docker ps -a

## config minikube
minikube config set driver none
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

