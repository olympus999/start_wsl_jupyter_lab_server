@echo off

:: Check if running as Administrative
:check_Permissions
    
    net session >nul 2>&1
    if NOT %errorLevel% == 0 (
        echo Failure: Current permissions inadequate. Set "Run as Administrative"
		pause
		exit
    )

:: Need to remove any assocations made to port by 'portproxy'. Otherwise Jupyter Notebook will not run on specific port
:: ´netsh interface portproxy show all´ - Command useful for showing currently active proxies:
netsh interface portproxy reset

:: Restart the IP Helper Service - fixes bugs that happen sometimes
net stop iphlpsvc && net start iphlpsvc

:: Check if port is open
SET port=8888

:start
netstat -o -n -a | findstr %port%
if %ERRORLEVEL% equ 0 (
	echo Port %port% already open
	timeout 10
	GOTO:start
)

:: Local IP
for /f "delims=[] tokens=2" %%a in ('ping -4 -n 1 %ComputerName% ^| findstr [') do set NetworkIP=%%a

:: WSL Local IP
for /f "usebackq tokens=2 delims= " %%i in (`wsl ip a ^| findstr eth0 ^| findstr 172`) do set ip_with_subnet=%%i
for /f "tokens=1 delims=/" %%a in ("%ip_with_subnet%") do set WSLNetworkIP=%%a

:: Start jupyter-lab
:: wsl.exe bash -c "source ~/.bashrc; /home/anti/miniconda3/envs/main/bin/jupyter-lab"
:: set c=runas /user:ANTI /savecred "wt.exe new-tab -p \"Ubuntu 22.04.1 LTS\" -- bash -i -l -c \"jupyter-lab && bash\""
:: echo(c)
:: %c%

wt.exe new-tab -p "Ubuntu 22.04.1 LTS" -- bash -i -l -c "jupyter-lab && bash"

:: Setup proxy from Windows to WSL
set c=netsh interface portproxy add v4tov4 listenport=%port% listenaddress=0.0.0.0 connectport=%port% connectaddress=127.0.0.1 ^
   && netsh interface portproxy add v4tov4 listenport=%port% listenaddress=%WSLNetworkIP% connectport=%port% connectaddress=127.0.0.1 ^
   && netsh interface portproxy add v4tov4 listenport=%port% listenaddress=%NetworkIP% connectport=%port% connectaddress=%WSLNetworkIP%

echo %c%
%c%

timeout 60