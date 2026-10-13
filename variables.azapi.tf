variable "ignore_body_changes" {
  type = object({
    authorization_locks                               = optional(list(string), [])
    authorization_role_assignments                    = optional(list(string), [])
    eventgrid_domains                                 = optional(list(string), [])
    insights_diagnostic_settings                      = optional(list(string), [])
    network_private_endpoints                         = optional(list(string), [])
    network_private_endpoints_private_dns_zone_groups = optional(list(string), [])
    eventgrid_domains_topics = optional(object({
      eventgrid_domains_topics = optional(list(string), [])
    }), {})
    eventgrid_domains_topics_event_subscriptions = optional(object({
      eventgrid_domains_topics_event_subscriptions = optional(list(string), [])
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
Body-relative dot-notation paths ignored by AzAPI. Ignored configuration is not sent to Azure until the path is removed, and changes take effect only after apply. Non-empty lists require Terraform 1.11 or later.

- `authorization_locks` - Domain and private endpoint lock paths.
- `authorization_role_assignments` - Domain and private endpoint assignment paths.
- `eventgrid_domains` - Domain paths.
- `insights_diagnostic_settings` - Diagnostic setting paths.
- `network_private_endpoints` - Private endpoint paths.
- `network_private_endpoints_private_dns_zone_groups` - Private DNS group paths.
- `eventgrid_domains_topics` - Paths passed to topic submodules.
- `eventgrid_domains_topics.eventgrid_domains_topics` - Topic paths.
- `eventgrid_domains_topics_event_subscriptions` - Paths passed to topic subscription submodules.
- `eventgrid_domains_topics_event_subscriptions.eventgrid_domains_topics_event_subscriptions` - Topic subscription paths.
DESCRIPTION
  nullable    = false
}

variable "resource_types" {
  type = object({
    authorization_locks                               = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments                    = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    eventgrid_domains                                 = optional(string, "Microsoft.EventGrid/domains@2025-02-15")
    insights_diagnostic_settings                      = optional(string, "Microsoft.Insights/diagnosticSettings@2021-05-01-preview")
    network_private_endpoints                         = optional(string, "Microsoft.Network/privateEndpoints@2024-05-01")
    network_private_endpoints_private_dns_zone_groups = optional(string, "Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01")
    eventgrid_domains_topics = optional(object({
      eventgrid_domains_topics = optional(string)
    }), {})
    eventgrid_domains_topics_event_subscriptions = optional(object({
      eventgrid_domains_topics_event_subscriptions = optional(string)
    }), {})
  })
  default     = {}
  description = <<DESCRIPTION
AzAPI resource types and API versions. Defaults preserve the existing resource API versions.

- `authorization_locks` - Domain and private endpoint locks.
- `authorization_role_assignments` - Domain and private endpoint role assignments.
- `eventgrid_domains` - Event Grid Domain.
- `insights_diagnostic_settings` - Diagnostic settings.
- `network_private_endpoints` - Private endpoints.
- `network_private_endpoints_private_dns_zone_groups` - Private endpoint DNS zone groups.
- `eventgrid_domains_topics` - Overrides passed to domain topic submodules.
- `eventgrid_domains_topics.eventgrid_domains_topics` - Domain topic resource type.
- `eventgrid_domains_topics_event_subscriptions` - Overrides passed to topic subscription submodules.
- `eventgrid_domains_topics_event_subscriptions.eventgrid_domains_topics_event_subscriptions` - Topic subscription resource type.
DESCRIPTION
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Optional AzAPI retry configuration applied to all resources and local submodules. Fields are error_message_regex, interval_seconds, and max_interval_seconds; null preserves provider defaults."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Optional AzAPI create, read, update, and delete timeouts applied to all resources and local submodules. Values are Go durations such as 30m; null preserves provider defaults."
}
