echo "Install net-tools"
sudo apt-get update && sudo apt-get install -y net-tools git

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

echo "Install kubectl"
##install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.30.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/bin/kubectl

echo "Creating cluster"
## Create cluster
sudo k3d cluster create aboba --api-port 6443 -p 30000-30011:30000-30011@server:0

echo "Get Info about new cluster"
## Get info abot cluster
sudo kubectl cluster-info

echo "Create namespaces"
## Create namespaces
sudo kubectl create namespace argocd
sudo kubectl create namespace dev
sudo kubectl create namespace gitlab

ADDR=$(ifconfig | grep 10.100 | awk '{print $2}')
#install helm
echo "installing helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
sudo mv /usr/local/bin/helm /usr/bin

echo "deploy gitlab"
git clone https://gitlab.com/gitlab-org/charts/gitlab.git
cd gitlab
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm dependency update -n gitlab
helm upgrade --install gitlab -f examples/values-minikube-minimum.yaml . --timeout 600s --set global.hosts.domain=$ADDR --set global.edition=ce --set global.hosts.externalIP=$ADDR --set global.hosts.https=false -n gitlab
sudo kubectl apply -f /vagrant/confs/gitlab/deployment-svc.yaml -n gitlab

# echo "Applying K3D configs"
# # Apply argocd Install conf
echo "deploy argocd"
sed -i "s|192.168.0.107|$ADDR|g" /vagrant/confs/argocd/application.yaml
sed -i "s|192.168.0.107|$ADDR|g" /vagrant/confs/argocd/argocd-project.yaml
sudo kubectl apply -f /vagrant/confs/argocd/install.yaml -n argocd
sudo kubectl apply -f /vagrant/confs/argocd/ingress.yaml -n argocd

echo "Set password for ArgoCD"
## Set password for ArgoCD newinceptionschoolproject
sudo kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$12$r1jYUHMDJdJoV5lYxfVQy.nUiTkU184OyB0rqZooDsSmYevLuSNdm",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'

echo "Applying configs application for ArgoCD"
## Apply configuration
sudo kubectl apply -f /vagrant/confs/argocd/argocd-project.yaml -n argocd

## Setup application to argocd
sudo kubectl apply -f /vagrant/confs/argocd/application.yaml -n argocd

sudo kubectl get secret gitlab-gitlab-initial-root-password -n gitlab  -ojsonpath='{.data.password}'  | base64 --decode ; echo