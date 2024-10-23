#!/bin/bash
echo "Install K3s"
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --flannel-iface=eth1" K3S_TOKEN=hyinya K3S_KUBECONFIG_MODE="644" sh -

sleep 10

## start another script
echo "=== -START APPLY- ==="
/usr/local/bin/kubectl apply -f /vagrant/confs/ingress.yaml
/usr/local/bin/kubectl apply -f /vagrant/confs/deployment-app1.yaml
/usr/local/bin/kubectl apply -f /vagrant/confs/deployment-app2.yaml
/usr/local/bin/kubectl apply -f /vagrant/confs/deployment-app3.yaml
echo "=== -END APPLY- ==="