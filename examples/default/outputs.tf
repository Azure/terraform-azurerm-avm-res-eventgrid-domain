output "domain_event_subscription_id" {
  description = "The resource ID of the domain event subscription."
  value       = module.domain_event_subscription.resource_id
}

output "domain_event_subscription_name" {
  description = "The name of the domain event subscription."
  value       = module.domain_event_subscription.name
}

output "domain_name" {
  description = "The name of the Event Grid Domain."
  value       = module.test.name
}

output "domain_resource_id" {
  description = "The resource ID of the Event Grid Domain."
  value       = module.test.resource_id
}

output "storage_account_id" {
  description = "The resource ID of the storage account used for event subscription destination."
  value       = azapi_resource.storage_account.id
}

output "storage_queue_name" {
  description = "The name of the storage queue used for event subscription destination."
  value       = azapi_resource.storage_queue.name
}
