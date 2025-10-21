@echo off
echo ============================================================
echo   Firebase Data Export Tool
echo ============================================================
echo.

REM Check if virtual environment exists
if exist venv\Scripts\activate.bat (
    echo Activating virtual environment...
    call venv\Scripts\activate.bat
) else (
    echo Warning: No virtual environment found. Using global Python.
)

echo.
echo Running export script...
echo.

python export_data.py

echo.
echo ============================================================
echo   Press any key to exit...
echo ============================================================
pause > nul

