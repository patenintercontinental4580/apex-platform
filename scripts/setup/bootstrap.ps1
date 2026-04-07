#Requires -Version 7.0
<#
.SYNOPSIS
    Bootstrap the Apex Platform from scratch.

.DESCRIPTION
    Creates the Terraform state storage account, initialises the global environment,
    and prints next steps. Mirrors bootstrap.sh for Windows users.

.PARAMETER SubscriptionId
    Azure subscription ID to use. If omitted, uses the current active subscription.

.PARAMETER Location
    Azure region for state storage. Defaults to uksouth.

.EXAMPLE
    .\scripts\setup\bootstrap.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000000"
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId = $env:SUBSCRIPTION_ID,
    [string]$Location = "uksouth"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$TfStateRg        = "rg-apex-platform-tfstate-uks"
$TfStateSa        = "stapexplatformtfstate"
$TfStateContainer = "tfstate"

function Write-Info  { param($Msg) Write-Host "[INFO]  $Msg" -ForegroundColor Green }
function Write-Warn  { param($Msg) Write-Host "[WARN]  $Msg" -ForegroundColor Yellow }
function Write-Err   { param($Msg) Write-Error "[ERROR] $Msg" }

# ─── Prerequisite checks ─────────────────────────────────────────────────────
Write-Info "Checking prerequisites..."
foreach ($cmd in @("az", "terraform", "git")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Err "'$cmd' is not installed. Please install it and retry."
    }
}

# ─── Azure login ─────────────────────────────────────────────────────────────
Write-Info "Checking Azure login status..."
try {
    $null = az account show 2>$null
} catch {
    Write-Warn "Not logged in to Azure. Running 'az login'..."
    az login
}

if ($SubscriptionId) {
    Write-Info "Setting subscription to $SubscriptionId"
    az account set --subscription $SubscriptionId
}

$CurrentSub = (az account show --query id -o tsv)
Write-Info "Using subscription: $CurrentSub"

# ─── Create Terraform state storage ──────────────────────────────────────────
Write-Info "Creating Terraform state resource group: $TfStateRg"
az group create `
    --name $TfStateRg `
    --location $Location `
    --tags ManagedBy=Terraform Repository=apex-platform `
    --output none

Write-Info "Creating Terraform state storage account: $TfStateSa"
az storage account create `
    --name $TfStateSa `
    --resource-group $TfStateRg `
    --location $Location `
    --sku Standard_GRS `
    --kind StorageV2 `
    --allow-blob-public-access false `
    --min-tls-version TLS1_2 `
    --https-only true `
    --output none

Write-Info "Creating Terraform state container: $TfStateContainer"
az storage container create `
    --name $TfStateContainer `
    --account-name $TfStateSa `
    --auth-mode login `
    --output none

# ─── Initialise and apply global environment ─────────────────────────────────
Write-Info "Initialising global environment..."
$RepoRoot = git rev-parse --show-toplevel
Push-Location (Join-Path $RepoRoot "terraform/environments/global")
try {
    terraform init -reconfigure
    terraform validate
    Write-Info "Planning global environment..."
    terraform plan -out=tfplan
    Write-Info "Applying global environment..."
    terraform apply tfplan
} finally {
    Pop-Location
}

Write-Info ""
Write-Info "Bootstrap complete!"
Write-Info ""
Write-Info "Next steps:"
Write-Info "  1. cd terraform/environments/connectivity && terraform init && terraform apply"
Write-Info "  2. cd terraform/environments/landing-zones/production/orders && terraform init && terraform apply"
Write-Info "  3. Configure Backstage: backstage/app-config.yaml"
Write-Info "  4. Push the repository to your Azure DevOps or GitHub organisation."
