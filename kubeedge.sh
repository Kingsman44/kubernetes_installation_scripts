# Update
sudo apt-get update
sudo apt-get upgrade -y

# Install required files
sudo apt install apt-transport-https curl -y

# Install containerd and set containerd
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install containerd.io -y
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

# Install Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo apt install kubeadm kubelet kubectl kubernetes-cni -y

# Disable Swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Enable IP features
sudo modprobe br_netfilter
sudo sysctl -w net.ipv4.ip_forward=1

# init kubeadm
sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd
sudo kubeadm init

# set config
mkdir -p $HOME/.kube
sudo cp -if /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Set calico
rm -rf calico.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml -O
kubectl apply -f calico.yaml

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

sudo apt-get install -y uidmap
#dockerd-rootless-setuptool.sh install

# Add the repository to Apt sources:
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# install golang
rm -rf go1.21.1.linux-amd64.tar.gz
wget https://go.dev/dl/go1.21.1.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.1.linux-amd64.tar.gz
chmod +x /usr/local/go/bin
export PATH=$PATH:/usr/local/go/bin

#install kind
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

sudo apt install iptables openssl git make manpages-dev build-essential jq -y

wget https://github.com/kubeedge/kubeedge/releases/download/v1.14.2/keadm-v1.14.2-linux-amd64.tar.gz
tar -zxvf keadm-v1.14.2-linux-amd64.tar.gz
cp keadm-v1.14.2-linux-amd64/keadm/keadm /usr/local/bin/keadm

rm -rf kubeedge
git clone https://github.com/kubeedge/kubeedge.git kubeedge -b release-1.14
cd kubeedge/hack
for i in $(ls update*.sh); do
  bash $i
done
for i in $(ls verify*.sh); do
  bash $i
done

bash local-up-kubeedge.sh
