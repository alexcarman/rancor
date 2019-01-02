# This is a collection of codes that allow you to build a k8s cluster and install rancher 2.1+

## Overview
This project is broken down into several parts:
- Load balancer configs as you will need a layer 7 balancer in front of the RKE cluster.
- Terraform to deploy the vsphere infrastructure.
- The configuration for RKE to deploy the kubernetes cluster.
- The instructions below for installing Rancher 2.1+ via a helm chart
- The instructions for installing and configuring an NFS provisioner via a helm chart for persistent storage.
- Experimental configs for things like the rook storage engine.

## Prerequisites
- Layer 7 Load balancer, I've included configs for nginx. Nginx stats aren't free, so maybe I'll convert to HAproxy at some point. Layer 4 would also work.
- RKE Installer executable from [https://github.com/rancher/rke/releases/](https://github.com/rancher/rke/releases/).
- Terraform Installed so you can provision the infrastructure.
- Kubectl executable from [https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- helm install from [https://github.com/helm/helm/blob/master/docs/install.md](https://github.com/helm/helm/blob/master/docs/install.md)
- Some working knowledge of various command lines, linux, terraform, kubectl, helm, etc.
- A Rancher OS(for now) VM template in vcenter with passworded SSH enabled.

## Create the Vsphere Environment.
1. Set the required variables in your LOCAL terraform.tfvars file, they are defined in variables.tf the variable "char_array" must be set to "abcdefghijklmnopqrstuvxyz", this was a hack to do what I wanted and may be refactored in the future.
2. Run ```sh terraform apply -parallelism=1 ```
3. Grab an age appropriate beverage and wait for it to finish.

## Install K8s via RKE
This command will bring up the k8s cluster using the included config in this project.
```sh
rke_linux-amd64 up -config rke_configs/rancher-cluster.yml
```
This will setup the kubeconfig for your kubectl:
```sh
export KUBECONFIG=$(pwd)/kube_config_rancher-cluster.yml
```

## Install Rancher via Helm
### Initialize Helm and install Tiller
```sh
kubectl -n kube-system create serviceaccount tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller
```
You can watch the progress of your tiller installation with the following command:
```sh
kubectl -n kube-system  rollout status deploy/tiller-deploy
```
You can validate the install was successful with this command:
```sh
helm version
```
### Install Rancher from stable
You really should read the helm rancher install doc before starting this because you'll have to make a decision on the certificates. [https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/](https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/)
I repeat, RANCHER WILL NOT START THE WEBUI UNTIL YOU HAVE CERTS.
```sh
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm install rancher-stable/rancher --name rancher --namespace cattle-system --set hostname=rancher.my.org --set ingress.tls.source=<secret_type_goes_here>
```

## Install NFS Provisioner via Helm
```sh
helm install stable/nfs-client-provisioner --set nfs.server=put_nfs_server_address_here --set nfs.path=/k8s --set nfs.mountOptions="{nolock}"
```
