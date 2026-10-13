mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example/providers/Microsoft.EventGrid/domains/example-domain"
      output = {
        identity = {
          principalId = "00000000-0000-0000-0000-000000000011"
          tenantId    = "00000000-0000-0000-0000-000000000012"
        }
      }
    }
  }
}
mock_provider "azurerm" {
  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example"
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {
  mock_resource "random_integer" {
    defaults = { result = 0 }
  }
  mock_resource "random_string" {
    defaults = { result = "example" }
  }
}
mock_provider "time" {}

run "default_example_uses_only_mocked_providers" {
  command = apply

  module {
    source = "./examples/default"
  }
  providers = {
    azapi   = azapi
    azurerm = azurerm
    random  = random
    time    = time
  }
  variables {
    enable_telemetry = false
  }
  assert {
    condition = (
      output.domain_resource_id != null &&
      output.domain_event_subscription_id != null &&
      output.domain_event_subscription_name == "example-domain-subscription" &&
      output.storage_queue_name == "eventgridqueue"
    )
    error_message = "The existing default caller, managed identity delivery and subscription must remain consumable with every provider mocked."
  }
}
