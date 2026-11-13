@echo off
setlocal
cd /d "%~dp0"

REM ---- Settings ----
set TAR_FILE=chumputer_bundle.tar
set IMAGE=chumputer:latest
set CONTAINER_NAME=chumputer
set HOST_PORT=5000
set APP_PORT=5000
set MODELS_DIR=%~dp0opt\chumputer
set MODELS_MOUNT=/opt/chumputer
set LOGS_DIR=%~dp0logs
set STAMP_FILE=%~dp0.loaded_stamp
set MAX_WAIT_SECONDS=420

REM ---- Checks ----
docker info >nul 2>&1
if errorlevel 1 (
    echo Docker isn't running. Start Docker Desktop, wait until it says it is running, then try again.
    pause
    exit /b 1
)

if not exist "%TAR_FILE%" (
    echo Can't find %TAR_FILE% next to this script.
    pause
    exit /b 1
)

if not exist "%MODELS_DIR%" (
    echo Can't find the opt\chumputer models folder next to this script.
    pause
    exit /b 1
)

set MISSING=
for %%F in (mask_weights.pth target_feats.pth weights.pth sam_vit_h_4b8939.pth) do (
    if not exist "%MODELS_DIR%\Scalevision\crop_vision\%%F" (
        echo Missing model file: opt\chumputer\Scalevision\crop_vision\%%F
        set MISSING=1
    )
)
if defined MISSING (
    pause
    exit /b 1
)

REM ---- Load the image only if it is new or has changed ----
for %%F in ("%TAR_FILE%") do set "TAR_STAMP=%%~tF %%~zF"
set "SAVED_STAMP="
if exist "%STAMP_FILE%" set /p SAVED_STAMP=<"%STAMP_FILE%"

set NEED_LOAD=
docker image inspect %IMAGE% >nul 2>&1
if errorlevel 1 set NEED_LOAD=1
if not "%SAVED_STAMP%"=="%TAR_STAMP%" set NEED_LOAD=1

if defined NEED_LOAD (
    echo Loading image from %TAR_FILE% - this can take several minutes the first time...
    docker load -i "%TAR_FILE%"
    if errorlevel 1 (
        echo Image load failed.
        pause
        exit /b 1
    )
    >"%STAMP_FILE%" echo %TAR_STAMP%
)

docker image inspect %IMAGE% >nul 2>&1
if errorlevel 1 (
    echo Image %IMAGE% was not found after loading. Run "docker images" to see what was loaded.
    pause
    exit /b 1
)

REM ---- GPU or CPU ----
set GPU_FLAG=
nvidia-smi >nul 2>&1
if not errorlevel 1 set GPU_FLAG=--gpus all
if defined GPU_FLAG (
    echo NVIDIA GPU detected - starting with GPU support.
) else (
    echo No NVIDIA GPU detected - starting in CPU mode. Processing will be slow.
)

if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"

REM ---- Start the container (retry on CPU if the GPU start fails) ----
call :start_container
if errorlevel 1 if defined GPU_FLAG (
    echo GPU start failed - retrying in CPU mode...
    set "GPU_FLAG="
    call :start_container
)
if errorlevel 1 (
    echo Container failed to start. Is port %HOST_PORT% already in use?
    pause
    exit /b 1
)

REM ---- Wait until the app answers ----
echo Waiting for Chumputer to finish loading models. The first start can take a few minutes...

where curl >nul 2>&1
if errorlevel 1 (
    echo curl was not found, so waiting 90 seconds instead of checking.
    timeout /t 90 /nobreak >nul
    goto ready
)

set /a WAITED=0
:wait_loop
curl -s -o nul http://127.0.0.1:%HOST_PORT%/upload_approve
if not errorlevel 1 goto ready
docker ps -q -f "name=%CONTAINER_NAME%" -f status=running | findstr . >nul
if errorlevel 1 goto crashed
if %WAITED% GEQ %MAX_WAIT_SECONDS% goto timed_out
timeout /t 3 /nobreak >nul
set /a WAITED+=3
goto wait_loop

:ready
docker logs %CONTAINER_NAME% 2>&1 | findstr /c:"Failed to load models" >nul
if not errorlevel 1 (
    docker logs %CONTAINER_NAME% > "%LOGS_DIR%\container_startup.log" 2>&1
    echo.
    echo WARNING: The app started but the models failed to load.
    echo Details were saved to logs\container_startup.log
    pause
    exit /b 1
)
echo.
echo Chumputer is ready at http://localhost:%HOST_PORT%
echo To stop it: docker stop %CONTAINER_NAME%
start http://localhost:%HOST_PORT%
pause
exit /b 0

:crashed
docker logs %CONTAINER_NAME% > "%LOGS_DIR%\container_startup.log" 2>&1
echo.
echo The container stopped unexpectedly. Its log was saved to logs\container_startup.log
echo Last lines:
docker logs --tail 20 %CONTAINER_NAME%
pause
exit /b 1

:timed_out
docker logs %CONTAINER_NAME% > "%LOGS_DIR%\container_startup.log" 2>&1
echo.
echo Timed out waiting for the app. Its log was saved to logs\container_startup.log
pause
exit /b 1

:start_container
docker rm -f %CONTAINER_NAME% >nul 2>&1
docker run -d --name %CONTAINER_NAME% %GPU_FLAG% ^
  -p 127.0.0.1:%HOST_PORT%:%APP_PORT% ^
  -v "%MODELS_DIR%:%MODELS_MOUNT%" ^
  -v "%LOGS_DIR%:/app/chumputer_logs" ^
  %IMAGE% >nul
exit /b %errorlevel%
