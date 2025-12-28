output "name" {
  description = "The name of the domain topic event subscription."
  value       = azapi_resource.this.name
}

output "output" {
  description = "The full output of the domain topic event subscription resource."
  value       = azapi_resource.this.output
}

output "resource_id" {
  description = "The resource ID of the domain topic event subscription."
  value       = azapi_resource.this.id
}
