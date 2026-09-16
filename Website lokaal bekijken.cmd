@echo off
rem Dubbelklik op dit bestand om de website lokaal te bekijken, precies zoals
rem hij live werkt. Er opent een venster (de testserver) en je browser toont
rem http://localhost:8080/ . Sluit het venster om de testserver te stoppen.
title Villa Sol y Viento - lokale testserver
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\serve.ps1" -Open
if errorlevel 1 pause
