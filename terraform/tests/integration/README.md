# Terraform Integration Tests

This directory contains integration tests for the IoT Edge monitoring infrastructure that validate end-to-end data flow from IoT Hub to both Storage Account and Event Hub.

## Overview

The integration tests deploy to a live Azure environment and verify that:

- IoT devices can be created and authenticated
- Telemetry messages can be sent to IoT Hub
- Messages are successfully routed to Azure Storage (ADLS Gen2)
- Messages are successfully routed to Azure Event Hub
- Data appears in both destinations within expected timeframes

## Prerequisites

- **Azure CLI** - Installed and logged in (`az login`)
- **Azure Subscription** - Active subscription with appropriate permissions
- **Deployed Infrastructure** - Terraform resources must be deployed first
- **Azure IoT Extension** - Install with `az extension add --name azure-iot`
- **PowerShell** - PowerShell 5.1 or later

## Test Files

- `test-data-flow.ps1` - Main integration test script
- `README.md` - This file

## Running the Tests

### Step 1: Deploy Infrastructure

First, ensure the Terraform infrastructure is deployed:

```powershell
cd terraform
terraform init
terraform apply
```

**IMPORTANT:** Do NOT run `terraform destroy` after applying - the integration tests need the resources to exist.

### Step 2: Run Integration Tests

From the project root:
```powershell
.\terraform\tests\integration\test-data-flow.ps1
```

From anywhere:
```powershell
C:\Projects\Bench\Azure\IotEdge\BauschAndLomb\terraform\tests\integration\test-data-flow.ps1
```

### Step 3: Review Results

The script provides detailed output showing:
- Number of messages sent
- Blobs found in storage
- Messages received in Event Hub
- Sample data contents

## What the Test Does

### 1. Resource Discovery
- Retrieves IoT Hub name from deployed resources
- Retrieves Storage Account name
- Retrieves Event Hub namespace and hub name

### 2. Device Creation
- Creates a temporary test IoT device with random ID
- Generates device credentials

### 3. Telemetry Transmission
- Sends 5 test messages with:
  - Device ID
  - Timestamp (ISO 8601 format)
  - Temperature (20-30°C)
  - Humidity (40-60%)
  - Message number

### 4. Wait Period
- Waits 90 seconds for message processing
- Accounts for IoT Hub's 60-second batch frequency

### 5. Storage Verification
- Lists blobs in the telemetry container
- Displays blob metadata (size, modification time)
- Downloads and displays first blob content

### 6. Event Hub Verification
- Retrieves Event Hub metrics for last 10 minutes
- Shows incoming message counts
- Displays time-series breakdown

### 7. Cleanup
- Deletes the test device
- Returns to original directory

## Expected Output

### Successful Test Run

```
=== Retrieving Terraform Outputs ===
IoT Hub: bl-iothub-12345
Storage Account: blmonitoring12345
Event Hub Namespace: bl-eh-namespace-12345
Event Hub: bl-telemetry-eh-12345

=== Creating Test IoT Device ===
Device ID: test-device-5678

=== Sending Test Telemetry Messages ===
Sending message 1/5 : {"deviceId":"test-device-5678","timestamp":"2026-01-15T10:30:00Z",...}
Sending message 2/5 : {"deviceId":"test-device-5678","timestamp":"2026-01-15T10:30:02Z",...}
...

=== Verifying Data in Storage Account ===
SUCCESS: Found 2 blob(s) in storage account!
  - Blob: bl-iothub-12345/00/2026/01/15/10/30.avro
    Size: 1234 bytes
    Modified: 2026-01-15T10:31:00Z

=== Verifying Data in Event Hub ===
SUCCESS: Event Hub received 5 message(s) in the last 10 minutes!

=== Test Summary ===
Device ID: test-device-5678
Messages Sent: 5
Blobs in Storage: 2
Messages in Event Hub (last 10 min): 5

=== Test Completed ===
```

## Understanding Test Results

### Storage Account Results

**Success Indicators:**
- Blobs appear in the `telemetry` container
- Blob names follow pattern: `{hubname}/{partition}/{year}/{month}/{day}/{hour}/{minute}.avro`
- Blob sizes are > 0 bytes
- Content is in AVRO format

**Warning Indicators:**
- No blobs found (may need to wait longer)
- Empty container after 3+ minutes (check IoT Hub routes)

### Event Hub Results

**Success Indicators:**
- IncomingMessages metric shows > 0 messages
- Message count matches or exceeds sent messages
- Messages appear within 2-3 minutes

**Warning Indicators:**
- No messages detected (may need to wait longer)
- Zero metrics after 5+ minutes (check IoT Hub routes)

## Timing Considerations

### Why the 90-Second Wait?

