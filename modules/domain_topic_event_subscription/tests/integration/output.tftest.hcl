run "preserves_read_only_resource_output" {
  command = apply

  variables {
    enable_telemetry = false
    location         = "eastus2"
    name             = "avm-output-${substr(uuid(), 0, 8)}"
  }

  assert {
    condition     = length(keys(output.output)) > 0
    error_message = "The event subscription output must retain read-only fields returned by Azure."
  }
}
