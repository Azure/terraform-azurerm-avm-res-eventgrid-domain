output "domain_topic_resource_id" {
  value = azapi_resource.domain_topic.id
}

output "destination" {
  value = {
    endpointType = "StorageQueue"
    properties = {
      resourceId = azapi_resource.storage_account.id
      queueName  = azapi_resource.storage_queue.name
    }
  }
}
