@echo off
setlocal EnableDelayedExpansion
chcp 65001 > nul

:: Проверка аргументов для админских операций
if "%~1"=="admin" (
    if "%~2"=="install" goto INSTALL_ADMIN
    if "%~2"=="remove" goto REMOVE_ADMIN
    if "%~2"=="status" goto STATUS_ADMIN
)

:: Главное меню
:MAIN_MENU
cls
echo.
echo  ==============================
echo     ZAPRET SERVICE MANAGER
echo  ==============================
echo  1. Установить сервис
echo  2. Удалить сервис
echo  3. Проверить статус
echo  4. Выход
echo  ==============================
echo.
choice /C 1234 /M "Выберите действие: "

if errorlevel 4 exit /b
if errorlevel 3 goto STATUS
if errorlevel 2 goto REMOVE
if errorlevel 1 goto INSTALL

:INSTALL
echo Запрос прав администратора...
powershell -Command "Start-Process 'cmd.exe' -ArgumentList '/c \"\"%~f0\" admin install\"' -Verb RunAs"
goto MAIN_MENU

:REMOVE
echo Запрос прав администратора...
powershell -Command "Start-Process 'cmd.exe' -ArgumentList '/c \"\"%~f0\" admin remove\"' -Verb RunAs"
goto MAIN_MENU

:STATUS
call :CHECK_STATUS
pause
goto MAIN_MENU

:INSTALL_ADMIN
cls
echo [УСТАНОВКА] Загрузка компонентов...
call :ANIMATION "Установка сервиса" 3
cd /d "%~dp0"
set "BIN_PATH=%~dp0bin\"
set "LISTS_PATH=%~dp0lists\"

:: Поиск .bat файлов
echo.
echo Выберите конфигурацию:
set "count=0"
for %%f in (*.bat) do (
    set "filename=%%~nxf"
    if /i not "!filename!"=="%~nx0" if /i not "!filename:~0,7!"=="service" if /i not "!filename:~0,13!"=="check_updates" (
        set /a count+=1
        echo !count!. %%f
        set "file!count!=%%f"
    )
)

:: Выбор файла
set "choice="
set /p "choice=Введите номер конфигурации: "
if "!choice!"=="" goto INSTALL_ADMIN

set "selectedFile=!file%choice%!"
if not defined selectedFile (
    echo Неверный выбор
    pause
    goto INSTALL_ADMIN
)

:: Парсинг аргументов
set "args="
set "capture=0"
for /f "tokens=*" %%a in ('type "!selectedFile!"') do (
    set "line=%%a"
    echo !line! | findstr /i "!BIN_PATH!winws.exe" >nul && set "capture=1"
    if !capture!==1 (
        set "args=!line:*winws.exe=!"
        goto CREATE_SERVICE
    )
)

:CREATE_SERVICE
echo Создание сервиса...
sc create zapret binPath= "\"%BIN_PATH%winws.exe\"%args%" DisplayName= "zapret" start= auto >nul
sc description zapret "Zapret DPI bypass software" >nul
net start zapret >nul
echo Сервис успешно установлен!
pause
goto MAIN_MENU

:REMOVE_ADMIN
cls
echo [УДАЛЕНИЕ] Остановка сервисов...
call :ANIMATION "Удаление сервиса" 2
net stop zapret >nul 2>&1
sc delete zapret >nul
net stop WinDivert >nul 2>&1
sc delete WinDivert >nul
net stop WinDivert14 >nul 2>&1
sc delete WinDivert14 >nul
echo Все сервисы удалены!
pause
goto MAIN_MENU

:CHECK_STATUS
echo.
echo Проверка состояния сервисов...
call :TEST_SERVICE zapret
call :TEST_SERVICE WinDivert
call :TEST_SERVICE WinDivert14
exit /b

:TEST_SERVICE
set "ServiceName=%~1"
for /f "tokens=3 delims=: " %%A in ('sc query "%ServiceName%" ^| findstr /i "STATE" 2^>nul') do set "status=%%A"
if "%status: =%"=="RUNNING" (
    echo [✔] %ServiceName% работает
) else (
    echo [✘] %ServiceName% не запущен
)
exit /b

:ANIMATION
setlocal
set "msg=%~1"
set "cnt=%~2"
:ANIM_LOOP
for /l %%i in (1,1,%cnt%) do (
    ping -n 2 127.0.0.1 >nul
    set /p "=   %msg%[!dots!]" <nul
    set "dots=.!dots!"
)
echo.
endlocal
exit /b

:STATUS_ADMIN
call :CHECK_STATUS
pause
goto MAIN_MENU