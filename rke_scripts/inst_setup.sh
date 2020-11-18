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

yum install yum-utils git vim gcc socat dep kubeadm -y
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y install https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.2.13-3.2.el7.x86_64.rpm
yum -y --nobest install docker-ce-18.09.2-3.el7 docker-ce-cli-18.09.2-3.el7

systemctl enable --now docker

swapoff -a

echo -e 'br_netfilter\nip6_udp_tunnel\nip_set\nip_set_hash_ip\nip_set_hash_net\niptable_filter\niptable_nat\niptable_mangle\niptable_raw\nnf_conntrack_netlink\nnf_conntrack\nnf_conntrack_ipv4\nnf_defrag_ipv4\nnf_nat\nnf_nat_ipv4\nnf_nat_masquerade_ipv4\nnfnetlink\nudp_tunnel\nveth\nvxlan\nx_tables\nxt_addrtype\nxt_conntrack\nxt_comment\nxt_mark\nxt_multiport\nxt_nat\nxt_recent\nxt_set\nxt_statistic\nxt_tcpudp' > /etc/modules-load.d/rke.conf

for module in br_netfilter ip6_udp_tunnel ip_set ip_set_hash_ip ip_set_hash_net iptable_filter iptable_nat iptable_mangle iptable_raw nf_conntrack_netlink nf_conntrack nf_conntrack_ipv4 nf_defrag_ipv4 nf_nat nf_nat_ipv4 nf_nat_masquerade_ipv4 nfnetlink udp_tunnel veth vxlan x_tables xt_addrtype xt_conntrack xt_comment xt_mark xt_multiport xt_nat xt_recent xt_set xt_statistic xt_tcpudp; do modprobe $module; done

echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/rke.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/rke.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/rke.conf
sysctl -p /etc/sysctl.d/rke.conf

curl -o /usr/bin/rke -L https://github.com/rancher/rke/releases/download/v1.1.12/rke_linux-amd64
chmod +x /usr/bin/rke
rke --version

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

