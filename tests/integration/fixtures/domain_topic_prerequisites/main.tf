data "azapi_client_config" "current" {}

resource "azapi_resource" "resource_group" {
  name                   = "rg-${var.name}"
  parent_id              = data.azapi_client_config.current.subscription_resource_id
  type                   = "Microsoft.Resources/resourceGroups@2025-04-01"
  location               = var.location
  response_export_values = []
}

resource "azapi_resource" "domain" {
  name      = "${var.name}-domain"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.EventGrid/domains@2025-02-15"
  location  = var.location
  body = {
    properties = {
      inputSchema = "EventGridSchema"
    }
  }

  response_export_values = []
}

resource "azapi_resource" "domain_topic" {
  name      = "${var.name}-topic"
  parent_id = azapi_resource.domain.id
  type      = "Microsoft.EventGrid/domains/topics@2025-02-15"

  response_export_values = []
}

resource "azapi_resource" "storage_account" {
  name      = substr(replace(lower(var.name), "-", ""), 0, 24)
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  location  = var.location
  body = {
    kind = "StorageV2"
    sku = {
      name = "Standard_LRS"
    }
    properties = {
      allowSharedKeyAccess     = true
      minimumTlsVersion        = "TLS1_2"
      publicNetworkAccess      = "Enabled"
      supportsHttpsTrafficOnly = true
    }
  }

  response_export_values = []
}

resource "azapi_resource" "storage_queue" {
  name      = "eventgridoutput"
  parent_id = "${azapi_resource.storage_account.id}/queueServices/default"
  type      = "Microsoft.Storage/storageAccounts/queueServices/queues@2023-05-01"
  body = {
    properties = {}
  }

  response_export_values = []
}
