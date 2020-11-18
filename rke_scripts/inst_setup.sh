## setup script ##

sudo su

cat <<EOF >> /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum install git vim gcc socat dep kubeadm -y
yum install -y yum-utils   device-mapper-persistent-data   lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io -y

systemctl start docker

curl -o /usr/bin/rke -L https://github.com/rancher/rke/releases/download/v1.1.12/rke_linux-amd64
chmod +x /usr/bin/rke
rke --version

swapoff -a
sed -i '/ swap / s/^(.*)$/#\1/g' /etc/fstab


exit

curl -O https://dl.google.com/go/go1.15.linux-amd64.tar.gz
tar -xvf go1.15.linux-amd64.tar.gz
rm -f go1.15.linux-amd64.tar.gz
sudo chown -R root:root ./go
sudo mv go /usr/local
mkdir -p ~/go/src/hello && cd ~/go/src/
export PATH=$PATH:/usr/local/go/bin
echo export PATH=$PATH:/usr/local/go/bin >> ~/.bashrc
cd

curl -o helm-v3.4.1.tar.gz -L https://github.com/helm/helm/archive/v3.4.1.tar.gz
tar -zvxf helm-v3.4.1.tar.gz
rm -f helm-v3.4.1.tar.gz
cd helm-3.4.1
make
sudo mv bin/helm /usr/bin
cd
rm -f helm-3.4.1

cat <<EOF >> ~/.bashrc
alias docker="sudo docker"
alias hist="history | cut -c 8-"
alias k="kubectl"
alias kg="kubectl get"
alias kga="kubectl get all"
alias kcre="kubectl create"
alias kapp="kubectl apply"
alias kdel="kubectl delete"
alias kdes="kubectl describe"
alias klogs="kubectl logs"
alias watchk="watch -d kubectl get all"
source <(kubectl completion bash)
EOF

source ~/.bashrc

