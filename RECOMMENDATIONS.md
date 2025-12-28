# Actionable Recommendations for Dev Branch

This document provides specific, actionable recommendations based on the code review of the dev branch.

## 🚀 Quick Actions (Do Before Merge)

### 1. Add Inline Comment for RBAC Wait ⏱️

**File:** `examples/default/main.tf`  
**Line:** Around line 114

**Current Code:**
```hcl
# Wait for RBAC propagation before creating event subscription
resource "time_sleep" "wait_for_rbac" {
  create_duration = "60s"

  depends_on = [
    azurerm_role_assignment.eventgrid_storage_queue_sender
  ]
}
```

**Recommended Change:**
```hcl
# Wait for RBAC propagation before creating event subscription
# Azure AD role assignments typically take 30-60 seconds to propagate globally
# This ensures the Event Grid Domain's managed identity has Storage Queue permissions
# before attempting to deliver events. Without this wait, the subscription creation
# may succeed but initial event deliveries will fail until propagation completes.
resource "time_sleep" "wait_for_rbac" {
  create_duration = "60s"

  depends_on = [
    azurerm_role_assignment.eventgrid_storage_queue_sender
  ]
}
```

**Why:** Better explains the timing choice and helps users understand the pattern.

**Effort:** 2 minutes

---

### 2. Run AVM Validation Tools ✔️

**Commands to run on dev branch:**

```bash
# Switch to dev branch
git checkout dev

# Set environment variable to disable TUI
export PORCH_NO_TUI=1

# Run pre-commit checks
./avm pre-commit

# Commit any changes from pre-commit
git add .
git commit -m "chore: avm pre-commit fixes"

# Run PR checks
./avm pr-check
```

**Expected Outcome:** All checks should pass. If any fail, address them before merge.

**Why:** Ensures AVM compliance and prevents CI/CD failures.

**Effort:** 10-15 minutes (mostly automated)

---

### 3. Update CHANGELOG 📝

