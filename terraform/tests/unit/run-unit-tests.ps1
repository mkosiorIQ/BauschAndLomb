# PowerShell script to run Terraform unit tests
# This script runs the Terraform test framework to validate the configuration
# Prerequisites:
# - Terraform 1.6.0 or later installed
# - Azure CLI installed and logged in (run 'az login' if not already done)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "=== Terraform Unit Tests ===" -ForegroundColor Cyan
Write-Host "Running unit tests for IoT Edge monitoring infrastructure" -ForegroundColor White
Write-Host ""

# Get the script directory and navigate to terraform root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$terraformRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)

Write-Host "Terraform root directory: $terraformRoot" -ForegroundColor Gray
Push-Location $terraformRoot

try {
    # Check Terraform version
    Write-Host ""
    Write-Host "=== Checking Terraform Version ===" -ForegroundColor Cyan
    $terraformVersion = terraform version -json | ConvertFrom-Json
    $version = $terraformVersion.terraform_version
    Write-Host "Terraform version: $version" -ForegroundColor Green

    # Parse version to check if it's 1.6.0 or later
    $versionParts = $version -split '\.'
    $majorVersion = [int]$versionParts[0]
    $minorVersion = [int]$versionParts[1]

    if ($majorVersion -lt 1 -or ($majorVersion -eq 1 -and $minorVersion -lt 6)) {
        Write-Host "WARNING: Terraform 1.6.0 or later is required for the test framework" -ForegroundColor Yellow
        Write-Host "Current version: $version" -ForegroundColor Yellow
        Write-Host "Please upgrade Terraform to run unit tests" -ForegroundColor Yellow
        exit 1
    }

    # Initialize Terraform if needed
    if (-not (Test-Path ".terraform")) {
        Write-Host ""
        Write-Host "=== Initializing Terraform ===" -ForegroundColor Cyan
        terraform init
        if ($LASTEXITCODE -ne 0) {
            throw "Terraform init failed"
        }
    } else {
        Write-Host ""
        Write-Host "Terraform already initialized" -ForegroundColor Gray
    }

    # Run Terraform tests
    Write-Host ""
    Write-Host "=== Running Terraform Unit Tests ===" -ForegroundColor Cyan
    Write-Host "Test file: tests/unit/main.tftest.hcl" -ForegroundColor Gray
    Write-Host ""

    terraform test -filter=tests/unit/main.tftest.hcl

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "=== All Unit Tests Passed ===" -ForegroundColor Green
        Write-Host "All assertions validated successfully" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "=== Unit Tests Failed ===" -ForegroundColor Red
        Write-Host "One or more assertions failed" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "Test execution completed" -ForegroundColor Cyan

} catch {
    Write-Host ""
    Write-Host "=== Error Running Tests ===" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
