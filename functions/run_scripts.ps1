Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Firestore Data Management Scripts" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Change to script directory
Set-Location $PSScriptRoot

Write-Host "Activating virtual environment..." -ForegroundColor Yellow
& ".\venv\Scripts\Activate.ps1"

Write-Host ""
Write-Host "Choose an option:" -ForegroundColor Green
Write-Host "1. Export data via API" -ForegroundColor White
Write-Host "2. Exit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice (1-2)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "Exporting data via API..." -ForegroundColor Yellow
        python scripts\export_via_api.py
    }
    "2" {
        Write-Host "Goodbye!" -ForegroundColor Green
        exit 0
    }
    default {
        Write-Host "Invalid choice!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host ""
Write-Host "Script completed!" -ForegroundColor Green
Read-Host "Press Enter to exit"
