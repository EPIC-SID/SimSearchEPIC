@echo off
cd /d "%~dp0..\app"
echo Starting SimSearch API on http://127.0.0.1:8000
python api.py
