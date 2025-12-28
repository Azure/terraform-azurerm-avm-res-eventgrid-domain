output "domain_endpoint" {
  description = <<DESCRIPTION
The endpoint URL of the Event Grid Domain.
DESCRIPTION
  value       = try(azapi_resource.this.output.properties.endpoint, null)
}

output "identity" {
  description = <<DESCRIPTION
The managed identity configuration of the Event Grid Domain, including principal_id and tenant_id for system-assigned identity.
DESCRIPTION
  value       = try(azapi_resource.this.output.identity, null)
}

output "name" {
  description = <<DESCRIPTION
The name of the Event Grid Domain.
DESCRIPTION
  value       = azapi_resource.this.name
}

output "resource_id" {
  description = <<DESCRIPTION
The Azure Resource Manager ID of the Event Grid Domain.
DESCRIPTION
  value       = azapi_resource.this.id
}

output "system_assigned_mi_principal_id" {
  description = <<DESCRIPTION
The principal ID of the system-assigned managed identity for the Event Grid Domain.
Use this to grant RBAC permissions for delivering events to destinations.
DESCRIPTION
  value       = try(azapi_resource.this.output.identity.principalId, null)
}
