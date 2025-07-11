@echo off

REM No CLI arguments supported anymore
set COMMANDLINE_ARGS=

cd /D "%~dp0"

echo "%CD%"| findstr /C:" " >nul && echo This script relies on Miniconda which can not be silently installed under a path with spaces. && goto end

set PATH=%PATH%;%SystemRoot%\system32

@rem config
set INSTALL_DIR=%cd%\installer_files
set CONDA_ROOT_PREFIX=%cd%\installer_files\conda
set INSTALL_ENV_DIR=%cd%\installer_files\env
set MINICONDA_DOWNLOAD_URL=https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe
set FFMPEG_DOWNLOAD_URL=https://github.com/GyanD/codexffmpeg/releases/download/7.1/ffmpeg-7.1-essentials_build.zip
set INSTALL_FFMPEG_DIR=%cd%\installer_files\ffmpeg
set INSIGHTFACE_PACKAGE_URL=https://huggingface.co/hanamizuki-ai/insightface-releases/blob/main/insightface-0.7.3-cp310-cp310-win_amd64.whl
set INSIGHTFACE_PACKAGE_PATH=%INSTALL_DIR%\insightface-0.7.3-cp310-cp310-win_amd64.whl

set conda_exists=F
set ffmpeg_exists=F

@rem figure out whether git and conda needs to be installed
call "%CONDA_ROOT_PREFIX%\_conda.exe" --version >nul 2>&1
if "%ERRORLEVEL%" EQU "0" set conda_exists=T

@rem Check if FFmpeg is already in PATH
where ffmpeg >nul 2>&1
if "%ERRORLEVEL%" EQU "0" (
    echo FFmpeg is already installed.
    set ffmpeg_exists=T
)

@rem (if necessary) install git and conda into a contained environment

@rem download conda
if "%conda_exists%" == "F" (
    echo Downloading Miniconda from %MINICONDA_DOWNLOAD_URL% to %INSTALL_DIR%\miniconda_installer.exe
    mkdir "%INSTALL_DIR%"
    call curl -Lk "%MINICONDA_DOWNLOAD_URL%" > "%INSTALL_DIR%\miniconda_installer.exe" || ( echo. && echo Miniconda failed to download. && goto end )
    echo Installing Miniconda to %CONDA_ROOT_PREFIX%
    start /wait "" "%INSTALL_DIR%\miniconda_installer.exe" /InstallationType=JustMe /NoShortcuts=1 /AddToPath=0 /RegisterPython=0 /NoRegistry=1 /S /D=%CONDA_ROOT_PREFIX%

    @rem test the conda binary
    echo Miniconda version:
    call "%CONDA_ROOT_PREFIX%\_conda.exe" --version || ( echo. && echo Miniconda not found. && goto end )
)

@rem create the installer env
if not exist "%INSTALL_ENV_DIR%" (
    echo Creating Conda Environment
    call "%CONDA_ROOT_PREFIX%\_conda.exe" create --no-shortcuts -y -k --prefix "%INSTALL_ENV_DIR%" python=3.10 || ( echo. && echo ERROR: Conda environment creation failed. && goto end )
    @rem check if conda environment was actually created
    if not exist "%INSTALL_ENV_DIR%\python.exe" ( echo. && echo ERROR: Conda environment is empty. && goto end )
    @rem activate installer env
    call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%" || ( echo. && echo ERROR: Miniconda hook not found. && goto end )
    @rem Download insightface package
    echo Downloading insightface package from %INSIGHTFACE_PACKAGE_URL% to %INSIGHTFACE_PACKAGE_PATH%
    call curl -Lk "%INSIGHTFACE_PACKAGE_URL%" > "%INSIGHTFACE_PACKAGE_PATH%" || ( echo. && echo ERROR: Insightface package failed to download. && goto end )
    @rem install insightface package using pip
    echo Installing insightface package
    call pip install "%INSIGHTFACE_PACKAGE_PATH%" || ( echo. && echo ERROR: Insightface package installation failed. && goto end )
)

@rem Download and install FFmpeg if not already installed
if "%ffmpeg_exists%" == "F" (
    if not exist "%INSTALL_FFMPEG_DIR%" (
        echo Downloading ffmpeg from %FFMPEG_DOWNLOAD_URL% to %INSTALL_DIR%
        call curl -Lk "%FFMPEG_DOWNLOAD_URL%" > "%INSTALL_DIR%\ffmpeg.zip" || ( echo. && echo ffmpeg failed to download. && goto end )
        call powershell -command "Expand-Archive -Force '%INSTALL_DIR%\ffmpeg.zip' '%INSTALL_DIR%\'"
        cd "%INSTALL_DIR%"
        move ffmpeg-* ffmpeg
        setx PATH "%INSTALL_FFMPEG_DIR%\bin\;%PATH%"
        echo To use videos, you need to restart roop after this installation.
        cd ..
    )
) else (
    echo Skipping FFmpeg installation as it is already available.
)

@rem setup installer env
@rem check if conda environment was actually created
if not exist "%INSTALL_ENV_DIR%\python.exe" ( echo. && echo ERROR: Conda environment is empty. && goto end )
@rem activate installer env
call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%" || ( echo. && echo ERROR: Miniconda hook not found. && goto end )
echo Launching roop unleashed
call python installer.py %COMMANDLINE_ARGS%

echo.
echo Done!

:end
pause
