# Event Subscription submodule for Event Grid Domains
# This submodule can be used to create event subscriptions on existing Event Grid Domains
# that may not be managed by the parent module.

locals {
  # Build delivery attribute mappings in Azure API format
  # Note: try() is required here because coalesce() evaluates all arguments,
  # and accessing .delivery_attribute_mappings on a null object would fail
  delivery_attribute_mappings = var.destination != null ? [
    for mapping in coalesce(
      try(var.destination.azure_function.delivery_attribute_mappings, null),
      try(var.destination.event_hub.delivery_attribute_mappings, null),
      try(var.destination.hybrid_connection.delivery_attribute_mappings, null),
      try(var.destination.service_bus_queue.delivery_attribute_mappings, null),
      try(var.destination.service_bus_topic.delivery_attribute_mappings, null),
      try(var.destination.webhook.delivery_attribute_mappings, null),
      []
      ) : {
      name = mapping.name
      type = mapping.type
      properties = mapping.type == "Static" ? {
        value    = mapping.value
        isSecret = mapping.is_secret
        } : {
        sourceField = mapping.source_field
      }
    }
  ] : []
  # Build delivery attribute mappings for delivery_with_resource_identity
  delivery_identity_attribute_mappings = var.delivery_with_resource_identity != null && var.delivery_with_resource_identity.destination != null ? [
    for mapping in coalesce(
      try(var.delivery_with_resource_identity.destination.azure_function.delivery_attribute_mappings, null),
      try(var.delivery_with_resource_identity.destination.event_hub.delivery_attribute_mappings, null),
      try(var.delivery_with_resource_identity.destination.hybrid_connection.delivery_attribute_mappings, null),
      try(var.delivery_with_resource_identity.destination.service_bus_queue.delivery_attribute_mappings, null),
      try(var.delivery_with_resource_identity.destination.service_bus_topic.delivery_attribute_mappings, null),
      try(var.delivery_with_resource_identity.destination.webhook.delivery_attribute_mappings, null),
      []
      ) : {
      name = mapping.name
      type = mapping.type
      properties = mapping.type == "Static" ? {
        value    = mapping.value
        isSecret = mapping.is_secret
        } : {
        sourceField = mapping.source_field
      }
    }
  ] : []
  # Destination JSON strings for delivery_with_resource_identity
  delivery_identity_azure_function = var.delivery_with_resource_identity != null && var.delivery_with_resource_identity.destination.azure_function != null ? jsonencode({
    resourceId                    = var.delivery_with_resource_identity.destination.azure_function.resource_id
    maxEventsPerBatch             = var.delivery_with_resource_identity.destination.azure_function.max_events_per_batch
    preferredBatchSizeInKilobytes = var.delivery_with_resource_identity.destination.azure_function.preferred_batch_size_in_kilobytes
    deliveryAttributeMappings     = local.delivery_identity_attribute_mappings
  }) : null
  # Determine delivery identity endpoint type
  delivery_identity_endpoint_type = (
    var.delivery_with_resource_identity == null ? null :
    var.delivery_with_resource_identity.destination.azure_function != null ? "AzureFunction" :
    var.delivery_with_resource_identity.destination.event_hub != null ? "EventHub" :
    var.delivery_with_resource_identity.destination.hybrid_connection != null ? "HybridConnection" :
    var.delivery_with_resource_identity.destination.namespace_topic != null ? "NamespaceTopic" :
    var.delivery_with_resource_identity.destination.service_bus_queue != null ? "ServiceBusQueue" :
    var.delivery_with_resource_identity.destination.service_bus_topic != null ? "ServiceBusTopic" :
    var.delivery_with_resource_identity.destination.storage_queue != null ? "StorageQueue" :
    var.delivery_with_resource_identity.destination.webhook != null ? "WebHook" : null
  )
  delivery_identity_event_hub = var.delivery_with_resource_identity != null && var.delivery_with_resource_identity.destination.event_hub != null ? jsonencode({
    resourceId                = var.delivery_with_resource_identity.destination.event_hub.resource_id
    deliveryAttributeMappings = local.delivery_identity_attribute_mappings
  }) : null
  delivery_identity_hybrid_connection = var.delivery_with_resource_identity != null && var.delivery_with_resource_identity.destination.hybrid_connection != null ? jsonencode({
    resourceId                = var.delivery_with_resource_identity.destination.hybrid_connection.resource_id
    deliveryAttributeMappings = local.delivery_identity_attribute_mappings
  }) : null
  delivery_identity_namespace_topic = var.delivery_with_resource_identity != null && var.delivery_with_resource_identity.destination.namespace_topic != null ? jsonencode({
    resourceId = var.delivery_with_resource_identity.destination.namespace_topic.resource_id
  }) : null
  delivery_identity_properties = var.delivery_with_resource_identity == null ? null : (
    length(local.delivery_identity_properties_list) > 0 ? jsondecode(local.delivery_identity_properties_list[0]) : null
  )
  # Lookup delivery identity properties
  delivery_identity_properties_list = compact([
    local.delivery_identity_azure_function,
    local.delivery_identity_event_hub,
    local.delivery_identity_hybrid_connection,
    local.delivery_identity_namespace_topic,
    local.delivery_identity_service_bus_queue,
    local.delivery_identity_service_bus_topic,
    local.delivery_identity_storage_queue,
    local.delivery_identity_webhook
  ])
  delivery_identity_service_bus_queue = var.delivery_with_resource_identity != null && var.delivery_with_resource_identity.destination.service_bus_queue != null ? jsonencode({
    resourceId                = var.delivery_with_resource_identity.destination.service_bus_queue.resource_id
    deliveryAttributeMappings = local.delivery_identity_attribute_mappings
  }) : null
  delivery_identity_service_bus_topic = var.delivery_with_resource_identity != null && var.delivery_with_resource_identity.destination.service_bus_topic != null ? jsonencode({
    resourceId                = var.delivery_with_resource_identity.destination.service_bus_topic.resource_id
    deliveryAttributeMappings = local.delivery_identity_attribute_mappings
  }) : null
  delivery_identity_storage_queue = var.delivery_with_resource_identity != null && var.delivery_with_resource_identity.destination.storage_queue != null ? jsonencode({
    resourceId                      = var.delivery_with_resource_identity.destination.storage_queue.resource_id
    queueName                       = var.delivery_with_resource_identity.destination.storage_queue.queue_name
    queueMessageTimeToLiveInSeconds = var.delivery_with_resource_identity.destination.storage_queue.queue_message_time_to_live_in_seconds
  }) : null
  delivery_identity_webhook = var.delivery_with_resource_identity != null && var.delivery_with_resource_identity.destination.webhook != null ? jsonencode({
    endpointUrl                    = var.delivery_with_resource_identity.destination.webhook.endpoint_url
    maxEventsPerBatch              = var.delivery_with_resource_identity.destination.webhook.max_events_per_batch
    preferredBatchSizeInKilobytes  = var.delivery_with_resource_identity.destination.webhook.preferred_batch_size_in_kilobytes
    azureActiveDirectoryTenantId   = var.delivery_with_resource_identity.destination.webhook.azure_active_directory_tenant_id
    azureActiveDirectoryAppIdOrUri = var.delivery_with_resource_identity.destination.webhook.azure_active_directory_app_id_or_uri
    minimumTlsVersionAllowed       = var.delivery_with_resource_identity.destination.webhook.minimum_tls_version_allowed
    deliveryAttributeMappings      = local.delivery_identity_attribute_mappings
  }) : null
  # Destination JSON strings for different destination types
  destination_azure_function = var.destination != null && var.destination.azure_function != null ? jsonencode({
    resourceId                    = var.destination.azure_function.resource_id
    maxEventsPerBatch             = var.destination.azure_function.max_events_per_batch
    preferredBatchSizeInKilobytes = var.destination.azure_function.preferred_batch_size_in_kilobytes
    deliveryAttributeMappings     = local.delivery_attribute_mappings
  }) : null
  # Determine destination endpoint type
  destination_endpoint_type = (
    var.destination == null ? null :
    var.destination.azure_function != null ? "AzureFunction" :
    var.destination.event_hub != null ? "EventHub" :
    var.destination.hybrid_connection != null ? "HybridConnection" :
    var.destination.monitor_alert != null ? "MonitorAlert" :
    var.destination.namespace_topic != null ? "NamespaceTopic" :
    var.destination.service_bus_queue != null ? "ServiceBusQueue" :
    var.destination.service_bus_topic != null ? "ServiceBusTopic" :
    var.destination.storage_queue != null ? "StorageQueue" :
    var.destination.webhook != null ? "WebHook" : null
  )
  destination_event_hub = var.destination != null && var.destination.event_hub != null ? jsonencode({
    resourceId                = var.destination.event_hub.resource_id
    deliveryAttributeMappings = local.delivery_attribute_mappings
  }) : null
  destination_hybrid_connection = var.destination != null && var.destination.hybrid_connection != null ? jsonencode({
    resourceId                = var.destination.hybrid_connection.resource_id
    deliveryAttributeMappings = local.delivery_attribute_mappings
  }) : null
  destination_monitor_alert = var.destination != null && var.destination.monitor_alert != null ? jsonencode({
    severity     = var.destination.monitor_alert.severity
    actionGroups = var.destination.monitor_alert.action_groups
    description  = var.destination.monitor_alert.description
  }) : null
  destination_namespace_topic = var.destination != null && var.destination.namespace_topic != null ? jsonencode({
    resourceId = var.destination.namespace_topic.resource_id
  }) : null
  destination_properties = var.destination == null ? null : (
    length(local.destination_properties_list) > 0 ? jsondecode(local.destination_properties_list[0]) : null
  )
  # Lookup destination properties - use compact() and one() to avoid type unification issues
  # by selecting from a list instead of chained conditionals
  destination_properties_list = compact([
    local.destination_azure_function,
    local.destination_event_hub,
    local.destination_hybrid_connection,
    local.destination_monitor_alert,
    local.destination_namespace_topic,
    local.destination_service_bus_queue,
    local.destination_service_bus_topic,
    local.destination_storage_queue,
    local.destination_webhook
  ])
  destination_service_bus_queue = var.destination != null && var.destination.service_bus_queue != null ? jsonencode({
    resourceId                = var.destination.service_bus_queue.resource_id
    deliveryAttributeMappings = local.delivery_attribute_mappings
  }) : null
  destination_service_bus_topic = var.destination != null && var.destination.service_bus_topic != null ? jsonencode({
    resourceId                = var.destination.service_bus_topic.resource_id
    deliveryAttributeMappings = local.delivery_attribute_mappings
  }) : null
  destination_storage_queue = var.destination != null && var.destination.storage_queue != null ? jsonencode({
    resourceId                      = var.destination.storage_queue.resource_id
    queueName                       = var.destination.storage_queue.queue_name
    queueMessageTimeToLiveInSeconds = var.destination.storage_queue.queue_message_time_to_live_in_seconds
  }) : null
  destination_webhook = var.destination != null && var.destination.webhook != null ? jsonencode({
    endpointUrl                    = var.destination.webhook.endpoint_url
    maxEventsPerBatch              = var.destination.webhook.max_events_per_batch
    preferredBatchSizeInKilobytes  = var.destination.webhook.preferred_batch_size_in_kilobytes
    azureActiveDirectoryTenantId   = var.destination.webhook.azure_active_directory_tenant_id
    azureActiveDirectoryAppIdOrUri = var.destination.webhook.azure_active_directory_app_id_or_uri
    minimumTlsVersionAllowed       = var.destination.webhook.minimum_tls_version_allowed
    deliveryAttributeMappings      = local.delivery_attribute_mappings
  }) : null
  # Transform filter
  filter = var.filter != null ? {
    subjectBeginsWith               = var.filter.subject_begins_with
    subjectEndsWith                 = var.filter.subject_ends_with
    includedEventTypes              = var.filter.included_event_types
    isSubjectCaseSensitive          = var.filter.is_subject_case_sensitive
    enableAdvancedFilteringOnArrays = var.filter.enable_advanced_filtering_on_arrays
    advancedFilters = var.filter.advanced_filters != null ? [
      for f in var.filter.advanced_filters : merge(
        {
          key          = f.key
          operatorType = f.operator_type
        },
        f.value != null ? { value = f.value } : {},
        f.values != null ? { values = f.values } : {}
      )
    ] : null
  } : null
  # Transform retry policy
  retry_policy = var.retry_policy != null ? {
    maxDeliveryAttempts      = var.retry_policy.max_delivery_attempts
    eventTimeToLiveInMinutes = var.retry_policy.event_time_to_live_in_minutes
  } : null
}

