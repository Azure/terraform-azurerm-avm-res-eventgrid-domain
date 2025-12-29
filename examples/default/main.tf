terraform {
  required_version = "~> 1.5"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "azurerm" {
  features {}
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.0"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Storage account for event subscription destination (using AzAPI for keyless operation)
resource "azapi_resource" "storage_account" {
  location  = azurerm_resource_group.this.location
  name      = module.naming.storage_account.name_unique
  parent_id = azurerm_resource_group.this.id
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_ZRS"
    }
    properties = {
      allowSharedKeyAccess = false # Security best practice - no keys
      minimumTlsVersion    = "TLS1_2"
      publicNetworkAccess  = "Enabled"
    }
  }
}

# Storage queue using AzAPI (no shared key required)
resource "azapi_resource" "storage_queue" {
  name      = "eventgridqueue"
  parent_id = "${azapi_resource.storage_account.id}/queueServices/default"
  type      = "Microsoft.Storage/storageAccounts/queueServices/queues@2023-05-01"
  body = {
    properties = {}
  }
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"

  location         = azurerm_resource_group.this.location
  name             = module.naming.eventgrid_domain.name_unique
  parent_id        = azurerm_resource_group.this.id
  enable_telemetry = var.enable_telemetry # see variables.tf
  # Enable system-assigned managed identity for secure delivery
  managed_identities = {
    system_assigned = true
  }
}

# Grant the Event Grid Domain's managed identity permission to write to the storage queue
resource "azurerm_role_assignment" "eventgrid_storage_queue_sender" {
  principal_id                     = module.test.system_assigned_mi_principal_id
  scope                            = azapi_resource.storage_account.id
  role_definition_name             = "Storage Queue Data Message Sender"
  skip_service_principal_aad_check = true # Skip AAD check to speed up propagation
}

# Wait for RBAC propagation before creating event subscription
resource "time_sleep" "wait_for_rbac" {
  create_duration = "60s"

  depends_on = [
    azurerm_role_assignment.eventgrid_storage_queue_sender
  ]
}

# Example domain event subscription using the submodule with managed identity
module "domain_event_subscription" {
  source = "../../modules/domain_event_subscription"

  event_grid_domain_resource_id = module.test.resource_id
  name                          = "example-domain-subscription"
  # Use managed identity for secure delivery (no shared keys)
  delivery_with_resource_identity = {
    identity = {
      type = "SystemAssigned"
    }
    destination = {
      storage_queue = {
        resource_id                           = azapi_resource.storage_account.id
        queue_name                            = azapi_resource.storage_queue.name
        queue_message_time_to_live_in_seconds = 604800 # 7 days
      }
    }
  }
  event_delivery_schema = "EventGridSchema"
  # Event filtering
  filter = {
    subject_begins_with       = "/myapp/"
    is_subject_case_sensitive = false
    included_event_types      = ["Microsoft.EventGrid.CustomEvent"]
    advanced_filters = [
      {
        key           = "data.severity"
        operator_type = "StringIn"
        values        = ["high", "critical"]
      }
    ]
  }
  # Labels for organization
  labels = ["example", "default"]
  # Retry policy
  retry_policy = {
    max_delivery_attempts         = 30
    event_time_to_live_in_minutes = 1440
  }

  depends_on = [time_sleep.wait_for_rbac]
}
