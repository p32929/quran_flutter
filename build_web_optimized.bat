@echo off
echo Building optimized Flutter web app...
echo.

REM Clean previous build
echo Cleaning previous build...
flutter clean

REM Get dependencies
echo Getting dependencies...
flutter pub get

REM Build for web with basic optimizations
echo Building web app with optimizations...
flutter build web --release --web-renderer canvaskit

REM Check if build was successful
if %errorlevel% == 0 (
    echo.
    echo ========================================
    echo Build completed successfully!
    echo ========================================
    echo.
    echo Your optimized web app is in: build\web\
    echo.
    echo To test locally, run:
    echo python -m http.server 8000 --directory build\web
    echo.
    echo Then open: http://localhost:8000
    echo.
) else (
    echo.
    echo ========================================
    echo Build failed! Check the errors above.
    echo ========================================
)

pause 