@echo off

rem Set md resource name
set MDNAME=<md resource name>

rem Execute Mirror Recovery
clplogcmd -m "SM Info: Start mirroring"
clpmdctrl -r %MDNAME%
exit /B %ERRORLEVEL%
