param([string]$Path = ".env")

if (-not (Test-Path $Path)) {
    Write-Error "Error: .env file not found at $Path"
    exit 1
}

# Read the file content, filtering out comments and empty lines
$content = Get-Content -Path $Path | Where-Object { $_ -match '^\s*[^#\s]+=' }

foreach ($line in $content) {
    # Split the line at the first '=' sign only
    $keyVal = $line -split '=', 2
    $key = $keyVal[0].Trim()
    $val = $keyVal[1].Trim(@(' ', "'", '"'))

    # Set the environment variable for the current process
    [Environment]::SetEnvironmentVariable($key, $val, "Process")
    Write-Host "Set environment variable: $key"
}
