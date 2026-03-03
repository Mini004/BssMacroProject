@echo off
cd /d "C:\Users\Najalt\Vs-code\BssMacroProject\BSSRelay"
start "BSS Server" node server.js
timeout /t 2
start "BSS Bridge" node bridge.js