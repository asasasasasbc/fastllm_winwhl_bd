@echo off
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" > nul 2>&1
cd /d d:\SillyTavern\fastllm_winwhl_bd\build-fastllm-win-cuda
cmake --build . --target fastllm_tools -- -j1 2>&1 | findstr /i "error FAILED Building"
