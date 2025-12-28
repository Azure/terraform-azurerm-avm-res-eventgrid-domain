variable "name" {
  type        = string
  description = "The name of the event subscription."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,64}$", var.name))
    error_message = "The name must be between 3 and 64 characters long and can only contain letters, numbers, and hyphens."
  }
}

variable "parent_id" {
  type        = string
  description = "The resource ID of the parent domain topic."
}

variable "dead_letter_destination" {
  type        = any
  default     = null
  description = <<DESCRIPTION
The dead letter destination for the event subscription.

Example:
```terraform
dead_letter_destination = {
  endpointType = "StorageBlob"
  properties = {
    resourceId       = "/subscriptions/.../storageAccounts/..."
    blobContainerName = "deadletter"
  }
}
```
DESCRIPTION
}

variable "dead_letter_with_resource_identity" {
  type        = any
  default     = null
  description = <<DESCRIPTION
Information about the dead letter destination identity.

Example:
```terraform
dead_letter_with_resource_identity = {
  identity = {
    type               = "UserAssigned"
    userAssignedIdentity = "/subscriptions/.../userAssignedIdentities/..."
  }
  deadLetterDestination = {
    endpointType = "StorageBlob"
    properties = {
      resourceId       = "/subscriptions/.../storageAccounts/..."
      blobContainerName = "deadletter"
    }
  }
}
```
DESCRIPTION
}

variable "delivery_with_resource_identity" {
  type        = any
  default     = null
  description = <<DESCRIPTION
Information about the destination identity.

Example:
```terraform
delivery_with_resource_identity = {
  identity = {
    type               = "UserAssigned"
    userAssignedIdentity = "/subscriptions/.../userAssignedIdentities/..."
  }
  destination = {
    endpointType = "EventHub"
    properties = {
      resourceId = "/subscriptions/.../eventhubs/..."
    }
  }
}
```
DESCRIPTION
}

variable "destination" {
  type        = any
  default     = null
  description = <<DESCRIPTION
The destination for the event subscription. This is a dynamic object that can represent different destination types.

Example for Event Hub:
```terraform
destination = {
  endpointType = "EventHub"
  properties = {
    resourceId = "/subscriptions/.../eventhubs/..."
  }
}
```

Example for Storage Queue:
```terraform
destination = {
  endpointType = "StorageQueue"
  properties = {
    resourceId = "/subscriptions/.../storageAccounts/.../queueServices/default"
    queueName  = "myqueue"
  }
}
```
DESCRIPTION
}

variable "event_delivery_schema" {
  type        = string
  default     = null
  description = "The event delivery schema. Possible values: `EventGridSchema`, `CloudEventSchemaV1_0`, `CustomInputSchema`."

  validation {
    condition     = var.event_delivery_schema == null || can(regex("^(EventGridSchema|CloudEventSchemaV1_0|CustomInputSchema)$", var.event_delivery_schema))
    error_message = "event_delivery_schema must be one of: EventGridSchema, CloudEventSchemaV1_0, CustomInputSchema."
  }
}

variable "expiration_time_utc" {
  type        = string
  default     = null
  description = "The expiration time for the event subscription in UTC format."
}

variable "filter" {
  type = object({
    advanced_filters                    = optional(list(any))
    enable_advanced_filtering_on_arrays = optional(bool)
    included_event_types                = optional(list(string))
    is_subject_case_sensitive           = optional(bool, false)
    subject_begins_with                 = optional(string)
    subject_ends_with                   = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
Filter criteria for the event subscription.

- `advanced_filters` - (Optional) List of advanced filter objects.
- `enable_advanced_filtering_on_arrays` - (Optional) Enable advanced filtering on arrays.
- `included_event_types` - (Optional) List of event types to include.
- `is_subject_case_sensitive` - (Optional) Whether subject matching is case sensitive. Defaults to false.
- `subject_begins_with` - (Optional) Subject must begin with this string.
- `subject_ends_with` - (Optional) Subject must end with this string.
DESCRIPTION
}

variable "labels" {
  type        = list(string)
  default     = null
  description = "List of labels for the event subscription."
}

variable "properties" {
  type        = any
  default     = {}
  description = "Additional properties to pass directly to the event subscription. These will be merged with other configured properties."
}

variable "retry_policy" {
  type = object({
    event_time_to_live_in_minutes = optional(number, 1440)
    max_delivery_attempts         = optional(number, 30)
  })
  default     = null
  description = <<DESCRIPTION
The retry policy for the event subscription.

- `event_time_to_live_in_minutes` - (Optional) Time to live in minutes for events. Defaults to 1440 (24 hours).
- `max_delivery_attempts` - (Optional) Maximum number of delivery attempts. Defaults to 30.
DESCRIPTION
}
