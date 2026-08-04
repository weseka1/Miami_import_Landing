@echo off
title MIAMI_IMPORT - Stock Manager
echo.
echo ============================================
echo  MIAMI_IMPORT - Stock Manager
echo ============================================
echo.
echo Verificando dependencias...
python -m pip install -q -r requirements.txt
echo.
echo Iniciando servidor...
echo Abri http://localhost:8000 en el navegador.
echo (Esta ventana tiene que quedar abierta mientras uses la app)
echo.
start "" http://localhost:8000
python app.py
pause
