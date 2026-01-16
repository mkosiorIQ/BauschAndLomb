# Run the Telemetry Dashboard (Backend + Frontend)

# Ensure we're in the right directory
$dashboardPath = "C:\Projects\Bench\Azure\IotEdge\BauschAndLomb\telemetry-dashboard"

# Install frontend dependencies if not already done
Write-Host "Installing frontend dependencies..." -ForegroundColor Cyan
Push-Location "$dashboardPath\frontend"
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "npm install failed. Check for errors above." -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

# Start the backend in a new terminal window
Write-Host "Starting backend (ASP.NET Core on http://localhost:5000)..." -ForegroundColor Green
Push-Location "$dashboardPath\backend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "dotnet run"
Pop-Location

# Wait a few seconds for backend to start
Start-Sleep -Seconds 3

# Start the frontend in a new terminal window
Write-Host "Starting frontend (React on http://localhost:3000)..." -ForegroundColor Green
Push-Location "$dashboardPath\frontend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "npm start"
Pop-Location

Write-Host "Dashboard is starting..." -ForegroundColor Yellow
Write-Host "Backend: http://localhost:5000" -ForegroundColor Yellow
Write-Host "Frontend: http://localhost:3000" -ForegroundColor Yellow
Write-Host "Open http://localhost:3000 in your browser to see the app." -ForegroundColor Yellow
