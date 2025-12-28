variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the Event Grid Domain."

  validation {
    condition     = can(regex("^[a-zA-Z0-9\\-]{3,50}$", var.name))
    error_message = "The name must be between 3 and 50 characters and can contain only letters, numbers and hyphens."
  }
}

variable "parent_id" {
  type        = string
  description = <<DESCRIPTION
The ID of the resource group where the Event Grid Domain will be deployed.
DESCRIPTION

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+$", var.parent_id))
    error_message = "parent_id must be a valid resource group ID."
  }
}

# Domain-specific variables
variable "auto_create_topic_with_first_subscription" {
  type        = bool
  default     = null
  description = <<DESCRIPTION
Automatically create a topic within this domain when the first event subscription is created. Defaults to null (API default).
DESCRIPTION
}

variable "auto_delete_topic_with_last_subscription" {
  type        = bool
  default     = null
  description = <<DESCRIPTION
Automatically delete a topic within this domain when the last event subscription is deleted. Defaults to null (API default).
DESCRIPTION
}

# required AVM interfaces
# remove only if not supported by the resource
# tflint-ignore: terraform_unused_declarations
variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.
DESCRIPTION
}

variable "data_residency_boundary" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Data residency boundary to set on the Event Grid Domain. Maps to the ARM property `dataResidencyBoundary`. Allowed values: 'WithinGeopair' (API default) and 'WithinRegion'. If `null`, the module will set `WithinGeopair` in the ARM payload to make the default explicit.
DESCRIPTION

  validation {
    condition     = var.data_residency_boundary == null || contains(["WithinGeopair", "WithinRegion"], var.data_residency_boundary)
    error_message = "data_residency_boundary must be one of: 'WithinGeopair', 'WithinRegion', or null."
  }
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "disable_local_auth" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
When true the Event Grid Domain will have local authentication disabled (ARM property `disableLocalAuth`). The module will always set this property; default is `true` (local auth disabled).
DESCRIPTION
}

