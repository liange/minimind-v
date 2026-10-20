@echo off
rem ============================================================
rem  MiniMind-V launcher for Windows
rem  Usage: run.bat [mode] [args passed to the python script...]
rem  Modes: eval / web / pretrain / sft / py / shell / help
rem  - always uses the project-local .venv interpreter
rem  - enables UTF-8 output (Chinese text and emoji print correctly)
rem  NOTE: keep this file ASCII-only; cmd.exe mis-parses UTF-8
rem        batch files while code page 65001 is active.
rem ============================================================
chcp 65001 >nul
for /f "tokens=2 delims=:." %%c in ('chcp') do set "OLDCP=%%c"

setlocal EnableExtensions
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"
title MiniMind-V
cd /d "%~dp0"

set "ROOT=%~dp0"
set "VENV_PY=%ROOT%.venv\Scripts\python.exe"
set "MODE=%~1"
if "%MODE%"=="" set "MODE=eval"
set "EXITCODE=0"
set "PAUSE_ON_EXIT=1"
if /i "%MODE%"=="py" set "PAUSE_ON_EXIT="
if /i "%MODE%"=="shell" set "PAUSE_ON_EXIT="
if "%MINIMIND_NOPAUSE%"=="1" set "PAUSE_ON_EXIT="

if /i "%MODE%"=="help" goto :help
if /i "%MODE%"=="shell" goto :shell
if not exist "%VENV_PY%" goto :no_venv

set "SCRIPT="
set "RAW="
if /i "%MODE%"=="eval"     set "SCRIPT=eval_vlm.py"
if /i "%MODE%"=="web"      set "SCRIPT=scripts\web_demo_vlm.py"
if /i "%MODE%"=="pretrain" set "SCRIPT=trainer\train_pretrain_vlm.py"
if /i "%MODE%"=="sft"      set "SCRIPT=trainer\train_sft_vlm.py"
if /i "%MODE%"=="py"       set "RAW=1"
if defined SCRIPT goto :collect
if defined RAW goto :collect
goto :unknown

rem ---------- collect every argument after the mode (quotes kept) ----------
:collect
set "REST="
shift
:collect_loop
if "%~1"=="" goto :run
set "REST=%REST% "%~1""
shift
goto :collect_loop

rem ---------- run ----------
:run
if defined RAW goto :run_raw
echo [MiniMind-V] interpreter : %VENV_PY%
echo [MiniMind-V] script      : %SCRIPT%
echo [MiniMind-V] arguments   : %REST%
echo ------------------------------------------------------------
"%VENV_PY%" "%SCRIPT%" %REST%
set "EXITCODE=%ERRORLEVEL%"
goto :report

:run_raw
echo [MiniMind-V] command     : python %REST%
echo ------------------------------------------------------------
"%VENV_PY%" %REST%
set "EXITCODE=%ERRORLEVEL%"
goto :report

:report
echo ------------------------------------------------------------
if "%EXITCODE%"=="0" echo [MiniMind-V] finished successfully.
if not "%EXITCODE%"=="0" echo [MiniMind-V] FAILED with exit code %EXITCODE%.
goto :finish

rem ---------- interactive shell inside the venv ----------
:shell
if not exist "%VENV_PY%" goto :no_venv
call "%ROOT%.venv\Scripts\activate.bat"
echo [MiniMind-V] virtual environment activated, type "exit" to leave.
echo ------------------------------------------------------------
cmd /k
set "EXITCODE=0"
goto :finish

rem ---------- venv missing ----------
:no_venv
echo [ERROR] virtual environment not found: %VENV_PY%
echo.
echo Run these commands in the project root first (see README.md, Step 0 - 1'):
echo   py -3.12 -m venv .venv
echo   .\.venv\Scripts\python.exe -m pip install torch==2.6.0 torchvision==0.21.0 --index-url https://download.pytorch.org/whl/cu126
echo   .\.venv\Scripts\python.exe -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
set "EXITCODE=1"
goto :finish

rem ---------- unknown mode ----------
:unknown
echo [ERROR] unknown mode: %MODE%
echo.
set "EXITCODE=1"

rem ---------- help ----------
:help
echo MiniMind-V launcher
echo.
echo Usage: run.bat ^<mode^> [args passed to the python script...]
echo.
echo   eval            image inference, eval_vlm.py (default when no mode given)
echo   web             Gradio web demo, scripts\web_demo_vlm.py (port 8888)
echo   pretrain        pre-training, trainer\train_pretrain_vlm.py
echo   sft             SFT fine-tuning, trainer\train_sft_vlm.py
echo   py ^<args...^>    run any command/script with the venv interpreter
echo   shell           open a command prompt inside the activated venv
echo   help            show this help
echo.
echo Examples:
echo   run.bat
echo   run.bat eval --weight pretrain_vlm
echo   run.bat eval --weight sft_vlm_moe --use_moe 1
echo   run.bat web
echo   run.bat pretrain --epochs 2
echo   run.bat py -c "import torch; print(torch.__version__, torch.cuda.is_available())"
echo.
echo Tip: set MINIMIND_NOPAUSE=1 to skip the final pause.
goto :finish

rem ---------- finish ----------
:finish
if defined OLDCP chcp %OLDCP% >nul
if defined PAUSE_ON_EXIT (
    echo.
    echo Press any key to close this window...
    pause >nul
)
endlocal & exit /b %EXITCODE%
