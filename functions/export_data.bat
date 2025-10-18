@echo off
echo ========================================
echo Firestore Data Export (API Method)
echo ========================================
echo.

cd /d "%~dp0"

echo Activating virtual environment...
call venv\Scripts\activate.bat

echo.
echo Exporting data via API...
python scripts\export_via_api.py

echo.
echo Export completed!
pause
