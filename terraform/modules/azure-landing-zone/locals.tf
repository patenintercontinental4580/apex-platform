locals {
  default_tags = {
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "apex-platform"
  }
}
