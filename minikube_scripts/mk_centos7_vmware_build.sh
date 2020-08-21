# Building Minikube Lab on CentOS7 VM in VMWare Workstation 15.5

## To download VMWare Workstation Player for Windows:
#  https://www.vmware.com/go/getplayer-win

## To download VMWare Workstation Player for Linux:
#  https://www.vmware.com/go/getplayer-linux

## prior to vm launch
#  Go to Virtual Machine Settings > Hardware > Processors > Virtualization engine then enable Virtualize Intel VT-x/EPT or AMD-V/RVI

## create sudo privs
visudo
<username> ALL=(ALL) NOPASSWD:ALL

## switch to root
sudo su

## base yum installs
yum install -y yum-utils conntrack socat lvm2 && sudo yum update

## install docker
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker
usermod -aG docker $USER && newgrp docker

## install kubelet, kubeadm, kubectl
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
yum install -y kubelet, kubectl, kubeadm
systemctl enable kubelet
systemctl start kubelet

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

## install crictl (CLI for CRI-compatible container runtimes)
VERSION="v1.17.0"
curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-${VERSION}-linux-amd64.tar.gz --output crictl-${VERSION}-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz

## install golang
VERSION="1.15"
curl -O https://dl.google.com/go/go${VERSION}.linux-amd64.tar.gz
tar -xvf go$VERSION.linux-amd64.tar.gz
sudo chown -R root:root ./go
sudo mv go /usr/local
mkdir -p ~/go/src/hello && cd ~/go/src/
export PATH=$PATH:/usr/local/go/bin
echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc

## install helm
cd ~/go/src/
curl -Lo helm-v3.0.0.tar.gz https://github.com/helm/helm/archive/v3.0.0.tar.gz
tar -zvxf helm-v3.0.0.tar.gz
rm -f helm-v3.0.0.tar.gz
cd helm-3.0.0
make
sudo mv bin/helm /usr/bin/
cd ~/
sudo rm -rf go*

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


