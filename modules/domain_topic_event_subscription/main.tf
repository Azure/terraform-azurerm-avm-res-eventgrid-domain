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
  type      = "Microsoft.EventGrid/domains/topics/eventSubscriptions@2025-02-15"
  body = {
    properties = local.subscription_properties
  }

  lifecycle {
    ignore_changes = [body]
  }
}
