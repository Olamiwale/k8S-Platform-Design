
#!/bin/bash

set -Eeuo pipefail

# Project configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENVIRONMENT="${1:-dev}"
REGION="us-east-1"
ENV_DIR="${PROJECT_ROOT}/infrastructure/environments/${ENVIRONMENT}"
PLAN_FILE="${ENV_DIR}/.eks-setup.tfplan"
TFVARS_FILE="${ENV_DIR}/admin.auto.tfvars"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
  echo "Usage: ./scripts/setup-eks.sh dev|staging|prod"
  exit 1
fi

# Check required commands
for cmd in aws terraform curl kubectl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: $cmd is not installed."
    exit 1
  fi
done

if [[ ! -d "$ENV_DIR" ]]; then
  echo "ERROR: Environment directory not found: $ENV_DIR"
  exit 1
fi

# Clean temporary files on exit
cleanup() {
  rm -f "$PLAN_FILE" "$TFVARS_FILE"
}
trap cleanup EXIT

echo "=================================="
echo "      EKS PLATFORM SETUP"
echo "=================================="

# Verify AWS credentials
echo "Checking AWS credentials..."

aws sts get-caller-identity >/dev/null

# Retrieve public IP
echo "Retrieving public IP..."

PUBLIC_IP="$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')"

if [[ ! "$PUBLIC_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "ERROR: Could not determine a valid public IPv4 address."
  exit 1
fi

ADMIN_CIDR="${PUBLIC_IP}/32"

echo "Admin access CIDR: $ADMIN_CIDR"

# Confirm VPC already exists in Terraform state
echo "Checking VPC deployment..."

VPC_ID="$(terraform -chdir="$ENV_DIR" output -raw vpc_id)"

if [[ -z "$VPC_ID" ]]; then
  echo "ERROR: VPC not found in Terraform outputs."
  echo "Deploy the VPC before setting up EKS."
  exit 1
fi

# Generate temporary Terraform variables
cat > "$TFVARS_FILE" <<EOF
admin_cidr = "${ADMIN_CIDR}"
EOF

# Initialize Terraform
echo "Initializing Terraform..."

terraform -chdir="$ENV_DIR" init -input=false

# Format and validate
echo "Formatting Terraform..."

terraform fmt -recursive "$PROJECT_ROOT/infrastructure"

echo "Validating Terraform..."

terraform -chdir="$ENV_DIR" validate

# Generate plan
echo "Generating EKS deployment plan..."

terraform -chdir="$ENV_DIR" plan \
  -input=false \
  -out="$PLAN_FILE"

echo ""
echo "=================================="
echo "Review the plan above."
echo "=================================="

read -r -p "Deploy EKS resources? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  echo "Deployment cancelled."
  exit 0
fi

# Deploy EKS
echo "Deploying EKS..."

terraform -chdir="$ENV_DIR" apply "$PLAN_FILE"

# Get cluster name
CLUSTER_NAME="$(
  terraform -chdir="$ENV_DIR" output -raw eks_cluster_name
)"

# Configure kubectl
echo "Configuring kubectl..."

aws eks update-kubeconfig \
  --region "$REGION" \
  --name "$CLUSTER_NAME"

# Verify cluster
echo "Checking Kubernetes nodes..."

kubectl get nodes

echo "Checking system pods..."

kubectl get pods -n kube-system

echo ""
echo "=================================="
echo "       EKS SETUP COMPLETED"
echo "=================================="
echo "Environment: $ENVIRONMENT"
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
