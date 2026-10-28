# Tests

Create tests in the provided subdirectories.

The domain topic event subscription integration test requires `TF_VAR_parent_id` to identify a dedicated, existing Event Grid domain topic and `TF_VAR_destination` to contain a valid Event Grid destination object. It creates a uniquely named subscription on that test topic and should not be run against production resources.