**File:** `CHANGELOG.md` (create if doesn't exist)

**Add Section:**

```markdown
## [2.0.0] - 2025-12-28

### BREAKING CHANGES

- Migrated from azurerm provider to AzAPI provider for Event Grid Domain resource
- Changed from `Microsoft.EventGrid/domains@2024-06-01-preview` to `2025-02-15` API version
- Existing deployments will need to import resources or recreate
- `resource_group_name` variable removed, replaced with `parent_id`

### Added

- New submodule: `domain_event_subscription` for domain-level event subscriptions
- New submodule: `domain_topic` for domain topic management  
- New submodule: `domain_topic_event_subscription` for topic-level event subscriptions
- Private endpoint support using AVM interfaces pattern
- Comprehensive example showing keyless storage and managed identity
- System-assigned and user-assigned managed identity support
- Customer-managed encryption key support
- Diagnostic settings support

### Fixed

- Advanced filters now properly support conditional `value` (single) vs `values` (multiple) fields
- Added missing `principal_type` field to private endpoint role assignments
- Removed unused `domain_event_subscriptions` variable

### Changed

- Example now demonstrates keyless storage account (`allowSharedKeyAccess = false`)
- Example uses managed identity for secure event delivery
- Example includes RBAC role assignment with propagation wait
- Documentation enhanced with security best practices
- Removed `ignore_example_for_e2e` in favor of enhanced default example

### Security

- **Keyless Storage:** Example demonstrates storage account without shared access keys
- **Managed Identity:** Event Grid uses system-assigned identity for authentication
- **RBAC Authorization:** Uses "Storage Queue Data Message Sender" role
- **TLS 1.2:** Enforced minimum TLS version on storage account
- **No Secrets:** Zero hardcoded credentials in example code
```

**Why:** Documents breaking changes and helps users understand migration path.

**Effort:** 5-10 minutes

---

## 📋 Documentation Enhancements (Recommended)

### 4. Add Architecture Diagram to Example

**File:** `examples/default/_header.md`

**Add Before "Security Features" Section:**

```markdown
## Architecture

```
┌─────────────────────┐
│  Event Grid Domain  │
│  (System MI)        │
└──────────┬──────────┘
           │
           │ Uses Managed Identity
           │
           ▼
    ┌──────────────┐
    │  RBAC Role   │
    │  Assignment  │
    └──────┬───────┘
           │
           │ Storage Queue Data Message Sender
           │
           ▼
┌──────────────────────┐
│  Storage Account     │
│  (Keyless)          │
│  ├── Queue Service   │
│  │   └── Queue      │
│  └── No Shared Keys  │
└──────────────────────┘
           ▲
           │
           │ Events delivered via MI
           │
┌──────────┴──────────┐
│  Event Subscription │
│  (Domain-level)     │
└─────────────────────┘
```

**Event Flow:**
1. Event published to Event Grid Domain
2. Domain evaluates subscription filters (subject + advanced)
3. Matching events trigger delivery to storage queue
4. Event Grid authenticates using system-assigned managed identity
5. RBAC verifies permissions (Storage Queue Data Message Sender role)
6. Event delivered to queue (no shared keys used)
```

**Why:** Visual representation helps users understand the secure architecture.

**Effort:** 10 minutes

---

### 5. Add Troubleshooting Section

**File:** `examples/default/README.md` or `_header.md`

**Add New Section:**

```markdown
## Troubleshooting

### Event Delivery Failures

**Symptom:** Events are not being delivered to the storage queue.

**Common Causes:**

1. **RBAC Not Propagated**
   - Check: Has it been at least 60 seconds since role assignment?
   - Solution: Wait for propagation, or increase `time_sleep` duration to 90-120s
   - Verify: `az role assignment list --scope <storage-account-id> --assignee <principal-id>`

2. **Incorrect Role Assignment**
   - Check: Role is "Storage Queue Data Message Sender" (not "Message Receiver")
   - Check: Scope is the storage account (not the queue)
   - Verify: Review role assignment in Azure Portal

3. **Managed Identity Not Found**
   - Check: Event Grid Domain has system-assigned identity enabled
   - Check: Identity is referenced in event subscription
   - Verify: `az eventgrid domain show --name <name> --resource-group <rg> --query identity`

4. **Queue Does Not Exist**
   - Check: Queue was created before event subscription
   - Check: Queue name matches in subscription configuration
   - Verify: `az storage queue list --account-name <account-name> --auth-mode login`

### Deployment Issues

**Error: "The specified blob container does not exist" (or similar)**

This can occur if resources are created in the wrong order.

**Solution:** Ensure proper `depends_on` in event subscription module call:
```hcl
module "domain_event_subscription" {
  # ...
  depends_on = [
    time_sleep.wait_for_rbac,  # Wait for RBAC
    azapi_resource.storage_queue  # Queue must exist
  ]
}
```

**Error: "User does not have permission to perform action"**

This occurs when RBAC hasn't propagated yet.

**Solution:** Increase wait time or deploy in two phases:
1. First phase: Domain, identity, storage, RBAC
2. Second phase: Event subscription (after manual verification)

### Validation Commands

```bash
# Check Event Grid Domain identity
az eventgrid domain show \
  --name <domain-name> \
  --resource-group <rg-name> \
  --query "identity.principalId" -o tsv

# Check role assignments
az role assignment list \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage> \
  --query "[?principalId=='<principal-id>'].{Role:roleDefinitionName, Scope:scope}"

# Check event subscription
az eventgrid event-subscription show \
  --name <subscription-name> \
  --source-resource-id <domain-id>

# Test event delivery (using Azure CLI)
az eventgrid domain event-subscription show-endpoint-url \
  --name <subscription-name> \
  --domain-name <domain-name> \
  --resource-group <rg-name>
```
```

**Why:** Helps users diagnose and fix common issues independently.

**Effort:** 15 minutes

---

### 6. Add Advanced Filters Examples

**File:** `examples/default/_header.md` or create `examples/advanced-filters/`

**Add Section:**

```markdown
## Advanced Filters Examples

The example demonstrates advanced filtering. Here are more patterns:

### String Operations

```hcl
advanced_filters = [
  {
    key           = "data.category"
    operator_type = "StringIn"
    values        = ["orders", "shipping", "returns"]
  },
  {
    key           = "data.region"
    operator_type = "StringBeginsWith"
    value         = "US-"
  }
]
```

### Numeric Operations

```hcl
advanced_filters = [
  {
    key           = "data.amount"
    operator_type = "NumberGreaterThan"
    value         = 1000
  },
  {
    key           = "data.priority"
    operator_type = "NumberIn"
    values        = [1, 2, 3]
  }
]
```

### Boolean Operations

```hcl
advanced_filters = [
  {
    key           = "data.isPriority"
    operator_type = "BoolEquals"
    value         = true
  }
]
```

### Combined Filters

```hcl
filter = {
  subject_begins_with = "/orders/"
  included_event_types = ["OrderCreated", "OrderUpdated"]
  advanced_filters = [
    {
      key           = "data.amount"
      operator_type = "NumberGreaterThan"
      value         = 100
    },
    {
      key           = "data.status"
      operator_type = "StringIn"
      values        = ["pending", "processing"]
    }
  ]
}
```

### Key vs Values

- Use `value` (singular) for operators: `StringContains`, `StringBeginsWith`, `StringEndsWith`, `NumberGreaterThan`, `NumberLessThan`, `BoolEquals`
- Use `values` (plural) for operators: `StringIn`, `StringNotIn`, `NumberIn`, `NumberNotIn`
```

**Why:** Demonstrates the flexible filtering capabilities.

**Effort:** 10 minutes

---

## 🔮 Future Enhancements (Not Required for Merge)

### 7. Add Retry Logic for RBAC Verification

**Concept:** Replace `time_sleep` with actual verification

```hcl
# This is conceptual - would require custom provider or external script
resource "null_resource" "verify_rbac" {
  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      MAX_ATTEMPTS=12  # 12 attempts * 10 seconds = 2 minutes max
      ATTEMPT=0
      
      while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        if az role assignment list \
          --scope ${azapi_resource.storage_account.id} \
          --assignee ${module.test.system_assigned_mi_principal_id} \
          --query "[?roleDefinitionName=='Storage Queue Data Message Sender']" \
          -o tsv | grep -q .; then
          echo "RBAC propagated successfully"
          exit 0
        fi
        echo "Waiting for RBAC propagation... (attempt $((ATTEMPT+1))/$MAX_ATTEMPTS)"
        sleep 10
        ATTEMPT=$((ATTEMPT+1))
      done
      
      echo "RBAC did not propagate within 2 minutes"
      exit 1
    EOT
  }
  
  depends_on = [azurerm_role_assignment.eventgrid_storage_queue_sender]
}
```

**Why:** More deterministic than fixed wait time.

**Complexity:** Higher, requires external dependencies.

**Recommendation:** Good for production modules, overkill for examples.

---

### 8. Add Integration Tests

**File:** `tests/integration/`

**Test Cases:**
1. Deploy full example
2. Send test event to domain
3. Verify event delivered to queue
4. Verify event content matches
5. Verify filtering works
6. Clean up resources

**Why:** Ensures example actually works end-to-end.

**Effort:** 1-2 hours for comprehensive tests.

---

### 9. Add More Example Variants

**Suggested Examples:**

1. **Private Network Only**
   - Domain with private endpoint
   - Storage account with private endpoint
   - No public access
   - Private DNS zones

2. **Dead Letter Destination**
   - Configure dead letter with managed identity
   - Show monitoring and alerting

3. **Multiple Subscriptions**
   - Multiple queues
   - Different filters per subscription
   - Different delivery options

4. **Customer-Managed Keys**
   - Domain with CMK encryption
   - Key vault configuration
   - User-assigned identity for key access

**Why:** Shows different use cases and patterns.

**Effort:** 30-60 minutes per example variant.

---

## ✅ Validation Checklist

Before merging to main, verify:

- [ ] All AVM pre-commit checks pass
- [ ] All AVM pr-check validations pass
- [ ] Terraform fmt -recursive -check passes
- [ ] Terraform validate passes (on example)
- [ ] CHANGELOG updated with breaking changes
- [ ] Inline comment added for time_sleep
- [ ] Example deploys successfully
- [ ] Test event can be sent and received
- [ ] Documentation builds without errors
- [ ] No security vulnerabilities introduced
- [ ] All module outputs are documented
- [ ] All variables have descriptions
- [ ] Examples have README files
- [ ] Submodules have proper documentation

---

## 📊 Summary

### Must Do (20 minutes total)
1. Add inline comment for RBAC wait (2 min)
2. Run AVM validation tools (15 min)
3. Update CHANGELOG (3 min)

### Should Do (35 minutes total)
4. Add architecture diagram (10 min)
5. Add troubleshooting section (15 min)
6. Add advanced filters examples (10 min)

### Could Do (Future)
7. Implement RBAC verification retry logic
8. Add integration tests
9. Create additional example variants

### Priority Order
1. **Critical:** AVM validation, CHANGELOG
2. **High:** Inline comment
3. **Medium:** Troubleshooting section
4. **Low:** Additional examples

---

**Questions?** Refer to `CODE_REVIEW.md` for detailed analysis or `REVIEW_SUMMARY.md` for executive overview.
