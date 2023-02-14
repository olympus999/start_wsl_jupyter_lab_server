# start_wsl_jupyter_lab_server
Starts Jupyter Lab in WSL and forwards ports so the server can be accessed by others

One option to automatically run the .bat file after every reboot is to use "Task Scheduler"

Some important notes before blindly running the script and helping to debug:
* default port is set to 8888
* App "Windows Terminal" (WT) is needed - I find WT makes working with Ubuntu easier.
* Profile used by the script is named "Ubuntu 22.04.1 LTS" in WT.