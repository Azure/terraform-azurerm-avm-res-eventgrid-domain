mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/domain-tests/providers/Microsoft.EventGrid/domains/domain-tests"
      output = {
        identity = {
          principalId = "00000000-0000-0000-0000-000000000011"
          tenantId    = "00000000-0000-0000-0000-000000000012"
        }
        properties = {
          endpoint = "https://domain-tests.eastus-1.eventgrid.azure.net/api/events"
          networkInterfaces = [{
            id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/domain-tests/providers/Microsoft.Network/networkInterfaces/endpoint-nic"
          }]
        }
      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000012"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [{
          role_name = "Reader"
          id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
        }]
      }
    }
  }
}

mock_provider "random" {
  mock_resource "random_uuid" {
    defaults = {
      result = "00000000-0000-0000-0000-000000000099"
    }
  }
}

variables {
  name             = "domain-tests"
  location         = "eastus"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/domain-tests"
  enable_telemetry = false
}

run "omitted_endpoints_preserve_domain_defaults" {
  command = apply

  assert {
    condition = (
      length(output.private_endpoints) == 0 &&
      length(azapi_resource.private_dns_zone_groups) == 0 &&
      length(azapi_resource.private_endpoint_locks) == 0 &&
      length(azapi_resource.private_endpoint_role_assignments) == 0
    )
    error_message = "Omitting private endpoints must not create any endpoint or endpoint extension resources."
  }
  assert {
    condition = (
      azapi_resource.this.body.properties.publicNetworkAccess == "Disabled" &&
      azapi_resource.this.body.properties.disableLocalAuth &&
      azapi_resource.this.body.properties.minimumTlsVersionAllowed == "1.2" &&
      azapi_resource.this.body.properties.dataResidencyBoundary == "WithinGeopair" &&
      azapi_resource.this.type == "Microsoft.EventGrid/domains@2025-02-15" &&
      output.domain_endpoint == "https://domain-tests.eastus-1.eventgrid.azure.net/api/events"
    )
    error_message = "Endpoint repairs must preserve domain defaults and export the documented domain endpoint."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "generated_names_and_dynamic_addressing_remain_compatible" {
  command = apply

  variables {
    private_endpoints = {
      arbitrary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
      }
    }
  }
  assert {
    condition = (
      output.private_endpoints["arbitrary"].name == "pe-domain-tests-arbitrary" &&
      output.private_endpoints["arbitrary"].body.properties.customNetworkInterfaceName == "nic-pe-domain-tests-arbitrary" &&
      output.private_endpoints["arbitrary"].body.properties.privateLinkServiceConnections[0].name == "pcon-pep-${uuidv5("url", azapi_resource.this.id)}" &&
      output.private_endpoints["arbitrary"].parent_id == var.parent_id &&
      output.private_endpoints["arbitrary"].location == var.location &&
      output.private_endpoints["arbitrary"].type == "Microsoft.Network/privateEndpoints@2024-05-01"
    )
    error_message = "Existing endpoint, NIC, connection, scope, location and API defaults must remain unchanged."
  }
  assert {
    condition = (
      output.private_endpoints["arbitrary"].body.properties.privateLinkServiceConnections[0].properties.groupIds == ["domain"] &&
      length(output.private_endpoints["arbitrary"].body.properties.ipConfigurations) == 0 &&
      length(azapi_resource.private_dns_zone_groups) == 0
    )
    error_message = "Dynamic addressing must still target domain and must not create an empty DNS group."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "explicit_endpoint_name_preserves_legacy_connection_name" {
  command = apply

  variables {
    private_endpoints = {
      arbitrary = {
        name               = "existing-endpoint"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
      }
    }
  }
  assert {
    condition = (
      output.private_endpoints["arbitrary"].name == "existing-endpoint" &&
      output.private_endpoints["arbitrary"].body.properties.customNetworkInterfaceName == "nic-existing-endpoint" &&
      output.private_endpoints["arbitrary"].body.properties.privateLinkServiceConnections[0].name == "pcon-existing-endpoint"
    )
    error_message = "Adding domain subresource forwarding must not rename a working explicitly named endpoint or its NIC/connection."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "all_endpoint_controls_are_honored" {
  command = apply

  variables {
    tags = { inherited = "must-not-be-merged" }
    retry = {
      error_message_regex  = ["ScopeLocked"]
      interval_seconds     = 17
      max_interval_seconds = 53
    }
    timeouts = {
      create = "40m"
      read   = "10m"
      update = "30m"
      delete = "20m"
    }
    private_endpoints = {
      arbitrary = {
        name                            = "custom-endpoint"
        subnet_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        subresource_name                = "domain"
        private_service_connection_name = "custom-connection"
        network_interface_name          = "custom-nic"
        location                        = "westus2"
        resource_group_name             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/endpoint-group"
        tags                            = { endpoint = "replacement" }
        application_security_group_associations = {
          arbitrary_asg = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/applicationSecurityGroups/endpoints"
        }
        ip_configurations = {
          custom = {
            name               = "custom-ip"
            private_ip_address = "10.0.1.5"
            member_name        = "custom-member"
          }
          default_member = {
            name               = "default-ip"
            private_ip_address = "10.0.1.6"
          }
        }
        private_dns_zone_group_name = "custom-dns"
        private_dns_zone_resource_ids = [
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/privateDnsZones/privatelink.eventgrid.azure.net",
          "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/privateDnsZones/secondary.example",
        ]
        lock = {
          kind  = "ReadOnly"
          name  = "custom-lock"
          notes = "Keep this endpoint configuration."
        }
        role_assignments = {
          arbitrary_role = {
            name                                   = "00000000-0000-0000-0000-000000000021"
            role_definition_id_or_name             = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            principal_id                           = "00000000-0000-0000-0000-000000000022"
            description                            = "Endpoint reader"
            skip_service_principal_aad_check       = true
            condition                              = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'example'"
            condition_version                      = "2.0"
            principal_type                         = "ServicePrincipal"
            delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/identity/providers/Microsoft.ManagedIdentity/userAssignedIdentities/delegated"
          }
        }
      }
    }
  }
  override_resource {
    target = azapi_resource.private_endpoints["arbitrary"]
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/endpoint-group/providers/Microsoft.Network/privateEndpoints/custom-endpoint"
    }
  }
  assert {
    condition = (
      output.private_endpoints["arbitrary"].location == "westus2" &&
      output.private_endpoints["arbitrary"].parent_id == var.private_endpoints["arbitrary"].resource_group_name &&
      output.private_endpoints["arbitrary"].tags == tomap({ endpoint = "replacement" }) &&
      output.private_endpoints["arbitrary"].body.properties.customNetworkInterfaceName == "custom-nic" &&
      output.private_endpoints["arbitrary"].body.properties.privateLinkServiceConnections[0].name == "custom-connection" &&
      output.private_endpoints["arbitrary"].body.properties.applicationSecurityGroups[0].id == var.private_endpoints["arbitrary"].application_security_group_associations["arbitrary_asg"]
    )
    error_message = "Endpoint scope, location, replacement tags, names and application security groups must all be forwarded."
  }
  assert {
    condition = (
      output.private_endpoints["arbitrary"].body.properties.ipConfigurations[0].properties.groupId == "domain" &&
      output.private_endpoints["arbitrary"].body.properties.ipConfigurations[0].properties.memberName == "custom-member" &&
      output.private_endpoints["arbitrary"].body.properties.ipConfigurations[0].properties.privateIPAddress == "10.0.1.5" &&
      output.private_endpoints["arbitrary"].body.properties.ipConfigurations[1].properties.memberName == "default"
    )
    error_message = "Static IP configuration names, addresses, domain group and explicit/default member names must reach the ARM body."
  }
  assert {
    condition = (
      azapi_resource.private_dns_zone_groups["arbitrary"].name == "custom-dns" &&
      azapi_resource.private_dns_zone_groups["arbitrary"].parent_id == output.private_endpoints["arbitrary"].id &&
      length(azapi_resource.private_dns_zone_groups["arbitrary"].body.properties.privateDnsZoneConfigs) == 2 &&
      length(toset([for config in azapi_resource.private_dns_zone_groups["arbitrary"].body.properties.privateDnsZoneConfigs : config.name])) == 2 &&
      toset([for config in azapi_resource.private_dns_zone_groups["arbitrary"].body.properties.privateDnsZoneConfigs : config.properties.privateDnsZoneId]) == var.private_endpoints["arbitrary"].private_dns_zone_resource_ids
    )
    error_message = "DNS groups must use the endpoint parent, custom name, all supplied zones and unique configuration names."
  }
  assert {
    condition = (
      azapi_resource.private_endpoint_locks["arbitrary"].name == "custom-lock" &&
      azapi_resource.private_endpoint_locks["arbitrary"].parent_id == output.private_endpoints["arbitrary"].id &&
      azapi_resource.private_endpoint_locks["arbitrary"].body.properties.level == "ReadOnly" &&
      azapi_resource.private_endpoint_locks["arbitrary"].body.properties.notes == "Keep this endpoint configuration."
    )
    error_message = "Explicit endpoint lock names, levels and notes must be honored at the endpoint scope."
  }
  assert {
    condition = (
      azapi_resource.private_endpoint_role_assignments["arbitrary-arbitrary_role"].name == "00000000-0000-0000-0000-000000000021" &&
      azapi_resource.private_endpoint_role_assignments["arbitrary-arbitrary_role"].parent_id == output.private_endpoints["arbitrary"].id &&
      azapi_resource.private_endpoint_role_assignments["arbitrary-arbitrary_role"].body.properties.principalId == "00000000-0000-0000-0000-000000000022" &&
      azapi_resource.private_endpoint_role_assignments["arbitrary-arbitrary_role"].body.properties.description == "Endpoint reader" &&
      azapi_resource.private_endpoint_role_assignments["arbitrary-arbitrary_role"].body.properties.conditionVersion == "2.0" &&
      azapi_resource.private_endpoint_role_assignments["arbitrary-arbitrary_role"].body.properties.condition == var.private_endpoints["arbitrary"].role_assignments["arbitrary_role"].condition &&
      azapi_resource.private_endpoint_role_assignments["arbitrary-arbitrary_role"].body.properties.principalType == "ServicePrincipal" &&
      azapi_resource.private_endpoint_role_assignments["arbitrary-arbitrary_role"].body.properties.roleDefinitionId == var.private_endpoints["arbitrary"].role_assignments["arbitrary_role"].role_definition_id_or_name &&
      azapi_resource.private_endpoint_role_assignments["arbitrary-arbitrary_role"].body.properties.delegatedManagedIdentityResourceId == var.private_endpoints["arbitrary"].role_assignments["arbitrary_role"].delegated_managed_identity_resource_id
    )
    error_message = "Every supported endpoint role assignment field must reach the scoped assignment without being dropped by the utility."
  }
  assert {
    condition = alltrue([
      for resource in [
        azapi_resource.private_endpoints["arbitrary"],
        azapi_resource.private_dns_zone_groups["arbitrary"],
        azapi_resource.private_endpoint_locks["arbitrary"],
        azapi_resource.private_endpoint_role_assignments["arbitrary-arbitrary_role"],
      ] :
      resource.retry.interval_seconds == 17 &&
      resource.retry.max_interval_seconds == 53 &&
      resource.timeouts.create == "40m" &&
      resource.timeouts.read == "10m" &&
      resource.timeouts.update == "30m" &&
      resource.timeouts.delete == "20m"
    ])
    error_message = "Retry and operation timeouts must apply to every endpoint and extension resource."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "dns_management_opt_out_is_respected" {
  command = apply

  variables {
    private_endpoints_manage_dns_zone_group = false
    private_endpoints = {
      arbitrary = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/privateDnsZones/privatelink.eventgrid.azure.net"]
      }
    }
  }
  assert {
    condition     = length(output.private_endpoints) == 1 && length(azapi_resource.private_dns_zone_groups) == 0
    error_message = "Opting out of DNS management must keep the endpoint and leave DNS groups unmanaged."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "domain_lock_and_tags_propagate_with_per_endpoint_opt_out" {
  command = apply

  variables {
    lock = { kind = "CanNotDelete", notes = "Inherited lock." }
    tags = { environment = "test" }
    private_endpoints = {
      inherit = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
      }
      opt_out = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        lock               = { kind = "None" }
        tags               = {}
      }
    }
  }
  assert {
    condition = (
      length(azapi_resource.private_endpoint_locks) == 1 &&
      azapi_resource.private_endpoint_locks["inherit"].name == "lock-CanNotDelete" &&
      azapi_resource.private_endpoint_locks["inherit"].body.properties.notes == "Inherited lock." &&
      output.private_endpoints["inherit"].tags == var.tags &&
      length(output.private_endpoints["opt_out"].tags) == 0 &&
      azapi_resource.management_lock[0].body.properties.notes == "Inherited lock."
    )
    error_message = "Domain locks and tags must propagate unless an endpoint explicitly opts out or supplies replacement tags."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "role_names_and_generated_assignment_guids_work" {
  command = apply

  variables {
    private_endpoints = {
      arbitrary = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        role_assignments = {
          reader = {
            role_definition_id_or_name = "Reader"
            principal_id               = "00000000-0000-0000-0000-000000000022"
          }
        }
      }
    }
  }
  assert {
    condition = (
      azapi_resource.private_endpoint_role_assignments["arbitrary-reader"].name == "00000000-0000-0000-0000-000000000099" &&
      azapi_resource.private_endpoint_role_assignments["arbitrary-reader"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
    )
    error_message = "Role-name resolution and generated GUID names must work without Azure access when providers are mocked."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "explicit_null_optionals_use_compatible_defaults" {
  command = apply

  variables {
    private_endpoints = {
      arbitrary = {
        subnet_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        name                            = null
        network_interface_name          = null
        private_service_connection_name = null
        subresource_name                = null
        location                        = null
        resource_group_name             = null
        private_dns_zone_resource_ids   = null
        role_assignments                = null
        ip_configurations               = null
      }
    }
  }
  assert {
    condition = (
      output.private_endpoints["arbitrary"].name == "pe-domain-tests-arbitrary" &&
      output.private_endpoints["arbitrary"].location == var.location &&
      output.private_endpoints["arbitrary"].parent_id == var.parent_id &&
      length(azapi_resource.private_endpoint_role_assignments) == 0 &&
      length(azapi_resource.private_dns_zone_groups) == 0
    )
    error_message = "Explicit null optional fields must use the same defaults as omitted fields."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "topic_callers_and_output_keys_remain_compatible" {
  command = apply
  variables {
    domain_topics = {
      first = {
        name = "existing-topic"
        event_subscriptions = {
          subscriber = {
            name = "existing-subscription"
            destination = {
              endpointType = "EventHub"
              properties = {
                resourceId = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/delivery/providers/Microsoft.EventHub/namespaces/events/eventhubs/events"
              }
            }
          }
        }
      }
    }
  }
  override_resource {
    target = module.domain_topic["first"].azapi_resource.this
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/domain-tests/providers/Microsoft.EventGrid/domains/domain-tests/topics/existing-topic"
    }
  }
  assert {
    condition = (
      output.domain_topics["first"].name == "existing-topic" &&
      output.domain_topics["first"].resource_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/domain-tests/providers/Microsoft.EventGrid/domains/domain-tests/topics/existing-topic" &&
      output.domain_topic_event_subscriptions["first-subscriber"].name == "existing-subscription" &&
      length(output.private_endpoints) == 0
    )
    error_message = "Existing topic/subscription caller shapes, instance keys and outputs must remain unchanged when endpoint support is repaired."
  }
  providers = {
    azapi  = azapi
    random = random
  }
}

run "invalid_subnet_is_rejected" {
  command = plan
  variables {
    private_endpoints = { invalid = { subnet_resource_id = "/not-a-subnet" } }
  }
  expect_failures = [var.private_endpoints]
  providers = {
    azapi  = azapi
    random = random
  }
}

run "invalid_dns_zone_is_rejected" {
  command = plan
  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        private_dns_zone_resource_ids = ["/not-a-dns-zone"]
      }
    }
  }
  expect_failures = [var.private_endpoints]
  providers = {
    azapi  = azapi
    random = random
  }
}

run "invalid_asg_is_rejected" {
  command = plan
  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id                      = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        application_security_group_associations = { invalid = "/not-an-asg" }
      }
    }
  }
  expect_failures = [var.private_endpoints]
  providers = {
    azapi  = azapi
    random = random
  }
}

run "invalid_delegated_identity_is_rejected" {
  command = plan
  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        role_assignments = {
          invalid = {
            role_definition_id_or_name             = "Reader"
            principal_id                           = "00000000-0000-0000-0000-000000000022"
            delegated_managed_identity_resource_id = "/not-an-identity"
          }
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
  providers = {
    azapi  = azapi
    random = random
  }
}

run "non_domain_subresource_is_rejected" {
  command = plan
  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        subresource_name   = "topic"
      }
    }
  }
  expect_failures = [var.private_endpoints]
  providers = {
    azapi  = azapi
    random = random
  }
}

run "invalid_resource_group_override_is_rejected" {
  command = plan
  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        resource_group_name = "not-a-resource-id"
      }
    }
  }
  expect_failures = [var.private_endpoints]
  providers = {
    azapi  = azapi
    random = random
  }
}

run "invalid_lock_kind_is_rejected" {
  command = plan
  variables {
    private_endpoints = {
      invalid = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/network/providers/Microsoft.Network/virtualNetworks/vnet/subnets/endpoints"
        lock               = { kind = "Invalid" }
      }
    }
  }
  expect_failures = [var.private_endpoints]
  providers = {
    azapi  = azapi
    random = random
  }
}
