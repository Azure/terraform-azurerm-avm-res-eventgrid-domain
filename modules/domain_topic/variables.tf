variable "name" {
  type        = string
  description = "The name of the domain topic."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,50}$", var.name))
    error_message = "The name must be between 3 and 50 characters long and can only contain letters, numbers, and hyphens."
  }
}

variable "parent_id" {
  type        = string
  description = "The resource ID of the parent EventGrid domain."
}
