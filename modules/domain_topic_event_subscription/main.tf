locals {
  subscription_properties = merge(
    var.properties,
    var.destination != null ? { destination = var.destination } : {},
    var.delivery_with_resource_identity != null ? { deliveryWithResourceIdentity = var.delivery_with_resource_identity } : {},
    var.filter != null ? { filter = var.filter } : {},
    var.labels != null ? { labels = var.labels } : {},
    var.event_delivery_schema != null ? { eventDeliverySchema = var.event_delivery_schema } : {},
    var.retry_policy != null ? { retryPolicy = var.retry_policy } : {},
    var.expiration_time_utc != null ? { expirationTimeUtc = var.expiration_time_utc } : {},
    var.dead_letter_destination != null ? { deadLetterDestination = var.dead_letter_destination } : {},
    var.dead_letter_with_resource_identity != null ? { deadLetterWithResourceIdentity = var.dead_letter_with_resource_identity } : {}
  )
}

resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.parent_id
  type      = var.resource_types.eventgrid_domains_topics_event_subscriptions
  body = {
    properties = local.subscription_properties
  }
  ignore_body_changes    = length(var.ignore_body_changes.eventgrid_domains_topics_event_subscriptions) > 0 ? var.ignore_body_changes.eventgrid_domains_topics_event_subscriptions : null
  response_export_values = null
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

  lifecycle {
    ignore_changes = [body]
  }
}
