# Test script to send telemetry data to IoT Hub and verify it's received in Storage and Event Hub
# This script assumes the Terraform resources are already deployed
# Prerequisites:
# - Azure CLI installed and logged in
# - Az PowerShell module installed (Install-Module -Name Az -AllowClobber -Scope CurrentUser)
# - Run 'Connect-AzAccount' if not already connected

# Set the Azure subscription
$subscriptionId = "046696af-1d89-4ff1-9ab1-411f666c1c06"
az account set --subscription $subscriptionId

# Get the script directory and navigate to terraform root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$terraformRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)
Push-Location $terraformRoot

Write-Host "=== Retrieving Terraform Outputs ===" -ForegroundColor Cyan
Write-Host "Working directory: $(Get-Location)" -ForegroundColor Gray

# Get resource names from Terraform state
# Since there's no output defined, use the hardcoded resource group name from config.tf
$resourceGroupName = "bl-monitoring-rg1"

# Get IoT Hub name
$iotHubName = az iot hub list --resource-group $resourceGroupName --query "[0].name" -o tsv
Write-Host "IoT Hub: $iotHubName" -ForegroundColor Green

# Get Storage Account name
$storageAccountName = az storage account list --resource-group $resourceGroupName --query "[0].name" -o tsv
Write-Host "Storage Account: $storageAccountName" -ForegroundColor Green

# Get Event Hub namespace and name
$eventHubNamespace = az eventhubs namespace list --resource-group $resourceGroupName --query "[0].name" -o tsv
$eventHubName = az eventhubs eventhub list --resource-group $resourceGroupName --namespace-name $eventHubNamespace --query "[0].name" -o tsv
Write-Host "Event Hub Namespace: $eventHubNamespace" -ForegroundColor Green
Write-Host "Event Hub: $eventHubName" -ForegroundColor Green

# Create a test IoT device
$deviceId = "test-device-$(Get-Random -Minimum 1000 -Maximum 9999)"
Write-Host "`n=== Creating Test IoT Device ===" -ForegroundColor Cyan
Write-Host "Device ID: $deviceId" -ForegroundColor Green

az iot hub device-identity create --device-id $deviceId --hub-name $iotHubName --resource-group $resourceGroupName

# Get the device connection string
$deviceConnectionString = az iot hub device-identity connection-string show --device-id $deviceId --hub-name $iotHubName --resource-group $resourceGroupName --query "connectionString" -o tsv

# Send test telemetry messages
Write-Host "`n=== Sending Test Telemetry Messages ===" -ForegroundColor Cyan
$messageCount = 5

for ($i = 1; $i -le $messageCount; $i++) {
    $timestamp = (Get-Date).ToString("o")
    $temperature = Get-Random -Minimum 20 -Maximum 30
    $humidity = Get-Random -Minimum 40 -Maximum 60

    $messageBody = @{
        deviceId = $deviceId
        timestamp = $timestamp
        temperature = $temperature
        humidity = $humidity
        messageNumber = $i
    } | ConvertTo-Json -Compress

    Write-Host "Sending message $i/$messageCount : $messageBody" -ForegroundColor Yellow

    az iot device send-d2c-message --device-id $deviceId --hub-name $iotHubName --data $messageBody --resource-group $resourceGroupName

    Start-Sleep -Seconds 2
}

Write-Host "`nAll messages sent. Waiting for messages to be processed..." -ForegroundColor Cyan
Write-Host "Note: IoT Hub routes have a batch frequency of 60 seconds, so data may take up to 2 minutes to appear." -ForegroundColor Yellow
Start-Sleep -Seconds 90

# Verify data in Storage Account
Write-Host "`n=== Verifying Data in Storage Account ===" -ForegroundColor Cyan

# Get storage account key
$storageKey = az storage account keys list --resource-group $resourceGroupName --account-name $storageAccountName --query "[0].value" -o tsv

# List blobs in the telemetry container
$containerName = "telemetry"
Write-Host "Checking container: $containerName" -ForegroundColor Green

$blobs = az storage blob list --account-name $storageAccountName --account-key $storageKey --container-name $containerName --query "[].{name:name, size:properties.contentLength, modified:properties.lastModified}" -o json | ConvertFrom-Json

