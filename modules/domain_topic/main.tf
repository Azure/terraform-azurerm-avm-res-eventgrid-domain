resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.EventGrid/domains/topics@2025-02-15"
}
