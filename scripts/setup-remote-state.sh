

set -euo pipefail

# Configuration
PROJECT="k8s-platform"
REGION="us-east-1"

# Validate environment
ENVIRONMENT="${1:-}"

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
  echo "Usage: ./scripts/setup-remote-state.sh dev|staging|prod"
  exit 1
fi

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

BUCKET="${PROJECT}-tfstate-${ACCOUNT_ID}"
ENV_DIR="infrastructure/environments/${ENVIRONMENT}"

echo "Setting up Terraform remote state..."
echo "Environment: ${ENVIRONMENT}"
echo "Bucket: ${BUCKET}"
echo "Region: ${REGION}"

# Create S3 bucket if it doesn't exist
if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "Creating S3 bucket..."

  aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
else
  echo "S3 bucket already exists."
fi

# Enable versioning
aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption --bucket "$BUCKET" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Block public access
aws s3api put-public-access-block --bucket "$BUCKET" --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create environment directory if needed
mkdir -p "$ENV_DIR"

# Configure Terraform S3 backend
cat > "${ENV_DIR}/backend.tf" <<EOF
terraform {
  backend "s3" {
    bucket       = "${BUCKET}"
    key          = "${ENVIRONMENT}/terraform.tfstate"
    region       = "${REGION}"
    encrypt      = true
    use_lockfile = true
  }
}
EOF

echo "Backend configuration created."


terraform -chdir="$ENV_DIR" init -reconfigure

echo "--------------------------------"
echo "Remote state setup completed!"
echo "Environment: ${ENVIRONMENT}"
echo "S3 bucket: ${BUCKET}"
echo "State key: ${ENVIRONMENT}/terraform.tfstate"
echo "--------------------------------"
