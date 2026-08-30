@echo off
title Git Auto Sync

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0auto-git-sync.ps1"

pause