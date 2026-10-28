variables {
  location = "eastus2"
  name     = "avm-output-${substr(uuid(), 0, 8)}"
}

run "create_test_prerequisites" {
  command = apply

  module {
    source = "./tests/integration/fixtures/prerequisites"
  }
}

run "preserves_read_only_resource_output" {
  command = apply

  variables {
    enable_telemetry = false
    parent_id        = run.create_test_prerequisites.domain_topic_resource_id
    destination      = run.create_test_prerequisites.destination
  }

  assert {
    condition     = length(keys(output.output)) > 0
    error_message = "The event subscription output must retain read-only fields returned by Azure."
  }
}
