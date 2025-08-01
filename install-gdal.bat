@echo off
setlocal enabledelayedexpansion

echo Installing GDAL via Pixi for Windows
echo ===================================
echo.

:: Check if Pixi is installed
where pixi >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Pixi is not installed
    echo Please install Pixi first:
    echo   irm https://pixi.sh/install.ps1 ^| iex
    exit /b 1
)

:: Check if GDAL is already installed
where gdalinfo >nul 2>&1
if %errorlevel% equ 0 (
    echo GDAL is already installed
    gdalinfo --version
) else (
    echo Installing GDAL via Pixi...
    pixi global install gdal=3.10.3
)

:: Get Pixi environment paths
set PIXI_GLOBAL_ROOT=%USERPROFILE%\.pixi\envs\gdal
set PIXI_GLOBAL_BIN=%USERPROFILE%\.pixi\envs\gdal\Library\bin

:: Create bundled library directories
echo Setting up bundled library directories...

:: Create Windows libraries directory for bundling
if not exist "src-tauri\gdal-libs\windows" mkdir "src-tauri\gdal-libs\windows"

:: Copy Windows GDAL libraries for bundling
echo Copying Windows GDAL libraries for bundling...

:: Copy main GDAL library
if exist "%PIXI_GLOBAL_ROOT%\Library\lib\gdal.lib" (
    copy "%PIXI_GLOBAL_ROOT%\Library\lib\gdal.lib" "src-tauri\gdal-libs\windows\"
    echo Copied gdal.lib
    :: Also create gdal_i.lib if it doesn't exist (for gdal-sys compatibility)
    if not exist "%PIXI_GLOBAL_ROOT%\Library\lib\gdal_i.lib" (
        copy "%PIXI_GLOBAL_ROOT%\Library\lib\gdal.lib" "%PIXI_GLOBAL_ROOT%\Library\lib\gdal_i.lib"
        echo Created gdal_i.lib for compatibility
    )
) else (
    echo Warning: gdal.lib not found at %PIXI_GLOBAL_ROOT%\Library\lib\gdal.lib
)

:: Copy all GDAL-related DLL files
if exist "%PIXI_GLOBAL_ROOT%\Library\bin" (
    copy "%PIXI_GLOBAL_ROOT%\Library\bin\*.dll" "src-tauri\gdal-libs\windows\" 2>nul
    echo Copied all DLL files
)

:: Copy all GDAL-related LIB files
if exist "%PIXI_GLOBAL_ROOT%\Library\lib" (
    copy "%PIXI_GLOBAL_ROOT%\Library\lib\*.lib" "src-tauri\gdal-libs\windows\" 2>nul
    echo Copied all LIB files
)

:: Copy include files
if exist "%PIXI_GLOBAL_ROOT%\Library\include" (
    xcopy "%PIXI_GLOBAL_ROOT%\Library\include" "src-tauri\gdal-libs\windows\include\" /E /I /Y 2>nul
    echo Copied include files
)

:: Copy share files (GDAL data, PROJ data)
if exist "%PIXI_GLOBAL_ROOT%\Library\share" (
    xcopy "%PIXI_GLOBAL_ROOT%\Library\share" "src-tauri\gdal-libs\windows\share\" /E /I /Y 2>nul
    echo Copied share files
)

:: Create .env file for the project
echo Creating .env file for project...
(
echo # GDAL Environment Variables for Tauri
echo GDAL_ROOT=%PIXI_GLOBAL_ROOT%
echo GDAL_HOME=%PIXI_GLOBAL_ROOT%
echo GDAL_LIB_DIR=%PIXI_GLOBAL_ROOT%\Library\lib
echo GDAL_INCLUDE_DIR=%PIXI_GLOBAL_ROOT%\Library\include
echo GDAL_BIN_DIR=%PIXI_GLOBAL_BIN%
echo GDAL_NO_PKG_CONFIG=1
echo GDAL_DYNAMIC=1
echo GDAL_STATIC=0
echo GDAL_VERSION=3.10.3
echo PKG_CONFIG=
echo PKG_CONFIG_PATH=
) > .env

echo Created .env file for project

:: Verify installation
echo.
echo Verifying installation...

:: First, try to find gdalinfo in PATH
where gdalinfo >nul 2>&1
if %errorlevel% equ 0 (
    echo GDAL is available in PATH:
    gdalinfo --version
    goto :verification_success
)

:: If not in PATH, try to find it in Pixi environment
if exist "%PIXI_GLOBAL_BIN%\gdalinfo.exe" (
    echo GDAL is available in Pixi environment:
    "%PIXI_GLOBAL_BIN%\gdalinfo.exe" --version
    goto :verification_success
)

:: If still not found, try to load environment variables from .env file
if exist ".env" (
    echo Loading environment variables from .env file...
    for /f "tokens=1,2 delims==" %%a in (.env) do (
        if not "%%a"=="" (
            if not "%%a:~0,1%"=="#" (
                set "%%a=%%b"
            )
        )
    )
    
    :: Check again after loading environment variables
    where gdalinfo >nul 2>&1
    if %errorlevel% equ 0 (
        echo GDAL is available after loading .env:
        gdalinfo --version
        goto :verification_success
    )
)

:: If all checks fail, show debugging info
echo Error: GDAL installation verification failed
echo Current PATH: %PATH%
exit /b 1

:verification_success

:: Show what was copied
echo.
echo Windows GDAL libraries copied to src-tauri\gdal-libs\windows\
echo Found GDAL libraries and dependencies for bundling

echo.
echo GDAL installation complete for Windows!
echo Libraries are now bundled with your Tauri application
echo Next steps:
echo   1. Build for Windows: pnpm tauri build
echo   2. The bundled libraries will be included in your app

endlocal

 