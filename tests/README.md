# Tests

Create tests in the provided subdirectories.

The domain topic event subscription integration test creates a uniquely named resource group, Event Grid domain and topic, storage account, queue, and event subscription in the selected test subscription. The test passes the created topic ID and storage queue destination to the independently tested submodule, then Terraform test cleanup removes the resources. The integration identity must have permission to create and delete these resources. Run only in a dedicated nonproduction test subscription.
