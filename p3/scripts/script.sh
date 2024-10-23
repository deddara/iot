echo "Setup Docker"
##install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo systemctl restart docker

echo "Install K3D"
## Install K3D
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | sudo bash
sudo chmod +x /usr/local/bin/k3d
sudo mv /usr/local/bin/k3d /usr/bin

sleep 5

echo "Install kubectl"
##install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.30.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/bin/kubectl

sleep 5

echo "Creating cluster"
## Create cluster
sudo k3d cluster create aboba --api-port 6443 -p 8080:80@loadbalancer

echo "Get Info about new cluster"
## Get info abot cluster
sudo kubectl cluster-info

echo "Create namespaces"
## Create namespaces
sudo kubectl create namespace argocd
sudo kubectl create namespace dev

echo "Applying K3D configs"
## Apply argocd Install conf
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
sudo kubectl apply -f /vagrant/confs/install.yaml -n argocd
sudo kubectl apply -f /vagrant/confs/ingress.yaml -n argocd

echo "Set password for ArgoCD"
## Set password for ArgoCD newinceptionschoolproject
sudo kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$12$r1jYUHMDJdJoV5lYxfVQy.nUiTkU184OyB0rqZooDsSmYevLuSNdm",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'

echo "Applying configs application for ArgoCD"
## Apply configuration
sudo kubectl apply -f /vagrant/confs/argocd-project.yaml -n argocd

## Setup application to argocd
sudo kubectl apply -f /vagrant/confs/application.yaml -n argocd
