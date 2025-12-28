output "name" {
  description = "The name of the domain topic."
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = "The resource ID of the domain topic."
  value       = azapi_resource.this.id
}
