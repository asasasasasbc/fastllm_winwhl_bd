@echo off
setlocal EnableExtensions

set "ROOT_DIR=%~dp0"
if "%ROOT_DIR:~-1%"=="\" set "ROOT_DIR=%ROOT_DIR:~0,-1%"

set "BUILD_DIR=%ROOT_DIR%\build-fastllm-win-cuda"
set "CONFIG=Release"
set "PLAT_NAME=win_amd64"
set "NIGHTLY=0"
set "CUDA_ARCH_LIST=70;75;80;86;89;90;100;120"

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--nightly" (
    set "NIGHTLY=1"
    shift
    goto parse_args
)
if /I "%~1"=="--help" goto usage
if /I "%~1"=="-h" goto usage
echo Unknown argument: %~1
goto usage

:args_done
pushd "%ROOT_DIR%" || exit /b 1

set "PYTHON_EXE="
set "PYTHON_ARGS="
where py >nul 2>&1 && (
    set "PYTHON_EXE=py"
    set "PYTHON_ARGS=-3"
)
if not defined PYTHON_EXE where python >nul 2>&1 && set "PYTHON_EXE=python"
if not defined PYTHON_EXE (
    echo Python not found. Please install Python 3 and ensure py or python is in PATH.
    exit /b 1
)

where cmake >nul 2>&1 || (
    echo CMake not found. Please install CMake and ensure it is in PATH.
    exit /b 1
)

where nvcc >nul 2>&1 || (
    echo nvcc not found. Please install CUDA Toolkit and ensure nvcc is in PATH.
    exit /b 1
)

if not defined VSCMD_VER call :init_vs_env
where cl >nul 2>&1 || (
    echo MSVC compiler not found. Please run this script in a Visual Studio x64 Native Tools prompt,
    echo or install Visual Studio Build Tools with C++ support.
    exit /b 1
)

set "CMAKE_GENERATOR="
call :resolve_generator
if not defined CMAKE_GENERATOR (
    echo Failed to determine a supported Visual Studio CMake generator.
    exit /b 1
)

if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%" || exit /b 1

set "FASTLLM_NIGHTLY=%NIGHTLY%"

echo Using generator: %CMAKE_GENERATOR%
echo Using CUDA architectures: %CUDA_ARCH_LIST%

cmake -S "%ROOT_DIR%" -B "%BUILD_DIR%" ^
    -G "%CMAKE_GENERATOR%" ^
    -A x64 ^
    -T host=x64 ^
    -DMAKE_WHL_X86=ON ^
    -DUSE_CUDA=ON ^
    -DUSE_NUMA=OFF ^
    -DUSE_NUMAS=OFF ^
    -DCUDA_ARCH="%CUDA_ARCH_LIST%" ^
    -DCMAKE_CUDA_ARCHITECTURES="%CUDA_ARCH_LIST%" || exit /b 1

cmake --build "%BUILD_DIR%" --target fastllm_tools --config "%CONFIG%" -- /m || exit /b 1

pushd "%BUILD_DIR%\tools" || exit /b 1
"%PYTHON_EXE%" %PYTHON_ARGS% setup.py sdist build || exit /b 1
"%PYTHON_EXE%" %PYTHON_ARGS% setup.py bdist_wheel --plat-name %PLAT_NAME% || exit /b 1
popd

echo.
echo Wheel created:
echo %BUILD_DIR%\tools\dist
popd
exit /b 0

:init_vs_env
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" goto :eof

for /f "usebackq delims=" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSINSTALL_PATH=%%I"
if not defined VSINSTALL_PATH goto :eof

if exist "%VSINSTALL_PATH%\Common7\Tools\VsDevCmd.bat" (
    call "%VSINSTALL_PATH%\Common7\Tools\VsDevCmd.bat" -arch=x64 -host_arch=x64
)
goto :eof

:resolve_generator
if defined CMAKE_GENERATOR goto :eof

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" goto :eof

for /f "usebackq delims=" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationVersion`) do set "VS_VERSION=%%I"
for /f "tokens=1 delims=." %%I in ("%VS_VERSION%") do set "VS_MAJOR=%%I"

if "%VS_MAJOR%"=="17" set "CMAKE_GENERATOR=Visual Studio 17 2022"
if "%VS_MAJOR%"=="16" set "CMAKE_GENERATOR=Visual Studio 16 2019"
if "%VS_MAJOR%"=="15" set "CMAKE_GENERATOR=Visual Studio 15 2017"
goto :eof

:usage
echo Usage: build.bat [--nightly]
echo.
echo Build a Windows + Nvidia CUDA ftllm wheel in a Visual Studio/MSVC environment.
exit /b 1
