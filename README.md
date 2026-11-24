# k8S-Platform-Design

Production-grade Kubernetes platform on a cloud provider
Build a multi-environment (dev/staging/prod) platform with everything defined as code.

Infrastructure with Terraform (modular, remote state, workspaces or Terragrunt)

Managed Kubernetes (EKS/GKE/AKS), with a proper VPC layout, private nodes, and IAM roles for service accounts

GitOps with ArgoCD or Flux, so deployments happen only through Git

Ingress, cert-manager, and external-dns for automatic TLS and DNS

Autoscaling (HPA, Karpenter or Cluster Autoscaler)

