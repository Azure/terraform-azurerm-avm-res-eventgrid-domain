locals {
  private_endpoints = {
    for k, v in var.private_endpoints : k => {
      name                                    = v.name
      role_assignments                        = v.role_assignments
      lock                                    = v.lock == null ? var.lock : (v.lock.kind == "None" ? null : v.lock)
      tags                                    = v.tags != null ? v.tags : var.tags
      subnet_resource_id                      = v.subnet_resource_id
      private_dns_zone_group_name             = v.private_dns_zone_group_name
      private_dns_zone_resource_ids           = v.private_dns_zone_resource_ids
      application_security_group_associations = v.application_security_group_associations
      # Retain the connection names generated before the domain subresource was forwarded.
      private_service_connection_name = v.private_service_connection_name != null ? v.private_service_connection_name : (v.name != null ? "pcon-${v.name}" : "pcon-pep-${uuidv5("url", azapi_resource.this.id)}")
      network_interface_name          = coalesce(v.network_interface_name, "nic-${coalesce(v.name, "pe-${var.name}-${k}")}")
      location                        = v.location
      resource_group_name             = v.resource_group_name
      ip_configurations               = v.ip_configurations
      subresource_name                = coalesce(v.subresource_name, "domain")
    }
  }
}
