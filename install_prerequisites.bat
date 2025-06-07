@echo off
setlocal

echo Starting prerequisite check/guidance for NYC Taxi Analysis project...
echo This script will guide you through manual installations.
echo For some steps, you may need Administrator privileges.

REM --- Check/Install Git ---
echo.
echo --- Git ---
where git >nul 2>nul
if %errorlevel% equ 0 (
    echo Git appears to be installed.
    git --version
) else (
    echo Git not found.
    echo Please download and install Git for Windows from:
    echo   https://git-scm.com/download/win
    echo Ensure Git is added to your system PATH during installation.
    pause
)

REM --- Check/Install JDK (OpenJDK 1.8+) ---
echo.
echo --- Java Development Kit (JDK) ---
where java >nul 2>nul
if %errorlevel% equ 0 (
    echo Java command found. Checking version...
    java -version
    echo.
    if defined JAVA_HOME (
        echo JAVA_HOME is set to: %JAVA_HOME%
    ) else (
        echo JAVA_HOME environment variable is NOT set. This is crucial!
    )
    echo Please ensure you have JDK 1.8 or a newer LTS version (e.g., OpenJDK 11, 17 from Adoptium/Temurin).
    echo If not, or if JAVA_HOME is not set correctly, please do the following:
) else (
    echo Java (JDK) not found.
)
echo 1. Download OpenJDK (e.g., Temurin 8 LTS, 11 LTS, or 17 LTS) from:
echo    https://adoptium.net/temurin/releases/
echo    (Choose the JDK, not JRE, for your Windows x64 architecture - MSI installer recommended)
echo 2. Install the JDK.
echo 3. Set the JAVA_HOME environment variable:
echo    - Search for "environment variables" in Windows search.
echo    - Click "Edit the system environment variables".
echo    - Click "Environment Variables...".
echo    - Under "System variables", click "New...".
echo      Variable name: JAVA_HOME
echo      Variable value: C:\Program Files\Eclipse Adoptium\jdk-8.x.x_x (Path to your JDK installation)
echo    - Find the "Path" variable under "System variables", select it, and click "Edit...".
echo    - Click "New" and add: %JAVA_HOME%\bin
echo    - Click OK on all dialogs.
echo    - You may need to open a new Command Prompt for changes to take effect.
pause


REM --- Check/Install Maven ---
echo.
echo --- Apache Maven ---
where mvn >nul 2>nul
if %errorlevel% equ 0 (
    echo Maven appears to be installed.
    mvn -version
) else (
    echo Maven not found.
    echo Please download and install Apache Maven:
    echo 1. Download Maven binary zip archive (e.g., apache-maven-3.9.x-bin.zip) from:
    echo    https://maven.apache.org/download.cgi
    echo 2. Extract the archive to a directory, e.g., C:\Program Files\Apache\maven-3.9.x
    echo 3. Set M2_HOME and update PATH environment variables:
    echo    - Set M2_HOME system variable to your Maven installation directory (e.g., C:\Program Files\Apache\maven-3.9.x)
    echo    - Add %M2_HOME%\bin to your system PATH variable (similar to JAVA_HOME setup).
    echo    - Alternatively, some users prefer MAVEN_HOME instead of M2_HOME.
    echo    - You may need to open a new Command Prompt for changes to take effect.
    pause
)


REM --- Apache Hadoop (Guidance) ---
echo.
echo --- Apache Hadoop ---
echo IMPORTANT: Running Hadoop natively on Windows is complex and NOT generally recommended for development.
echo The PREFERRED method is to use Windows Subsystem for Linux 2 (WSL2) and follow Linux setup instructions.
echo.
if defined HADOOP_HOME (
    echo HADOOP_HOME is set to: %HADOOP_HOME%
    echo Please ensure this points to a correctly configured Hadoop 3.3.x installation.
) else (
    echo HADOOP_HOME environment variable is NOT set.
)
echo.
echo If you intend to run Hadoop natively on Windows (ADVANCED USERS):
echo 1. Download Hadoop 3.3.x binary (e.g., hadoop-3.3.6.tar.gz) from:
echo    https://hadoop.apache.org/releases.html
echo 2. Extract it to a directory like C:\Hadoop
echo 3. CRITICAL: You will need 'winutils.exe' and other Hadoop Windows binaries compatible with your Hadoop version.
echo    Search for "winutils for Hadoop <your_version>" (e.g., "winutils for Hadoop 3.3.6").
echo    A common repository is: https://github.com/cdarlint/winutils
echo    Download and place these in a 'bin' subdirectory of your Hadoop installation (e.g., C:\Hadoop\bin).
echo 4. Set HADOOP_HOME environment variable (e.g., C:\Hadoop).
echo 5. Add %HADOOP_HOME%\bin and %HADOOP_HOME%\sbin to your system PATH.
echo 6. Configure Hadoop files in %HADOOP_HOME%\etc\hadoop (core-site.xml, hdfs-site.xml, mapred-site.xml, yarn-site.xml).
echo    Ensure JAVA_HOME is correctly specified in hadoop-env.cmd (using Windows path format).
echo.
echo AGAIN, WSL2 IS STRONGLY RECOMMENDED FOR A SMOOTHER HADOOP EXPERIENCE ON WINDOWS.
pause

echo.
echo Prerequisite check/guidance script finished.
echo Please ensure all tools are correctly installed and environment variables are set.
echo You may need to restart your Command Prompt or your system for all changes to take effect.

endlocal