if ($blobs.Count -gt 0) {
    Write-Host "SUCCESS: Found $($blobs.Count) blob(s) in storage account!" -ForegroundColor Green

    # Display blob details
    foreach ($blob in $blobs) {
        Write-Host "  - Blob: $($blob.name)" -ForegroundColor White
        Write-Host "    Size: $($blob.size) bytes" -ForegroundColor Gray
        Write-Host "    Modified: $($blob.modified)" -ForegroundColor Gray
    }

    # Download and display the first blob content
    if ($blobs.Count -gt 0) {
        $firstBlob = $blobs[0].name
        $tempFile = [System.IO.Path]::GetTempFileName()

        Write-Host "`nDownloading first blob to view contents..." -ForegroundColor Cyan
        az storage blob download --account-name $storageAccountName --account-key $storageKey --container-name $containerName --name $firstBlob --file $tempFile --no-progress 2>$null

        if (Test-Path $tempFile) {
            Write-Host "Sample blob content:" -ForegroundColor Yellow
            Get-Content $tempFile -Raw | Write-Host -ForegroundColor White
            Remove-Item $tempFile -Force
        }
    }
} else {
    Write-Host "WARNING: No blobs found in storage account yet." -ForegroundColor Red
    Write-Host "This could mean the data hasn't been written yet (batch frequency is 60s)" -ForegroundColor Yellow
}

# Verify data in Event Hub
Write-Host "`n=== Verifying Data in Event Hub ===" -ForegroundColor Cyan

# Get Event Hub connection string
$authRuleName = az eventhubs eventhub authorization-rule list --resource-group $resourceGroupName --namespace-name $eventHubNamespace --eventhub-name $eventHubName --query "[0].name" -o tsv
$eventHubConnectionString = az eventhubs eventhub authorization-rule keys list --resource-group $resourceGroupName --namespace-name $eventHubNamespace --eventhub-name $eventHubName --name $authRuleName --query "primaryConnectionString" -o tsv

Write-Host "Event Hub connection string retrieved" -ForegroundColor Green

# Check Event Hub metrics
Write-Host "`nChecking Event Hub metrics for incoming messages..." -ForegroundColor Cyan

# Get the namespace resource ID (not the individual event hub)
$namespaceResourceId = az eventhubs namespace show --resource-group $resourceGroupName --name $eventHubNamespace --query "id" -o tsv

# Get metrics for the last 10 minutes
$endTime = Get-Date
$startTime = $endTime.AddMinutes(-10)

$metrics = az monitor metrics list --resource $namespaceResourceId --metric "IncomingMessages" --start-time $startTime.ToString("o") --end-time $endTime.ToString("o") --interval PT1M --query "value[0].timeseries[0].data" -o json | ConvertFrom-Json

$totalMessages = ($metrics | Measure-Object -Property total -Sum).Sum

if ($totalMessages -gt 0) {
    Write-Host "SUCCESS: Event Hub received $totalMessages message(s) in the last 10 minutes!" -ForegroundColor Green

    # Display metrics details
    Write-Host "`nMessage details by minute:" -ForegroundColor Yellow
    foreach ($dataPoint in $metrics | Where-Object { $_.total -gt 0 }) {
        Write-Host "  - Time: $($dataPoint.timeStamp) | Messages: $($dataPoint.total)" -ForegroundColor White
    }
} else {
    Write-Host "WARNING: No messages detected in Event Hub yet." -ForegroundColor Red
    Write-Host "This could mean the data hasn't been routed yet (batch frequency is 60s)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Device ID: $deviceId" -ForegroundColor White
Write-Host "Messages Sent: $messageCount" -ForegroundColor White
Write-Host "Blobs in Storage: $($blobs.Count)" -ForegroundColor White
Write-Host "Messages in Event Hub (last 10 min): $totalMessages" -ForegroundColor White

# Cleanup test device
Write-Host "`n=== Cleaning Up Test Device ===" -ForegroundColor Cyan
az iot hub device-identity delete --device-id $deviceId --hub-name $iotHubName --resource-group $resourceGroupName
Write-Host "Test device deleted" -ForegroundColor Green

Write-Host "`n=== Test Completed ===" -ForegroundColor Green
Write-Host "Note: If no data was found, try running this script again after waiting 2-3 minutes." -ForegroundColor Yellow

# Return to original directory
Pop-Location
