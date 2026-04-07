#!/usr/bin/env bash
# bootstrap.sh — Bootstrap the Apex Platform from scratch
# Usage: ./scripts/setup/bootstrap.sh [--subscription-id <id>] [--location <location>]
set -euo pipefail

# ─── Defaults ────────────────────────────────────────────────────────────────
LOCATION="${LOCATION:-uksouth}"
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-}"
TF_STATE_RG="rg-apex-platform-tfstate-uks"
TF_STATE_SA="stapexplatformtfstate"
TF_STATE_CONTAINER="tfstate"

# ─── Colour helpers ──────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ─── Parse arguments ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription-id) SUBSCRIPTION_ID="$2"; shift 2 ;;
    --location)        LOCATION="$2";        shift 2 ;;
    *) error "Unknown argument: $1" ;;
  esac
done

# ─── Prerequisite checks ─────────────────────────────────────────────────────
info "Checking prerequisites..."
for cmd in az terraform git; do
  command -v "$cmd" >/dev/null 2>&1 || error "'$cmd' is not installed. Please install it and retry."
done

TERRAFORM_VERSION=$(terraform version -json | python3 -c "import sys,json; print(json.load(sys.stdin)['terraform_version'])")
info "Terraform version: $TERRAFORM_VERSION"

# ─── Azure login ─────────────────────────────────────────────────────────────
info "Checking Azure login status..."
if ! az account show >/dev/null 2>&1; then
  warn "Not logged in to Azure. Running 'az login'..."
  az login
fi

if [[ -n "$SUBSCRIPTION_ID" ]]; then
  info "Setting subscription to $SUBSCRIPTION_ID"
  az account set --subscription "$SUBSCRIPTION_ID"
fi

CURRENT_SUB=$(az account show --query id -o tsv)
info "Using subscription: $CURRENT_SUB"

# ─── Create Terraform state storage ──────────────────────────────────────────
info "Creating Terraform state resource group: $TF_STATE_RG"
az group create \
  --name "$TF_STATE_RG" \
  --location "$LOCATION" \
  --tags ManagedBy=Terraform Repository=apex-platform \
  --output none

info "Creating Terraform state storage account: $TF_STATE_SA"
az storage account create \
  --name "$TF_STATE_SA" \
  --resource-group "$TF_STATE_RG" \
  --location "$LOCATION" \
  --sku Standard_GRS \
  --kind StorageV2 \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2 \
  --https-only true \
  --output none

info "Creating Terraform state container: $TF_STATE_CONTAINER"
az storage container create \
  --name "$TF_STATE_CONTAINER" \
  --account-name "$TF_STATE_SA" \
  --auth-mode login \
  --output none

# ─── Assign RBAC for Terraform state ─────────────────────────────────────────
CURRENT_USER_OID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || az account show --query user.name -o tsv)
SA_ID=$(az storage account show --name "$TF_STATE_SA" --resource-group "$TF_STATE_RG" --query id -o tsv)
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee-object-id "$CURRENT_USER_OID" \
  --assignee-principal-type User \
  --scope "$SA_ID" \
  --output none || true

# ─── Initialise and apply global environment ─────────────────────────────────
info "Initialising global environment..."
pushd "$(git rev-parse --show-toplevel)/terraform/environments/global" >/dev/null
terraform init -reconfigure
terraform validate
info "Planning global environment..."
terraform plan -out=tfplan
info "Applying global environment..."
terraform apply tfplan
popd >/dev/null

# ─── Done ────────────────────────────────────────────────────────────────────
info ""
info "Bootstrap complete!"
info ""
info "Next steps:"
info "  1. cd terraform/environments/connectivity && terraform init && terraform apply"
info "  2. cd terraform/environments/landing-zones/production/orders && terraform init && terraform apply"
info "  3. Configure Backstage: backstage/app-config.yaml"
info "  4. Push the repository to your Azure DevOps or GitHub organisation."
