# Building K8s lab with kubeadm and minimum requirements on AWS Centos7 ami

### On all nodes

## sanity updates
echo "colo desert" > ~/.vimrc
cat >> ~/.bashrc << EOL
alias kg="kubectl get"
alias kga="kubectl get all"
alias kcre="kubectl create"
alias kapp="kubectl apply"
alias kdel="kubectl delete"
alias kdes="kubectl describe"
alias klogs="kubectl logs"
alias watchk="watch -d kubectl get all"
EOL
source ~/.bashrc
echo "source <(kubectl completion bash)" >> ~/.bashrc


## install essential packages
sudo yum -y install yum-utils vim wget bash-completion git && sudo yum -y update
echo "done installing essentials"
echo

## switch to root
sudo su

## install docker
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install docker-ce docker-ce-cli containerd.io
systemctl enable --now docker
usermod -aG docker $USER && newgrp docker
echo "done installing docker"
echo

## prepare centos for kubeadm
swapoff -a
modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
echo "done preparing for kubeadm"
echo

## install kubeadm, kubelet, kubectl
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
systemctl daemon-reload
systemctl restart kubelet
kubeadm config images pull
echo "done installing kubeadm, kubelet, kubectl"
echo

## switch to user
exit
source ./bashrc

### On master node only

## add ip address to /etc/hosts
echo "$(hostname -i) k8smaster" >> /etc/hosts

## initial kubernetes control-plane
sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --v=5 | tee kubeadm-init.out

## apply config file to .kube user location
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo

## install pod network (calico, kube-router, etc)

# using calico
wget https://docs.projectcalico.org/manifests/calico.yaml
# remove comments for lines 3579-3580 re: CALICO_IPV4POOL_CIDR 
kubectl apply -f calico.yaml

# using kube-router (install then remove kube-proxy cleanup iptables)
# KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml
# KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter-all-features.yaml
# KUBECONFIG=/etc/kubernetes/admin.conf kubectl -n kube-system delete ds kube-proxy
# docker run --privileged -v /lib/modules:/lib/modules --net=host k8s.gcr.io/kube-proxy-amd64:v1.15.1 kube-proxy --cleanup


### For worker nodes

## (on master node) copy kubeadm join command created with tokens
cat kubeadm-init.out

## (on worker node) paste kubedm join command to join node with cluster
sudo kubeadm join <master node ip>:6443 --token <kubeadm token> --discovery-token-ca-cert-hash <hash token>

## (on master node) test new worker node connection
kubectl get nodes
