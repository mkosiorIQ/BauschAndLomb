# Terraform Unit Tests

This directory contains unit tests for the IoT Edge monitoring infrastructure Terraform configuration.

## Overview

The unit tests validate the Terraform configuration without actually deploying resources to Azure. They use Terraform's built-in testing framework (available in Terraform 1.6.0+) to verify:

- Resource configurations match expected values
- Security settings are properly configured
- Naming conventions are followed
- Resource relationships are correct
- Routes and endpoints are properly defined

## Prerequisites

- **Terraform 1.6.0 or later** - The test framework was introduced in Terraform 1.6.0
- **Azure CLI** - Logged in to your Azure subscription
- **PowerShell** - For running the test script

## Test Files

- `main.tftest.hcl` - Main test file containing all unit test assertions
- `run-unit-tests.ps1` - PowerShell script to execute the tests
- `README.md` - This file

## Running the Tests

### Using PowerShell Script

From the project root:
```powershell
.\terraform\tests\unit\run-unit-tests.ps1
```

From anywhere:
```powershell
C:\Projects\Bench\Azure\IotEdge\BauschAndLomb\terraform\tests\unit\run-unit-tests.ps1
```

### Using Terraform CLI

From the terraform directory:
```bash
cd terraform
terraform test -filter=tests/unit/main.tftest.hcl
```

## Test Coverage

### Resource Group Tests
- ✓ Correct name (`bl-monitoring-rg1`)
- ✓ Correct location (`East US`)

### Storage Account Tests
- ✓ Standard tier
- ✓ LRS replication
- ✓ ADLS Gen2 enabled (hierarchical namespace)
- ✓ Minimum TLS 1.2 enforced
- ✓ System-assigned managed identity configured

### Storage Container Tests
- ✓ Container named `telemetry`
- ✓ Private access type

### Event Hub Namespace Tests
- ✓ Basic SKU
- ✓ Capacity set to 1

### Event Hub Tests
- ✓ 2 partitions configured
- ✓ 1-day message retention

### Event Hub Authorization Rule Tests
- ✓ Listen permission enabled
- ✓ Send permission enabled
- ✓ Manage permission disabled (security best practice)

### IoT Hub Tests
- ✓ S1 SKU
- ✓ Capacity set to 1
- ✓ Correct tags applied
- ✓ Storage endpoint configured correctly
- ✓ Event Hub endpoint configured correctly
- ✓ 60-second batch frequency for both endpoints

### IoT Hub Routes Tests
- ✓ Exactly 2 routes configured
- ✓ Storage route exists and is enabled
- ✓ Event Hub route exists and is enabled
- ✓ Both routes source from `DeviceMessages`
- ✓ Both routes condition is `true` (route all messages)

### Naming Convention Tests
- ✓ Storage account: `blmonitoring` + 5 digits
- ✓ Event Hub namespace: `bl-eh-namespace-` + 5 digits
- ✓ Event Hub: `bl-telemetry-eh-` + 5 digits
- ✓ IoT Hub: `bl-iothub-` + 5 digits

### Random Suffix Tests
- ✓ Minimum value: 10000
- ✓ Maximum value: 99999

## Understanding Test Results

### Successful Test Output
```
Success! 15 passed, 0 failed.
```

### Failed Test Output
If a test fails, you'll see:
```
Error: Test assertion failed

  on tests/unit/main.tftest.hcl line XX:
  XX:   assert {

  [Error message explaining what failed]
```

## Benefits of Unit Testing

1. **Early Detection** - Catch configuration errors before deploying to Azure
2. **No Cost** - Tests run locally without creating Azure resources
3. **Fast Feedback** - Tests complete in seconds
4. **Regression Prevention** - Ensure changes don't break existing configurations
5. **Documentation** - Tests serve as living documentation of expected configuration
6. **CI/CD Integration** - Can be integrated into automated pipelines

## Integration with CI/CD

These unit tests can be integrated into GitHub Actions or Azure DevOps pipelines to automatically validate Terraform changes before deployment:

```yaml
# Example GitHub Actions step
- name: Run Terraform Unit Tests
  run: |
    cd terraform
    terraform init
    terraform test -filter=tests/unit/main.tftest.hcl
```

## Next Steps

After unit tests pass, proceed to:
1. **Integration Tests** - Run `terraform\tests\integration\test-data-flow.ps1` to test actual data flow
2. **Deployment** - Use `test-terraform.ps1` to deploy to Azure
3. **Validation** - Verify resources in Azure Portal

## Troubleshooting

### Terraform Version Too Old
```
Upgrade Terraform to 1.6.0 or later:
- Download from: https://www.terraform.io/downloads
- Or use chocolatey: choco upgrade terraform
```

### Test Fails with "Plan Failed"
```
Ensure you're logged into Azure CLI:
az login
az account set --subscription <subscription-id>
```

### Test Fails Due to Configuration Change
Update the test assertions in `main.tftest.hcl` to match your new configuration requirements.
