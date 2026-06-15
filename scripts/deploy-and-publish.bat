@echo off
setlocal

REM === Configure these for your project ===
set ORG_ALIAS=PlayGround
set SITE_NAME=application

echo === Publishing Experience Cloud site: %SITE_NAME% ===
call sf community publish --name "%SITE_NAME%" --target-org %ORG_ALIAS%
if errorlevel 1 goto :fail

echo === Done ===
exit /b 0

:fail
echo Publish failed.
exit /b 1
