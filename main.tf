# Create the Event Grid Domain using the AzAPI provider and the 2025-02-15 API version
resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.eventgrid_domains
  body = {
    properties = local.domain_properties
  }
  ignore_body_changes    = length(var.ignore_body_changes.eventgrid_domains) > 0 ? var.ignore_body_changes.eventgrid_domains : null
  ignore_null_property   = true
  response_export_values = ["identity", "properties.endpoint"]
  retry                  = var.retry
  tags                   = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  dynamic "identity" {
    for_each = local.identity_required ? [1] : []

    content {
      type         = local.identity_type_str
      identity_ids = local.identity_required && length(local.user_assigned_id_map) > 0 ? keys(local.user_assigned_id_map) : null
    }
  }
}

# Diagnostic settings for the Event Grid Domain using AzAPI provider
resource "azapi_resource" "diagnostic_settings" {
  for_each = var.diagnostic_settings

  name      = each.value.name != null ? each.value.name : "diag-${var.name}"
  parent_id = azapi_resource.this.id
  type      = var.resource_types.insights_diagnostic_settings
  body = {
    properties = {
      eventHubAuthorizationRuleId = each.value.event_hub_authorization_rule_resource_id
      eventHubName                = each.value.event_hub_name
      logAnalyticsDestinationType = each.value.log_analytics_destination_type
      marketplacePartnerId        = each.value.marketplace_partner_resource_id
      storageAccountId            = each.value.storage_account_resource_id
      workspaceId                 = each.value.workspace_resource_id

      logs = [
        for log_category in(length(each.value.log_categories) > 0 ? each.value.log_categories : (length(each.value.log_groups) > 0 ? each.value.log_groups : [])) : {
          category      = length(each.value.log_categories) > 0 ? log_category : null
          categoryGroup = length(each.value.log_groups) > 0 ? log_category : null
          enabled       = true
        }
      ]

      metrics = [
        for metric_category in each.value.metric_categories : {
          category = metric_category
          enabled  = true
        }
      ]
    }
  }
  ignore_body_changes     = length(var.ignore_body_changes.insights_diagnostic_settings) > 0 ? var.ignore_body_changes.insights_diagnostic_settings : null
  ignore_missing_property = true
  response_export_values  = []
  retry                   = var.retry

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

# required AVM resources interfaces (scoped to the created domain)
resource "azapi_resource" "management_lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(var.lock.name, "lock-${var.lock.kind}")
  parent_id = azapi_resource.this.id
  type      = var.resource_types.authorization_locks
  body = {
    properties = {
      level = var.lock.kind
      notes = coalesce(var.lock.notes, var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources.")
    }
  }
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
    azapi_resource.diagnostic_settings,
    azapi_resource.role_assignment,
    azapi_resource.private_endpoints,
    azapi_resource.private_dns_zone_groups,
    azapi_resource.private_endpoint_locks,
    azapi_resource.private_endpoint_role_assignments,
    module.domain_topic,
    module.domain_topic_event_subscription,
  ]
}

resource "azapi_resource" "role_assignment" {
  for_each = var.role_assignments

  name      = uuid()
  parent_id = azapi_resource.this.id
  type      = var.resource_types.authorization_role_assignments
  body = {
    properties = {
      principalId                        = each.value.principal_id
      roleDefinitionId                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : "${azapi_resource.this.id}${local.role_definition_resource_substring}/${each.value.role_definition_id_or_name}"
      condition                          = each.value.condition
      conditionVersion                   = each.value.condition_version
      delegatedManagedIdentityResourceId = each.value.delegated_managed_identity_resource_id
      principalType                      = each.value.principal_type
      description                        = "Role assignment managed by AVM module"
    }
  }
  ignore_body_changes     = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  ignore_missing_property = true
  response_export_values  = []
  retry                   = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    ignore_changes = [name]
  }
}
