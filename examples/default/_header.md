# Default example

This example deploys an Event Grid Domain with a domain-level event subscription using **fully keyless security** with managed identity. The example demonstrates:

- Creating an Event Grid Domain with **system-assigned managed identity**
- Creating a **keyless storage account** (`allowSharedKeyAccess = false`) using AzAPI provider
- Creating a storage queue using AzAPI (no shared keys required)
- Configuring a domain event subscription using the `domain_event_subscription` submodule with **managed identity delivery**
- Setting up **RBAC role assignment** for Event Grid to access the storage queue
- Configuring event filtering with subject filters and advanced filters
- Setting up retry policies for event delivery
- Using labels for organization

## Security Features

This example follows Azure security best practices with a **fully keyless architecture**:

- ✅ **No Shared Access Keys** - Storage account has `allowSharedKeyAccess = false`
- ✅ **Managed Identity** - Event Grid uses system-assigned managed identity for authentication
- ✅ **RBAC-based Access** - Uses "Storage Queue Data Contributor" role for secure access
- ✅ **Secure Event Delivery** - Events are delivered using `delivery_with_resource_identity`
- ✅ **AzAPI Provider** - Used for storage resources to support keyless deployment

The domain event subscription delivers events to an Azure Storage Queue using managed identity authentication (no keys anywhere), filtered by subject prefix and event type, with custom retry policies.

## Why AzAPI Provider?

The `azurerm_storage_account` and `azurerm_storage_queue` resources require shared key access for Terraform state management. By using the `azapi` provider, we can deploy and manage storage resources without requiring shared key access, achieving a truly keyless infrastructure.

