# Create the Event Grid Domain using the AzAPI provider and the 2025-02-15 API version
resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.EventGrid/domains@2025-02-15"
  body = {
    properties = local.domain_properties
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_null_property   = true
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = ["identity"]
  tags                   = var.tags
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

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
  type      = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
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
  create_headers          = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers          = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_missing_property = true
  read_headers            = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers          = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

# required AVM resources interfaces (scoped to the created domain)
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  principal_type                         = each.value.principal_type
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
