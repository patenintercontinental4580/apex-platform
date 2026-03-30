variable "application_name" {
  description = "The name of the application. Used in all resource names and tags."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,23}$", var.application_name))
    error_message = "application_name must start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and be between 3 and 24 characters long."
  }
}

variable "environment" {
  description = "The deployment environment. Must be one of: dev, staging, prod."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "team" {
  description = "The name of the team that owns this application. Used in tags."
  type        = string
}

variable "cost_centre" {
  description = "The cost centre code for billing. Used in tags."
  type        = string
}

variable "container_image" {
  description = "Full container image reference including tag, e.g. myacr.azurecr.io/myapp:1.0.0"
  type        = string
}

variable "location" {
  description = "The Azure region in which to deploy all resources."
  type        = string
  default     = "uksouth"
}

variable "instance_number" {
  description = "The instance number, zero-padded to two digits in resource names. Used to differentiate multiple deployments of the same application in the same environment."
  type        = number
  default     = 1
}

variable "cpu" {
  description = "The number of vCPUs allocated to the container. Must be one of the supported values: 0.25, 0.5, 1.0, 2.0, 4.0."
  type        = number
  default     = 0.5

  validation {
    condition     = contains([0.25, 0.5, 1.0, 2.0, 4.0], var.cpu)
    error_message = "cpu must be one of the supported values: 0.25, 0.5, 1.0, 2.0, 4.0."
  }
}

variable "memory" {
  description = "The memory allocated to the container. Must be one of the supported values: 0.5Gi, 1Gi, 2Gi, 4Gi."
  type        = string
  default     = "1Gi"

  validation {
    condition     = contains(["0.5Gi", "1Gi", "2Gi", "4Gi"], var.memory)
    error_message = "memory must be one of the supported values: 0.5Gi, 1Gi, 2Gi, 4Gi."
  }
}

variable "min_replicas" {
  description = "The minimum number of container replicas to run. Set to 0 to allow scale-to-zero. Production environments require a minimum of 2."
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "The maximum number of container replicas that can be provisioned under load."
  type        = number
  default     = 5
}

variable "target_port" {
  description = "The port that the container listens on for incoming HTTP traffic."
  type        = number
  default     = 8080
}

variable "environment_variables" {
  description = "A map of non-sensitive environment variables to inject into the container at runtime."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "A map of sensitive environment variables to inject into the container as Container App secrets. Keys are used as secret names and as the environment variable names (uppercased with underscores)."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics workspace used for the Container App Environment and Application Insights diagnostics."
  type        = string
}

variable "subnet_id" {
  description = "The resource ID of the subnet to use for the Container App Environment. Required for VNet integration. If null, the environment is deployed without VNet integration."
  type        = string
  default     = null
}

variable "custom_domain" {
  description = "An optional custom domain name to associate with the Container App ingress. If null, only the default Azure-assigned FQDN is used."
  type        = string
  default     = null
}

variable "health_check_path" {
  description = "The HTTP path used for liveness and readiness probes."
  type        = string
  default     = "/healthz"
}

variable "container_app_environment_id" {
  description = "If provided, uses this existing Container App Environment instead of creating a new one. Useful when multiple Container Apps share the same environment."
  type        = string
  default     = null
}
