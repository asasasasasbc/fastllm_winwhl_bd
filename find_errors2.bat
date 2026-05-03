@echo off
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" > nul 2>&1

echo === Reconfiguring CMake ===
cd /d d:\SillyTavern\fastllm_winwhl_bd\build-fastllm-win-cuda
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DUSE_CUDA=ON -DUSE_NUMAS=OFF -DCMAKE_CUDA_ARCHITECTURES="70;75;80;86;89;90" -DCMAKE_MAKE_PROGRAM=C:/Python312/Scripts/ninja.exe d:\SillyTavern\fastllm_winwhl_bd
if %errorlevel% neq 0 (echo CMake configure failed! & exit /b 1)

echo === Building (single thread for clear errors) ===
cmake --build . --target fastllm_tools -- -j1 2>&1 | findstr /i "error FAILED Building"
if %errorlevel% neq 0 (echo Build failed! & exit /b 1)

echo Done!
