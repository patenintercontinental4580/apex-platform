# Azure Firewall Public IP
resource "azurerm_public_ip" "firewall" {
  name                = "pip-fw-apex-hub-uks"
  resource_group_name = azurerm_resource_group.connectivity.name
  location            = azurerm_resource_group.connectivity.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = azurerm_resource_group.connectivity.tags
}

# Firewall Policy
resource "azurerm_firewall_policy" "hub" {
  name                = "fwp-apex-hub-uks"
  resource_group_name = azurerm_resource_group.connectivity.name
  location            = azurerm_resource_group.connectivity.location
  sku                 = "Standard"
  tags                = azurerm_resource_group.connectivity.tags

  dns {
    proxy_enabled = true
  }
}

# Azure Firewall
resource "azurerm_firewall" "hub" {
  name                = "fw-apex-hub-uks"
  resource_group_name = azurerm_resource_group.connectivity.name
  location            = azurerm_resource_group.connectivity.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.hub.id
  tags                = azurerm_resource_group.connectivity.tags

  ip_configuration {
    name                 = "ipconfig-primary"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

# Firewall Policy Rule Collection Group: Platform Core
resource "azurerm_firewall_policy_rule_collection_group" "platform_core" {
  name               = "platform-core"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 100

  network_rule_collection {
    name     = "azure-management"
    priority = 100
    action   = "Allow"

    rule {
      name                  = "AllowAzureCloud"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["*"]
      destination_addresses = ["AzureCloud"]
      destination_ports     = ["443", "80"]
    }

    rule {
      name                  = "AllowDNS"
      protocols             = ["UDP", "TCP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_addresses = ["168.63.129.16"]
      destination_ports     = ["53"]
    }

    rule {
      name                  = "AllowNTP"
      protocols             = ["UDP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_addresses = ["*"]
      destination_ports     = ["123"]
    }

    rule {
      name                  = "AllowAzureMonitor"
      protocols             = ["TCP"]
      source_addresses      = ["10.0.0.0/8"]
      destination_addresses = ["AzureMonitor"]
      destination_ports     = ["443"]
    }
  }
}

# Firewall Policy Rule Collection Group: Development Tools
resource "azurerm_firewall_policy_rule_collection_group" "development_tools" {
  name               = "development-tools"
  firewall_policy_id = azurerm_firewall_policy.hub.id
  priority           = 200

  application_rule_collection {
    name     = "package-registries"
    priority = 100
    action   = "Allow"

    rule {
      name             = "AllowNuGet"
      source_addresses = ["10.0.0.0/8"]
      destination_fqdns = [
        "api.nuget.org",
        "www.nuget.org",
        "nuget.org",
        "*.nuget.org",
      ]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name             = "AllowPyPI"
      source_addresses = ["10.0.0.0/8"]
      destination_fqdns = [
        "pypi.org",
        "files.pythonhosted.org",
        "*.pypi.org",
      ]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name             = "AllowNpm"
      source_addresses = ["10.0.0.0/8"]
      destination_fqdns = [
        "registry.npmjs.org",
        "*.npmjs.org",
        "npmjs.com",
      ]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name             = "AllowDockerHub"
      source_addresses = ["10.0.0.0/8"]
      destination_fqdns = [
        "hub.docker.com",
        "registry-1.docker.io",
        "auth.docker.io",
        "index.docker.io",
        "*.docker.io",
        "*.docker.com",
        "production.cloudflare.docker.com",
      ]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name             = "AllowTerraformRegistry"
      source_addresses = ["10.0.0.0/8"]
      destination_fqdns = [
        "registry.terraform.io",
        "checkpoint-api.hashicorp.com",
        "releases.hashicorp.com",
        "*.hashicorp.com",
      ]
      protocols {
        type = "Https"
        port = 443
      }
    }

    rule {
      name             = "AllowGitHub"
      source_addresses = ["10.0.0.0/8"]
      destination_fqdns = [
        "github.com",
        "*.github.com",
        "*.githubusercontent.com",
        "githubassets.com",
      ]
      protocols {
        type = "Https"
        port = 443
      }
    }
  }
}

# Diagnostic Settings for Firewall
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                       = "diag-fw-apex-hub-uks"
  target_resource_id         = azurerm_firewall.hub.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id

  enabled_log {
    category = "AzureFirewallApplicationRule"
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"
  }

  enabled_log {
    category = "AzureFirewallDnsProxy"
  }

  metric {
    category = "AllMetrics"
  }
}
