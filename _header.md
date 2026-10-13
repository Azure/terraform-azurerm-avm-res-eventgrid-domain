# terraform-azurerm-avm-res-eventgrid-domain

Terraform Azure Verified Resource Module for managing an EventGrid Domain.

Private endpoints retain their existing endpoint, network interface, and connection
names when overrides are omitted. Endpoint location and resource group ID overrides,
static IP member names, DNS zone groups, locks, and role assignments are honored.
DNS groups are created only when zone IDs are supplied and management is enabled.
An omitted endpoint lock inherits the domain lock; set its `kind` to `None` to opt out.
