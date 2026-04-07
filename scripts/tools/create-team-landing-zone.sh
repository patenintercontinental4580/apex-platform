#!/usr/bin/env bash
# create-team-landing-zone.sh — Scaffold a new landing zone for a team
# Usage: ./scripts/tools/create-team-landing-zone.sh \
#           --team orders --env production --vnet-cidr 10.10.0.0/22
set -euo pipefail

# ─── Defaults ────────────────────────────────────────────────────────────────
TEAM=""
ENV=""
VNET_CIDR=""
HUB_FIREWALL_IP="${HUB_FIREWALL_IP:-10.0.1.4}"
DRY_RUN=false

# ─── Colour helpers ──────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ─── Parse arguments ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --team)             TEAM="$2";             shift 2 ;;
    --env)              ENV="$2";              shift 2 ;;
    --vnet-cidr)        VNET_CIDR="$2";        shift 2 ;;
    --hub-firewall-ip)  HUB_FIREWALL_IP="$2";  shift 2 ;;
    --dry-run)          DRY_RUN=true;          shift   ;;
    *) error "Unknown argument: $1" ;;
  esac
done

[[ -z "$TEAM"      ]] && error "--team is required"
[[ -z "$ENV"       ]] && error "--env is required (production | non-production)"
[[ -z "$VNET_CIDR" ]] && error "--vnet-cidr is required (e.g. 10.10.0.0/22)"

REPO_ROOT=$(git rev-parse --show-toplevel)
TARGET_DIR="$REPO_ROOT/terraform/environments/landing-zones/$ENV/$TEAM"

if [[ -d "$TARGET_DIR" ]]; then
  error "Landing zone already exists at $TARGET_DIR"
fi

info "Creating landing zone: team=$TEAM env=$ENV cidr=$VNET_CIDR"

if $DRY_RUN; then
  warn "DRY RUN — no files will be written"
  warn "Would create: $TARGET_DIR/main.tf"
  exit 0
fi

mkdir -p "$TARGET_DIR"

cat > "$TARGET_DIR/main.tf" <<EOF
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.80" }
  }
  backend "azurerm" {
    resource_group_name  = "rg-apex-platform-tfstate-uks"
    storage_account_name = "stapexplatformtfstate"
    container_name       = "tfstate"
    key                  = "$ENV/$TEAM.tfstate"
  }
}

provider "azurerm" {
  features {}
}

data "terraform_remote_state" "connectivity" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-apex-platform-tfstate-uks"
    storage_account_name = "stapexplatformtfstate"
    container_name       = "tfstate"
    key                  = "connectivity/connectivity.tfstate"
  }
}

module "${TEAM}_landing_zone" {
  source = "../../../../modules/azure-landing-zone"

  application_name     = "$TEAM"
  environment          = "$ENV"
  location             = "uksouth"
  instance_number      = 1
  vnet_address_space   = ["$VNET_CIDR"]
  hub_vnet_id          = data.terraform_remote_state.connectivity.outputs.hub_vnet_id
  hub_firewall_private_ip = "$HUB_FIREWALL_IP"

  budget_amount        = 500
  budget_contact_emails = ["platform-engineering@example.com"]

  tags = {
    Team       = "$TEAM"
    CostCentre = "TEAM-$(echo $TEAM | tr '[:lower:]' '[:upper:]')"
  }
}

output "vnet_id" {
  value = module.${TEAM}_landing_zone.vnet_id
}
EOF

info "Created $TARGET_DIR/main.tf"
info ""
info "Next steps:"
info "  cd $TARGET_DIR"
info "  terraform init"
info "  terraform plan"
info "  terraform apply"
