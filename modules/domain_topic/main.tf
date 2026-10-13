resource "azapi_resource" "this" {
  name                   = var.name
  parent_id              = var.parent_id
  type                   = var.resource_types.eventgrid_domains_topics
  ignore_body_changes    = length(var.ignore_body_changes.eventgrid_domains_topics) > 0 ? var.ignore_body_changes.eventgrid_domains_topics : null
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
