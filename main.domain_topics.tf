module "domain_topic" {
  source   = "./modules/domain_topic"
  for_each = var.domain_topics

  name      = each.value.name
  parent_id = azapi_resource.this.id
}

module "domain_topic_event_subscription" {
  source = "./modules/domain_topic_event_subscription"
  for_each = merge([
    for topic_key, topic in var.domain_topics : {
      for sub_key, subscription in topic.event_subscriptions :
      "${topic_key}-${sub_key}" => merge(subscription, {
        parent_id = module.domain_topic[topic_key].resource_id
      })
    }
  ]...)

  name                               = each.value.name
  parent_id                          = each.value.parent_id
  dead_letter_destination            = each.value.dead_letter_destination
  dead_letter_with_resource_identity = each.value.dead_letter_with_resource_identity
  delivery_with_resource_identity    = each.value.delivery_with_resource_identity
  destination                        = each.value.destination
  event_delivery_schema              = each.value.event_delivery_schema
  expiration_time_utc                = each.value.expiration_time_utc
  filter                             = each.value.filter
  labels                             = each.value.labels
  properties                         = each.value.properties
  retry_policy                       = each.value.retry_policy
}
