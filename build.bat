@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT_DIR=%~dp0"
if "%ROOT_DIR:~-1%"=="\" set "ROOT_DIR=%ROOT_DIR:~0,-1%"

set "GENERATOR=Ninja"
set "CONFIG=Release"
if not defined CUDA_ARCHS set "CUDA_ARCHS=70;75;80;86;89;90"
set "DIST_DIR=%ROOT_DIR%\pyfastllm\dist"
set "PYFASTLLM_DIR=%ROOT_DIR%\pyfastllm"
set "VENV_PYTHON=%ROOT_DIR%\.venv\Scripts\python.exe"
set "PYTHON_EXE="
set "VSDEVCMD="
set "NINJA_EXE="
set "CUDA_BIN="
set "CUDACXX="

echo Using generator: %GENERATOR%
echo Using CUDA architectures: %CUDA_ARCHS%

pushd "%ROOT_DIR%"

call :ensure_vs_environment
if errorlevel 1 goto :fail

call :ensure_ninja
if errorlevel 1 goto :fail

call :ensure_cuda
if errorlevel 1 goto :fail

call :ensure_python
if errorlevel 1 goto :fail

where cmake >nul 2>nul
if errorlevel 1 (
    echo [ERROR] cmake.exe not found in PATH.
    goto :fail
)

echo Cleaning previous Python build artifacts...
if exist "%PYFASTLLM_DIR%\build" rmdir /s /q "%PYFASTLLM_DIR%\build"
if exist "%DIST_DIR%" del /q "%DIST_DIR%\*.whl" >nul 2>nul

echo Installing wheel build dependencies...
"%PYTHON_EXE%" -m pip install --disable-pip-version-check -U setuptools wheel
if errorlevel 1 goto :fail

set "CMAKE_GENERATOR=%GENERATOR%"
set "USE_CUDA=ON"
set "CMAKE_MAKE_PROGRAM=%NINJA_EXE%"
set "CUDACXX=%CUDACXX%"
set "CMAKE_ARGS=-DCMAKE_BUILD_TYPE=%CONFIG% -DCMAKE_CUDA_ARCHITECTURES=%CUDA_ARCHS% -DUSE_NUMA=OFF -DUSE_NUMAS=OFF -DUSE_MULTICUDA=OFF -DUSE_FLASHINFER=OFF"

echo Building wheel...
pushd "%PYFASTLLM_DIR%"
"%PYTHON_EXE%" setup.py bdist_wheel --dist-dir "%DIST_DIR%"
if errorlevel 1 (
    popd
    goto :fail
)
popd

echo.
echo Wheel output:
dir /b "%DIST_DIR%\*.whl"
if errorlevel 1 goto :fail

popd
echo Build completed.
exit /b 0

:ensure_vs_environment
where cl >nul 2>nul
if not errorlevel 1 goto :eof

for %%D in (
    "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\Tools\VsDevCmd.bat"
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat"
    "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"
) do (
    if exist "%%~D" (
        set "VSDEVCMD=%%~D"
        goto :vsdevcmd_found
    )
)

echo [ERROR] Unable to find VsDevCmd.bat.
exit /b 1

:vsdevcmd_found
echo Initializing Visual Studio build environment...
call "%VSDEVCMD%" -host_arch=x64 -arch=x64 >nul
where cl >nul 2>nul
if errorlevel 1 (
    echo [ERROR] cl.exe is still unavailable after initializing Visual Studio.
    exit /b 1
)
exit /b 0

:ensure_ninja
where ninja >nul 2>nul
if not errorlevel 1 (
    for /f "delims=" %%I in ('where ninja') do (
        set "NINJA_EXE=%%~fI"
        goto :ninja_ready
    )
)

for %%I in (
    "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"
    "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe"
) do (
    if exist "%%~I" (
        set "NINJA_EXE=%%~fI"
        set "PATH=%%~dpI;%PATH%"
        goto :ninja_ready
    )
)

echo [ERROR] ninja.exe not found.
exit /b 1

:ninja_ready
echo Using Ninja: %NINJA_EXE%
exit /b 0

:ensure_cuda
where nvcc >nul 2>nul
if not errorlevel 1 (
    for /f "delims=" %%I in ('where nvcc') do (
        set "CUDACXX=%%~fI"
        goto :cuda_ready
    )
)

for /d %%D in ("C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v*") do (
    if exist "%%~fD\bin\nvcc.exe" (
        set "CUDA_BIN=%%~fD\bin"
        set "CUDACXX=%%~fD\bin\nvcc.exe"
    )
)

if not defined CUDACXX (
    echo [ERROR] nvcc.exe not found.
    exit /b 1
)

set "PATH=%CUDA_BIN%;%PATH%"

:cuda_ready
echo Using NVCC: %CUDACXX%
exit /b 0

:ensure_python
if exist "%VENV_PYTHON%" (
    set "PYTHON_EXE=%VENV_PYTHON%"
    goto :python_ready
)

for /f "delims=" %%I in ('where python 2^>nul') do (
    set "PYTHON_EXE=%%~fI"
    goto :python_ready
)

echo [ERROR] Python executable not found.
exit /b 1

:python_ready
echo Using Python: %PYTHON_EXE%
exit /b 0

:fail
set "EXIT_CODE=%ERRORLEVEL%"
if not defined EXIT_CODE set "EXIT_CODE=1"
popd
exit /b %EXIT_CODE%