variable "domain_topics" {
  type = map(object({
    name = string
    event_subscriptions = optional(map(object({
      name                            = string
      destination                     = optional(any)
      delivery_with_resource_identity = optional(any)
      filter = optional(object({
        advanced_filters                    = optional(list(any))
        enable_advanced_filtering_on_arrays = optional(bool)
        included_event_types                = optional(list(string))
        is_subject_case_sensitive           = optional(bool, false)
        subject_begins_with                 = optional(string)
        subject_ends_with                   = optional(string)
      }))
      labels                = optional(list(string))
      event_delivery_schema = optional(string)
      retry_policy = optional(object({
        event_time_to_live_in_minutes = optional(number, 1440)
        max_delivery_attempts         = optional(number, 30)
      }))
      expiration_time_utc                = optional(string)
      dead_letter_destination            = optional(any)
      dead_letter_with_resource_identity = optional(any)
      properties                         = optional(any, {})
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of domain topics to create with their nested event subscriptions.

Each topic supports:
- `name` - (Required) The name of the domain topic.
- `event_subscriptions` - (Optional) A map of event subscriptions for this topic. Each subscription supports:
  - `name` - (Required) The name of the event subscription.
  - `destination` - (Optional) The destination for events.
  - `delivery_with_resource_identity` - (Optional) Delivery configuration with managed identity.
  - `filter` - (Optional) Event filtering configuration.
  - `labels` - (Optional) List of labels for the subscription.
  - `event_delivery_schema` - (Optional) Event delivery schema (EventGridSchema, CloudEventSchemaV1_0, CustomInputSchema).
  - `retry_policy` - (Optional) Retry policy configuration.
  - `expiration_time_utc` - (Optional) Expiration time in UTC.
  - `dead_letter_destination` - (Optional) Dead letter destination configuration.
  - `dead_letter_with_resource_identity` - (Optional) Dead letter destination with managed identity.
  - `properties` - (Optional) Additional properties to pass directly.

Example:
```terraform
domain_topics = {
  topic1 = {
    name = "my-topic"
    event_subscriptions = {
      sub1 = {
        name = "my-subscription"
        destination = {
          endpointType = "EventHub"
          properties = {
            resourceId = "/subscriptions/.../eventhubs/..."
          }
        }
      }
    }
  }
}
```
DESCRIPTION
  nullable    = false
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "event_type_info" {
  type = object({
    kind = optional(string)
    inline_event_types = optional(map(object({
      description       = optional(string)
      display_name      = optional(string)
      data_schema_url   = optional(string)
      documentation_url = optional(string)
    })))
  })
  default     = null
  description = <<DESCRIPTION
Event type information for the domain. This includes:
- `kind` - (Optional) The kind of event type info.
- `inline_event_types` - (Optional) Map of inline event types with their metadata.
DESCRIPTION
}

variable "inbound_ip_rules" {
  type = list(object({
    ip_mask = string
    action  = string
  }))
  default     = []
  description = <<DESCRIPTION
A list of inbound IP rules to restrict network access to the domain. Each rule must have an `ip_mask` and an `action` (e.g. 'Allow' or 'Deny').
DESCRIPTION
}

variable "input_schema" {
  type        = string
  default     = "EventGridSchema"
  description = <<DESCRIPTION
Optional input schema for the domain. Allowed values: 'EventGridSchema' (default), 'CloudEventSchemaV1_0', 'CustomEventSchema'.
DESCRIPTION

  validation {
    condition     = contains(["EventGridSchema", "CloudEventSchemaV1_0", "CustomEventSchema"], var.input_schema)
    error_message = "input_schema must be one of: 'EventGridSchema', 'CloudEventSchemaV1_0', or 'CustomEventSchema'."
  }
}

variable "input_schema_mapping" {
  type = object({
    input_schema_mapping_type = string
    properties = optional(object({
      data_version = optional(object({
        default_value = optional(string)
        source_field  = optional(string)
      }))
      event_time = optional(object({
        source_field = optional(string)
      }))
      event_type = optional(object({
        default_value = optional(string)
        source_field  = optional(string)
      }))
      id = optional(object({
        source_field = optional(string)
      }))
      subject = optional(object({
        default_value = optional(string)
        source_field  = optional(string)
      }))
      topic = optional(object({
        source_field = optional(string)
      }))
    }))
  })
  default     = null
  description = <<DESCRIPTION
Optional input schema mapping object. Use this to provide mappings when `input_schema` is 'CustomEventSchema'. The structure follows the ARM schema for JSON input mappings. Set `input_schema_mapping_type` to 'Json' and provide field mappings in the `properties` object.
DESCRIPTION

  validation {
    condition     = var.input_schema_mapping == null ? true : var.input_schema_mapping.input_schema_mapping_type == "Json"
    error_message = "input_schema_mapping_type must be 'Json' when input_schema_mapping is provided."
  }
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
DESCRIPTION
  nullable    = false
}

variable "minimum_tls_version_allowed" {
  type        = string
  default     = "1.2"
  description = <<DESCRIPTION
Minimum TLS version allowed for the Event Grid Domain. This maps to the ARM property `minimumTlsVersionAllowed`.
DESCRIPTION

  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version_allowed)
    error_message = "minimum_tls_version_allowed must be one of: '1.0', '1.1', '1.2'."
  }
}

variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of private endpoints to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of this resource.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.
DESCRIPTION
  nullable    = false
}

# This variable is used to determine if the private_dns_zone_group block should be included,
# or if it is to be managed externally, e.g. using Azure Policy.
# https://github.com/Azure/terraform-azurerm-avm-res-keyvault-vault/issues/32
# Alternatively you can use AzAPI, which does not have this issue.
variable "private_endpoints_manage_dns_zone_group" {
  type        = bool
  default     = true
  description = "Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy."
  nullable    = false
}

variable "properties" {
  type        = map(string)
  default     = {}
  description = "A map of additional string properties to set on the Event Grid Domain resource. This allows passing ARM schema properties that are not explicitly modeled by this module. For complex object properties, use the explicitly-defined module variables. See schema at: https://learn.microsoft.com/en-us/azure/templates/microsoft.eventgrid/2025-02-15/domains"
  nullable    = false
}

variable "public_network_access" {
  type        = string
  default     = "Disabled"
  description = <<DESCRIPTION
Controls public network access for the domain. Must be one of: 'Enabled', 'Disabled'. Defaults to 'Disabled' to reduce public exposure by default.
DESCRIPTION

  validation {
    condition     = contains(["Enabled", "Disabled"], var.public_network_access)
    error_message = "public_network_access must be one of: 'Enabled', 'Disabled'."
  }
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.
- `delegated_managed_identity_resource_id` - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.
- `principal_type` - The type of the principal_id. Possible values are `User`, `Group` and `ServicePrincipal`. Changing this forces a new resource to be created. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
