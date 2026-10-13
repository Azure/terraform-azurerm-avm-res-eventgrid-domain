module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.7.0"

  enable_telemetry                        = var.enable_telemetry
  lock                                    = var.lock
  private_endpoints                       = local.private_endpoints
  private_endpoints_manage_dns_zone_group = var.private_endpoints_manage_dns_zone_group
  private_endpoints_scope                 = azapi_resource.this.id
  role_assignment_definition_scope        = var.parent_id
  role_assignments                        = var.role_assignments
}

resource "azapi_resource" "private_endpoints" {
  for_each = module.avm_interfaces.private_endpoints_azapi

  location  = coalesce(local.private_endpoints[each.key].location, azapi_resource.this.location)
  name      = coalesce(local.private_endpoints[each.key].name, "pe-${var.name}-${each.key}")
  parent_id = coalesce(local.private_endpoints[each.key].resource_group_name, var.parent_id)
  type      = var.resource_types.network_private_endpoints
  body = merge(
    each.value.body,
    {
      properties = merge(
        each.value.body.properties,
        {
          privateLinkServiceConnections = [
            for conn in try(each.value.body.properties.privateLinkServiceConnections, []) : merge(
              conn,
              {
                properties = merge(
                  try(conn.properties, {}),
                  {
                    groupIds = ["domain"]
                  }
                )
              }
            )
          ]
        }
      )
    }
  )
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints) > 0 ? var.ignore_body_changes.network_private_endpoints : null
  response_export_values = ["properties.networkInterfaces"]
  retry                  = var.retry
  tags                   = each.value.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azapi_resource" "private_dns_zone_groups" {
  for_each = {
    for key, group in module.avm_interfaces.private_dns_zone_groups_azapi : key => group
    if length(local.private_endpoints[key].private_dns_zone_resource_ids) > 0
  }

  name      = each.value.name
  parent_id = azapi_resource.private_endpoints[each.key].id
  type      = var.resource_types.network_private_endpoints_private_dns_zone_groups
  body = {
    properties = {
      privateDnsZoneConfigs = [
        for index, config in each.value.body.properties.privateDnsZoneConfigs : merge(config, {
          name = "zone-${index}"
        })
      ]
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups) > 0 ? var.ignore_body_changes.network_private_endpoints_private_dns_zone_groups : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}

resource "azapi_resource" "private_endpoint_locks" {
  for_each = module.avm_interfaces.lock_private_endpoint_azapi

  name                   = coalesce(each.value.name, "lock-${local.private_endpoints[each.key].lock.kind}")
  parent_id              = azapi_resource.private_endpoints[each.value.pe_key].id
  type                   = var.resource_types.authorization_locks
  body                   = each.value.body
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    azapi_resource.private_dns_zone_groups,
    azapi_resource.private_endpoint_role_assignments,
  ]
}

resource "azapi_resource" "private_endpoint_role_assignments" {
  for_each = module.avm_interfaces.role_assignments_private_endpoint_azapi

  name                   = each.value.name
  parent_id              = azapi_resource.private_endpoints[each.value.pe_key].id
  type                   = var.resource_types.authorization_role_assignments
  body                   = each.value.body
  ignore_body_changes    = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
