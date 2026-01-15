# IoT Edge Monitoring Infrastructure - Terraform

This directory contains Terraform configuration for deploying Azure IoT Edge monitoring infrastructure, including IoT Hub, Storage Account (ADLS Gen2), and Event Hub for telemetry ingestion and routing.

## Directory Structure

```
terraform/
│
├── config.tf                          # Main Terraform configuration
├── variables.tf                       # Input variables
├── README.md                          # This file
│
├── .terraform/                        # Terraform provider plugins (auto-generated)
├── .terraform.lock.hcl               # Dependency lock file (auto-generated)
├── terraform.tfstate                 # State file (auto-generated, DO NOT COMMIT)
├── terraform.tfstate.backup          # State backup (auto-generated, DO NOT COMMIT)
├── tfplan                            # Execution plan (auto-generated)
│
└── tests/                            # Test directory
    │
    ├── unit/                         # Unit tests
    │   ├── main.tftest.hcl          # Terraform test definitions
    │   ├── run-unit-tests.ps1       # PowerShell script to run unit tests
    │   └── README.md                # Unit test documentation
    │
    └── integration/                  # Integration tests
        ├── test-data-flow.ps1       # End-to-end data flow test
        └── README.md                # Integration test documentation
```

## Architecture Overview

This Terraform configuration deploys the following Azure resources:

```
┌─────────────────────────────────────────────────────────────────┐
│                      Azure Resource Group                       │
│                        bl-monitoring-rg1                        │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    IoT Hub (S1)                          │   │
│  │                  bl-iothub-{suffix}                      │   │
│  │                                                          │   │
│  │  Routes:                                                 │   │
│  │  • DeviceMessages → Storage Endpoint (batch: 60s)        │   │
│  │  • DeviceMessages → Event Hub Endpoint (batch: 60s)      │   │
│  └──────────────┬───────────────────────┬───────────────────┘   │
│                 │                       │                       │
│                 ▼                       ▼                       │
│  ┌──────────────────────┐   ┌──────────────────────────┐        │
│  │  Storage Account     │   │  Event Hub Namespace     │        │
│  │  (ADLS Gen2)         │   │  bl-eh-namespace-{suffix}│        │
│  │  blmonitoring{suffix}│   │                          │        │
│  │                      │   │  ┌────────────────────┐  │        │
│  │  ┌─────────────────┐ │   │  │   Event Hub        │  │        │
│  │  │   Container:    │ │   │  │   bl-telemetry-eh  │  │        │
│  │  │   telemetry     │ │   │  │   Partitions: 2    │  │        │
│  │  │   (private)     │ │   │  │   Retention: 1 day │  │        │
│  │  └─────────────────┘ │   │  └────────────────────┘  │        │
│  │                      │   │                          │        │
│  │  • Tier: Standard    │   │  • SKU: Basic            │        │
│  │  • Replication: LRS  │   │  • Capacity: 1           │        │
│  │  • TLS: 1.2 minimum  │   │                          │        │
│  │  • System Identity   │   │  Authorization Rule:     │        │
│  └──────────────────────┘   │  • Listen: Yes           │        │
│                             │  • Send: Yes             │        │
│                             │  • Manage: No            │        │
│                             └──────────────────────────┘        │
└─────────────────────────────────────────────────────────────────┘
```

## Resources Deployed
|-------------------------------------------------------------------------------------------------------|
| Resource Type           | Name Pattern                        | Purpose                               |
|-------------------------|-------------------------------------|---------------------------------------|
| **Resource Group**      | `bl-monitoring-rg1`                 | Container for all resources           |
| **Storage Account**     | `blmonitoring{5-digit-suffix}`      | ADLS Gen2 storage for telemetry data  |
| **Storage Container**   | `telemetry`                         | Private container for IoT messages    |
| **Event Hub Namespace** | `bl-eh-namespace-{5-digit-suffix}`  | Event streaming namespace             |
| **Event Hub**           | `bl-telemetry-eh-{5-digit-suffix}`  | Event hub for real-time telemetry     |
| **Event Hub Auth Rule** | `bl-eh-auth-rule-{5-digit-suffix}`  | Authorization for IoT Hub routing     |
| **IoT Hub**           | `bl-iothub-{5-digit-suffix}`        | IoT device management and routing       |
|-------------------------------------------------------------------------------------------------------|