The test waits 90 seconds because:
1. IoT Hub routes have a **60-second batch frequency** (configured in [config.tf:98](../../config.tf#L98) and [config.tf:105](../../config.tf#L105))
2. Additional time for message processing and metrics collection
3. Storage write operations may be slightly delayed

### If Data Doesn't Appear

If no data appears after the first run:
1. Wait an additional 2-3 minutes
2. Run the script again (it will query existing data)
3. Check Azure Portal for route status
4. Verify IoT Hub routes are enabled in Terraform

## Troubleshooting

### Error: IoT Extension Not Found

```powershell
az extension add --name azure-iot
```

### Error: Resource Group Not Found

Ensure Terraform resources are deployed:
```powershell
cd terraform
terraform apply
```

### Error: Insufficient Permissions

Verify your Azure account has:
- IoT Hub Data Contributor (to create devices and send messages)
- Storage Blob Data Reader (to list and read blobs)
- Reader role (to query metrics)

### Warning: No Blobs Found

**Possible causes:**
1. **Too early** - Wait 2-3 minutes total and check again
2. **Route disabled** - Check IoT Hub route configuration
3. **Storage connection issue** - Verify storage account connection string in IoT Hub endpoint
4. **Incorrect container** - Verify container name is `telemetry`

### Warning: No Event Hub Messages

**Possible causes:**
1. **Too early** - Wait up to 5 minutes for metrics to populate
2. **Route disabled** - Check IoT Hub route configuration
3. **Authorization issue** - Verify Event Hub authorization rule has send/listen permissions
4. **Connection issue** - Check Event Hub connection string in IoT Hub endpoint

### Script Fails at Device Creation

**Possible causes:**
1. **Not logged in** - Run `az login`
2. **Wrong subscription** - Run `az account set --subscription <subscription-id>`
3. **Permissions** - Ensure you have IoT Hub Contributor or higher

## Cost Considerations

### Resources Created by Test
- 1 temporary IoT device (deleted at end)
- 5 telemetry messages (~1 KB total)
- Storage blobs (~1-2 KB)

### Estimated Cost per Test Run
- **Storage**: < $0.01 (negligible for small test data)
- **Event Hub**: Included in Basic SKU (already running)
- **IoT Hub**: 5 messages (< 0.01% of daily quota on S1 SKU)

**Total per run: < $0.01**

## Integration with CI/CD

These integration tests can be run in automated pipelines after Terraform deployment:

### GitHub Actions Example

```yaml
name: Integration Tests

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy Terraform
        run: |
          cd terraform
          terraform init
          terraform apply -auto-approve

      - name: Run Integration Tests
        run: |
          .\terraform\tests\integration\test-data-flow.ps1

      - name: Cleanup (Optional)
        if: always()
        run: |
          cd terraform
          terraform destroy -auto-approve
```

### Azure DevOps Example

```yaml
- task: AzureCLI@2
  displayName: 'Run Integration Tests'
  inputs:
    azureSubscription: 'Azure-Subscription'
    scriptType: 'pscore'
    scriptLocation: 'scriptPath'
    scriptPath: 'terraform/tests/integration/test-data-flow.ps1'
```

## Test Data Format

### Sample Message Structure

```json
{
  "deviceId": "test-device-1234",
  "timestamp": "2026-01-15T10:30:00.0000000Z",
  "temperature": 25.3,
  "humidity": 52.7,
  "messageNumber": 1
}
```

### Storage Output Format

Data is stored in AVRO format in the storage container with the following structure:
```
telemetry/
  bl-iothub-12345/
    00/  (partition 0)
      2026/
        01/
          15/
            10/
              30.avro
    01/  (partition 1)
      ...
```

## Comparison with Unit Tests

| Aspect | Unit Tests | Integration Tests |
|--------|-----------|------------------|
| **Speed** | Seconds | Minutes (90+ seconds) |
| **Cost** | Free | Minimal (< $0.01) |
| **Scope** | Configuration validation | End-to-end data flow |
| **Azure Resources** | None created | Uses deployed resources |
| **When to Run** | Before deployment | After deployment |
| **Detects** | Config errors | Runtime/connectivity issues |

## Best Practices

1. **Run unit tests first** - Catch configuration errors before deploying
2. **Deploy once, test multiple times** - No need to destroy between test runs
3. **Monitor costs** - Integration tests create minimal data but watch for runaway resources
4. **Clean up devices** - The script auto-deletes test devices, but verify in portal
5. **Check timestamps** - Ensure test data is recent to verify active routing
6. **Save outputs** - Redirect output to file for audit trails: `.\test-data-flow.ps1 > results.txt`

## Related Documentation

- **Unit Tests**: [../unit/README.md](../unit/README.md)
- **Terraform Configuration**: [../../config.tf](../../config.tf)
- **Main Test Script**: [../../../test-terraform.ps1](../../../test-terraform.ps1)

## Next Steps

After integration tests pass:
1. **Verify in Portal** - Check Azure Portal for data in Storage and Event Hub
2. **Test with Real Devices** - Connect actual IoT Edge devices
3. **Monitor Metrics** - Set up Azure Monitor alerts
4. **Scale Testing** - Test with more messages and devices
5. **Performance Testing** - Measure throughput and latency
