@echo off

:: Check if port is open
SET port_jupyter=8888
SET port_SSH=2222
SET port_postgresql=5432
SET port_backend=5000
SET port_frontend=8080
SET port_superset=8088
SET port_pulsar=8088

:: Check if running as Administrative
:check_Permissions
    
    net session >nul 2>&1
    if NOT %errorLevel% == 0 (
        echo Failure: Current permissions inadequate. Set "Run as Administrative"
		pause
		exit
    )

:: This solves the problem when the JupyterLab is restarted as it takes a bit of time to release the ports by 'portproxy' for reusing by WSL. 
:: This can take few minutes
:: ´netsh interface portproxy show all´ - Command useful for showing currently active proxies:
netsh interface portproxy reset

:: Restart the "IP Helper Service" and make sure it is running - restarting fixes bugs that happen sometimes.
net stop iphlpsvc & net start iphlpsvc

:start
netstat -o -n -a | findstr %port_jupyter%
if %ERRORLEVEL% equ 0 (
	echo Port %port_jupyter% already open
	timeout 10
	GOTO:start
)

:: Local IP
for /f "delims=[] tokens=2" %%a in ('ping -4 -n 1 %ComputerName% ^| findstr [') do set NetworkIP=%%a

:: WSL Local IP
for /f "usebackq tokens=2 delims= " %%i in (`wsl ip a ^| findstr eth0 ^| findstr 172`) do set ip_with_subnet=%%i
for /f "tokens=1 delims=/" %%a in ("%ip_with_subnet%") do set WSLNetworkIP=%%a

:: Start jupyter-lab. In my case "Ubuntu 22.04.2 LTS" is the name of profile in the Windows Terminal.

wt.exe new-tab -p "Ubuntu 22.04.2 LTS" -- bash -i -l -c "cd /mnt/e/data/ && jupyter-lab && bash"
:: wt.exe new-tab -p "Ubuntu 22.04.2 LTS" -- bash -i -l -c "mamba activate xeus-python & jupyter-lab && bash"

:: Setup proxy from Windows to WSL for JupyterLab
CALL :ProxyForward %port_jupyter%

:: Setup proxy from Windows to WSL for SSH
CALL :ProxyForward %port_SSH%

:: Setup proxy from Windows to WSL for PostgreSQL
CALL :ProxyForward %port_postgresql%

CALL :ProxyForward %port_backend%

CALL :ProxyForward %port_frontend%

:: CALL :ProxyForward %port_superset%

CALL :ProxyForward %port_pulsar%

timeout 60
  
:: Setup proxy from Windows to WSL	
:ProxyForward
set c=netsh interface portproxy add v4tov4 listenport=%~1 listenaddress=0.0.0.0 connectport=%~1 connectaddress=127.0.0.1 ^
   && netsh interface portproxy add v4tov4 listenport=%~1 listenaddress=%WSLNetworkIP% connectport=%~1 connectaddress=127.0.0.1 ^
   && netsh interface portproxy add v4tov4 listenport=%~1 listenaddress=%NetworkIP% connectport=%~1 connectaddress=%WSLNetworkIP%
echo %c%
%c%
Exit /B