**Note:** The 5-digit suffix (10000-99999) is randomly generated to ensure unique resource names across Azure.

## Prerequisites

### Required Tools
- **Terraform** 1.6.0 or later ([Download](https://www.terraform.io/downloads))
- **Azure CLI** 2.0 or later ([Download](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- **PowerShell** 5.1 or later (for test scripts)

### Azure Requirements
- Active Azure subscription
- Subscription ID: `046696af-1d89-4ff1-9ab1-411f666c1c06` (configured in config.tf)
- Permissions required:
  - Contributor or Owner role on subscription
  - Ability to create resource groups and resources

### Authentication
Log in to Azure CLI before running Terraform:
```bash
az login
az account set --subscription 046696af-1d89-4ff1-9ab1-411f666c1c06
```

## Quick Start

### 1. Initialize Terraform
```bash
cd terraform
terraform init
```

This downloads required providers and initializes the backend.

### 2. Validate Configuration
```bash
terraform validate
```

### 3. Preview Changes
```bash
terraform plan
```

Review the execution plan to see what will be created.

### 4. Deploy Infrastructure
```bash
terraform apply
```

Type `yes` when prompted to confirm deployment.

### 5. Verify Deployment
```bash
terraform show
```

View the deployed resources and their properties.

## Configuration Files

### config.tf

Main Terraform configuration file containing:
- Provider configuration (AzureRM 4.57.0)
- Resource definitions
- IoT Hub routing configuration
- Storage and Event Hub endpoints

**Key Configuration Points:**
- Line 12: Subscription ID
- Line 22-24: Resource group name and location
- Line 98, 105: Batch frequency (60 seconds)
- Line 113, 121: Route conditions (currently `true` - routes all messages)

### variables.tf

Input variables for the configuration:
- `subscription_id`: Azure subscription ID (currently unused, hardcoded in config.tf)

**Future Enhancement:** Move hardcoded values to variables for better reusability.

## Common Operations

### View Current State
```bash
terraform show
```

### List Resources
```bash
terraform state list
```

### Get Resource Details
```bash
terraform state show azurerm_iothub.iothub
terraform state show azurerm_storage_account.st
```

### Format Configuration
```bash
terraform fmt
```

### Validate Configuration
```bash
terraform validate
```

### Plan Changes
```bash
terraform plan -out=tfplan
```

### Apply Saved Plan
```bash
terraform apply tfplan
```

### Destroy Infrastructure
```bash
terraform destroy
```

**WARNING:** This will delete all deployed resources. Use with caution!

## Testing

### Unit Tests

Run unit tests to validate configuration without deploying:

```bash
cd terraform
terraform test -filter=tests/unit/main.tftest.hcl
```

Or use the PowerShell script:
```powershell
.\tests\unit\run-unit-tests.ps1
```

**What it tests:**
- Resource configuration values
- Security settings (TLS, permissions)
- Naming conventions
- Route configurations
- Endpoint settings

**Benefits:**
- Fast (completes in seconds)
- No Azure resources created
- No cost
- Catches configuration errors early

See [tests/unit/README.md](tests/unit/README.md) for details.

### Integration Tests

Run integration tests to verify end-to-end data flow:

```powershell
.\tests\integration\test-data-flow.ps1
```

**What it tests:**
- Device creation and authentication
- Message transmission to IoT Hub
- Data routing to Storage Account
- Data routing to Event Hub
- Message delivery timing

**Requirements:**
- Infrastructure must be deployed first
- Azure IoT CLI extension
- Takes ~2 minutes to complete

See [tests/integration/README.md](tests/integration/README.md) for details.

## Resource Configuration Details

### Storage Account (ADLS Gen2)
- **Tier:** Standard (general-purpose v2)
- **Replication:** Locally Redundant (LRS)
- **Hierarchical Namespace:** Enabled (ADLS Gen2)
- **TLS Version:** 1.2 minimum
- **Identity:** System-assigned managed identity
- **Container:** `telemetry` (private access)

**Data Format:** AVRO files organized by hub/partition/date/time

### Event Hub
- **Namespace SKU:** Basic
- **Capacity:** 1 throughput unit
- **Partitions:** 2
- **Message Retention:** 1 day
- **Authorization:** Listen + Send (no Manage for security)

### IoT Hub
- **SKU:** S1 (Standard tier)
- **Capacity:** 1 unit (400,000 messages/day)
- **Tags:**
  - `purpose`: testing-azure-iothub
  - `environment`: dev

**Endpoints:**
- `export-storage-endpoint`: Routes to Storage Container
- `export-eventhub-endpoint`: Routes to Event Hub
- **Batch Frequency:** 60 seconds for both endpoints

**Routes:**
- `export-telemetry-route-storage`: All device messages → Storage
- `export-telemetry-route-eventhub`: All device messages → Event Hub
- **Condition:** `true` (routes all messages)

## Security Considerations

### Implemented Security Features

1. **Storage Account**
   - TLS 1.2 minimum enforced
   - Private container access
   - System-assigned managed identity

2. **Event Hub**
   - Limited authorization rule (no Manage permission)
   - Listen + Send only

3. **Network**
   - All resources in same region (East US)
   - Resources communicate via Azure backbone

### Security Best Practices

- [ ] Enable Azure Private Link for Storage/Event Hub
- [ ] Implement network security groups (NSGs)
- [ ] Enable diagnostic logging
- [ ] Rotate connection strings regularly
- [ ] Use Azure Key Vault for secrets
- [ ] Enable Azure Defender for IoT

## Cost Estimation

### Monthly Cost Breakdown (Approximate)

| Resource | SKU/Tier | Estimated Cost |
|----------|----------|----------------|
| IoT Hub | S1 (1 unit) | ~$25/month |
| Storage Account | Standard LRS | ~$0.02/GB/month |
| Event Hub | Basic (1 TU) | ~$11/month |
| **Total** | | **~$36-40/month** |

**Notes:**
- Storage cost depends on data volume
- Actual costs may vary based on usage patterns
- Event Hub includes 1M events/day
- IoT Hub includes 400K messages/day

### Cost Optimization Tips

1. **Use Basic SKUs** where possible (already implemented)
2. **Set message retention** appropriately (1 day configured)
3. **Monitor unused resources** with Azure Advisor
4. **Clean up old data** in storage
5. **Use lifecycle policies** for storage archival

## Troubleshooting

### Common Issues

#### 1. "Subscription not found"
**Solution:**
```bash
az account list
az account set --subscription 046696af-1d89-4ff1-9ab1-411f666c1c06
```

#### 2. "Resource name already exists"
**Cause:** Random suffix collision (rare)
**Solution:** Run `terraform destroy` and `terraform apply` again to generate new suffix

#### 3. "Insufficient permissions"
**Solution:** Ensure you have Contributor role:
```bash
az role assignment list --assignee <your-email>
```

#### 4. "Provider not found"
**Solution:** Re-initialize Terraform:
```bash
terraform init -upgrade
```

#### 5. State file locked
**Cause:** Previous operation didn't complete
**Solution:** Wait 15 minutes or manually unlock:
```bash
terraform force-unlock <lock-id>
```

### Getting Help

- **Terraform Docs:** https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Azure IoT Hub:** https://docs.microsoft.com/en-us/azure/iot-hub/
- **Azure Storage:** https://docs.microsoft.com/en-us/azure/storage/
- **Azure Event Hubs:** https://docs.microsoft.com/en-us/azure/event-hubs/

## State Management

### Local State (Current Setup)

State is stored locally in `terraform.tfstate`:
- ✅ Simple for single-user scenarios
- ❌ No collaboration support
- ❌ Not suitable for teams
- ❌ No state locking

### Remote State (Recommended for Production)

Consider migrating to Azure Storage backend:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate"
    container_name       = "tfstate"
    key                  = "iot-monitoring.tfstate"
  }
}
```

**Benefits:**
- State locking
- Team collaboration
- Encrypted at rest
- Version history

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
    paths: ['terraform/**']

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.6.0

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Terraform Init
        run: terraform init
        working-directory: terraform

      - name: Terraform Validate
        run: terraform validate
        working-directory: terraform

      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: terraform

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve tfplan
        working-directory: terraform
```

### Azure DevOps Example

```yaml
trigger:
  paths:
    include:
      - terraform/*

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: TerraformInstaller@0
  inputs:
    terraformVersion: '1.6.0'

- task: AzureCLI@2
  inputs:
    azureSubscription: 'Azure-Subscription'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      cd terraform
      terraform init
      terraform validate
      terraform plan -out=tfplan
      terraform apply -auto-approve tfplan
```

## Best Practices

### Before Deployment
1. ✅ Run unit tests (`terraform test`)
2. ✅ Review plan output (`terraform plan`)
3. ✅ Verify subscription and permissions
4. ✅ Check resource quotas in region

### During Deployment
1. ✅ Monitor deployment progress
2. ✅ Check for warnings or errors
3. ✅ Verify resource creation in Azure Portal

### After Deployment
1. ✅ Run integration tests
2. ✅ Verify data flow in Portal
3. ✅ Set up monitoring and alerts
4. ✅ Document any manual steps taken
5. ✅ Commit state file to secure location (if using local state)

### Ongoing Maintenance
1. ✅ Regular Terraform version updates
2. ✅ Provider version updates
3. ✅ Security patch reviews
4. ✅ Cost optimization reviews
5. ✅ Backup state files regularly

## Migration and Upgrades

### Upgrading Provider Version

1. Update version in `config.tf`:
```hcl
required_providers {
  azurerm = {
    source  = "hashicorp/azurerm"
    version = "=4.58.0"  # New version
  }
}
```

2. Upgrade provider:
```bash
terraform init -upgrade
```

3. Test with plan:
```bash
terraform plan
```

### Importing Existing Resources

If resources already exist:
```bash
terraform import azurerm_resource_group.rg /subscriptions/{subscription-id}/resourceGroups/bl-monitoring-rg1
```

## Related Files

- **Root Directory:**
  - [../test-terraform.ps1](../test-terraform.ps1) - Full deployment and destroy test script
  - [../Readme.txt](../Readme.txt) - Project overview

- **Test Documentation:**
  - [tests/unit/README.md](tests/unit/README.md) - Unit test documentation
  - [tests/integration/README.md](tests/integration/README.md) - Integration test documentation

## Support and Contributions

### Reporting Issues
Create an issue with:
- Terraform version (`terraform version`)
- Azure CLI version (`az --version`)
- Error messages and logs
- Steps to reproduce

### Making Changes
1. Update configuration files
2. Run `terraform fmt` to format
3. Run unit tests
4. Test in dev environment first
5. Document changes in README

## License and Compliance

Ensure compliance with:
- Azure security policies
- Data residency requirements
- Industry regulations (HIPAA, GDPR, etc.)
- Company security standards

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-15 | Initial Terraform configuration |
| | | - IoT Hub with dual routing |
| | | - ADLS Gen2 storage |
| | | - Event Hub integration |
| | | - Unit and integration tests |

---

**Last Updated:** 2026-01-15
**Terraform Version:** 1.6.0+
**Provider Version:** hashicorp/azurerm 4.57.0
**Location:** East US
