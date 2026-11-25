# k8S-Platform-Design

 



command to check if VPC is running
aws ec2 describe-vpcs --vpc-ids vpc-09b15426214cc74af



# confirm if EKS running
aws eks describe-cluster --name olawale --region us-east-1 --query 'cluster.{Name:name,Status:status,Version:version,Endpoint:endpoint}' --output table

# confirm if node is running
aws eks describe-nodegroup --cluster-name olawale --nodegroup-name olawale-workers --region us-east-1 --query 'nodegroup.{Name:nodegroupName,Status:status,Desired:scalingConfig.desiredSize,Running:health.issues}' --output json

# node group active
aws eks wait nodegroup-active --cluster-name olawale --nodegroup-name olawale-workers --region us-east-1

# connect kubectl to cluster
aws eks update-kubeconfig --region us-east-1 --name olawale

# check connectivity
kubectl cluster-info


### ArgoCD setup

aws eks update-kubeconfig --region us-east-1 --name olawale

kubectl get nodes

Create the ArgoCD namespace**
kubectl create namespace argocd

# create ArgoCd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Verify installation
kubectl get pods -n argocd

### Access the dashboard**
kubectl port-forward svc/argocd-server -n argocd 8080:443

### Getting password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d

Username: `admin`