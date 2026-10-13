variable "ignore_body_changes" {
  type = object({
    eventgrid_domains_topics_event_subscriptions = optional(list(string), [])
  })
  default     = {}
  description = "eventgrid_domains_topics_event_subscriptions contains body-relative dot-notation paths ignored on the subscription. Ignored configuration is not sent to Azure until removed; changes take effect after apply. Non-empty lists require Terraform 1.11 or later."
  nullable    = false
}

variable "resource_types" {
  type = object({
    eventgrid_domains_topics_event_subscriptions = optional(string, "Microsoft.EventGrid/domains/topics/eventSubscriptions@2025-02-15")
  })
  default     = {}
  description = "AzAPI types and API versions. eventgrid_domains_topics_event_subscriptions controls the topic event subscription resource."
  nullable    = false
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string))
    interval_seconds     = optional(number)
    max_interval_seconds = optional(number)
  })
  default     = null
  description = "Optional AzAPI error_message_regex, interval_seconds, and max_interval_seconds retry settings. Null preserves provider defaults."
}

variable "timeouts" {
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default     = null
  description = "Optional AzAPI create, read, update, and delete duration strings. Null preserves provider defaults."
}