resource "azapi_resource" "this" {
  name      = var.name
  parent_id = var.event_grid_domain_resource_id
  type      = "Microsoft.EventGrid/domains/eventSubscriptions@2025-02-15"
  body = {
    properties = merge(
      # Direct destination (without managed identity)
      local.destination_endpoint_type != null ? {
        destination = {
          endpointType = local.destination_endpoint_type
          properties   = local.destination_properties
        }
      } : {},

      # Delivery with resource identity
      var.delivery_with_resource_identity != null ? {
        deliveryWithResourceIdentity = {
          identity = {
            type                 = var.delivery_with_resource_identity.identity.type
            userAssignedIdentity = var.delivery_with_resource_identity.identity.user_assigned_identity
          }
          destination = {
            endpointType = local.delivery_identity_endpoint_type
            properties   = local.delivery_identity_properties
          }
        }
      } : {},

      # Dead letter destination
      var.dead_letter_destination != null ? {
        deadLetterDestination = {
          endpointType = "StorageBlob"
          properties = {
            resourceId        = var.dead_letter_destination.storage_blob.resource_id
            blobContainerName = var.dead_letter_destination.storage_blob.blob_container_name
          }
        }
      } : {},

      # Dead letter with resource identity
      var.dead_letter_with_resource_identity != null ? {
        deadLetterWithResourceIdentity = {
          identity = {
            type                 = var.dead_letter_with_resource_identity.identity.type
            userAssignedIdentity = var.dead_letter_with_resource_identity.identity.user_assigned_identity
          }
          deadLetterDestination = {
            endpointType = "StorageBlob"
            properties = {
              resourceId        = var.dead_letter_with_resource_identity.dead_letter_destination.storage_blob.resource_id
              blobContainerName = var.dead_letter_with_resource_identity.dead_letter_destination.storage_blob.blob_container_name
            }
          }
        }
      } : {},

      # Event delivery schema
      var.event_delivery_schema != null ? {
        eventDeliverySchema = var.event_delivery_schema
      } : {},

      # Expiration time
      var.expiration_time_utc != null ? {
        expirationTimeUtc = var.expiration_time_utc
      } : {},

      # Filter
      local.filter != null ? {
        filter = local.filter
      } : {},

      # Labels
      var.labels != null ? {
        labels = var.labels
      } : {},

      # Retry policy
      local.retry_policy != null ? {
        retryPolicy = local.retry_policy
      } : {}
    )
  }
  ignore_casing             = true
  ignore_missing_property   = true
  ignore_null_property      = true
  response_export_values    = ["*"]
  schema_validation_enabled = false
}
