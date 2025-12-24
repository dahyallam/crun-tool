@echo off
	set "CRUN_DIR=%~dp0.."
	set "CRUN_VERSION=1.0"
	
	if not defined CRUN_STARTUP_FLAG call :enableAnsicon
	set "CRUN_STARTUP_FLAG=1"
	
	setlocal EnableDelayedExpansion
	chcp 65001 >nul 2>&1

	REM Check parameters-list if it's empty go to the help label and exit.
	if "%~1" == "" goto :help
	
	REM == Configurations ==
	set "PROJECT_DIR=%CD%"
	set "SRC_DIR=%PROJECT_DIR%\src"
	set "INC_DIR=%PROJECT_DIR%\include"
	set "OBJ_DIR=%PROJECT_DIR%\obj"
	set "BIN_DIR=%PROJECT_DIR%\bin"
	for %%i in (.) do set "EXE_NAME=%%~nxi"
	set "EXE_PATH=%BIN_DIR%\%EXE_NAME%.exe"
	
	set "CC="
	set "WILDCARD="
	set "NEW_PROJECT="
	set "BUILD="
	set "SMART_BUILD="
	set "CFLAGS="
	set "LDFLAGS="
	set "CONFIG="
	set "RUN="
	set "ARGS="
	set "CLEAN="
	set "CLEAR_SCREEN="
	set "INSTALL_MINGW="
	set "UNINSTALL_MINGW="
	set "UPDATE_TOOL="
	set "HELP="
	set "OPTIONS_COUNT=0"
	
	REM == Parse command-line arguments ==
	:loop
		if "%~1" == "" goto :start
		if /i "%~1" == "--new" (
			goto :createProject
		) else if /i "%~1" == "--build" (
			call :isDefined BUILD
			if errorlevel 1 goto :eof
			
			set "BUILD=1"
			set /a "OPTIONS_COUNT+=1"
		) else if /i "%~1" == "--smart-build" (
			call :isDefined SMART_BUILD
			if errorlevel 1 goto :eof
			
			set "SMART_BUILD=1"
			set /a "OPTIONS_COUNT+=1"
		) else if /i "%~1" == "--run" (
			call :isDefined RUN
			if errorlevel 1 goto :eof
			
			set "RUN=1"
			set /a "OPTIONS_COUNT+=1"
		) else if /i "%~1" == "--clean" (
			call :isDefined CLEAN
			if errorlevel 1 goto :eof
			
			set "CLEAN=1"
			set /a "OPTIONS_COUNT+=1"
		) else if /i "%~1" == "--clear" (
			call :isDefined CLEAR_SCREEN
			if errorlevel 1 goto :eof
			
			set "CLEAR_SCREEN=1"
		) else if /i "%~1" == "--install" (
			call :isDefined INSTALL_MINGW
			if errorlevel 1 goto :eof
			
			set "INSTALL_MINGW=1"
			set /a "OPTIONS_COUNT+=1"
		) else if /i "%~1" == "--uninstall" (
			call :isDefined UNINSTALL_MINGW
			if errorlevel 1 goto :eof
			
			set "UNINSTALL_MINGW=1"
			set /a "OPTIONS_COUNT+=1"
		) else if /i "%~1" == "--update" (
			call :isDefined UPDATE_TOOL
			if errorlevel 1 goto :eof
			
			set "UPDATE_TOOL=1"
			set /a "OPTIONS_COUNT+=1"
			
		) else if /i "%~1" == "--version" (
			echo CRun %CRUN_VERSION%
			goto :eof
		) else if /i "%~1" == "--help" (
			set "HELP=1"
		) else if /i "%~1" == "--lang" (
			call :isDefined CC
			if errorlevel 1 goto :eof
			
			call :checkOption "%~1" "%~2"
			if errorlevel 1 (
				exit /b 1
			)
			
			if /i "%~2" == "c" (
				set "CC=gcc"
				set "WILDCARD=*.c"
			) else if /i "%~2" == "cpp" (
				set "CC=g++"
				set "WILDCARD=*.cpp *.cxx *.c++"
			) else (
				call :println "[^!] Invalid language: '%~2'." red endl
				echo Supported values are:
				echo   - c    ^(C language^)
				echo   - cpp  ^(C++ language^)
				echo.
				echo Example:
				echo   crun --lang c
				echo   crun --lang cpp
				exit /b 1
			)
			shift
		) else if "%~1" == "--cflags" (
			call :isDefined CFLAGS
			if errorlevel 1 goto :eof
			
			call :checkOption "--cflags" %2
			if errorlevel 1 (
				exit /b 1
			)
			
			set "CFLAGS=%~2"
			shift
		) else if "%~1" == "--ldflags" (
			call :isDefined LDFLAGS
			if errorlevel 1 goto :eof
			
			call :checkOption "--ldflags" %2
			if errorlevel 1 (
				exit /b 1
			)
			
			set "LDFLAGS=%~2"
			shift
		) else if /i "%~1" == "--config" (
			call :isDefined CONFIG
			if errorlevel 1 goto :eof
			
			if /i "%~2" == "" (
				call :println "[^!] The '%~1' option requires an argument: debug or release." red endl
				exit /b 1
			) else if /i "%~2" == "debug" (
				set "CONFIG=-O0 -g"
			) else if /i "%~2" == "release" (
				set "CONFIG=-O2 -DNDEBUG"
			) else (
				call :println "[^!] '%~2' is not a valid value for --config. Use 'debug' or 'release'." red endl
				exit /b 1
			)
			set /a "OPTIONS_COUNT+=1"
			shift
		) else if /i "%~1" == "--args" (
			if /i "%~2" == "" (
				call :println "[^!] '--args' requires one argument at least." red endl
				exit /b 1
			)
			
			:collectArgs
				if /i "%~2" == "" goto :start
				set "ARGS=!ARGS! %2"
				shift
			goto :collectArgs
		) else (
			call :isKeyworkd "%~1"
			if !errorlevel! EQU 0 (
				echo Unrecognized option: %~1
				echo for more information type: crun --help
				echo Program will exit.
				exit /b 1
			)
		)
		shift
	goto :loop
	
	:start
		REM == Clear the console screen ==
		if defined CLEAR_SCREEN cls
		
		if defined CFLAGS if not defined BUILD (
			call :println "[^!]: --cflags requires --build option!." red endl
			exit /b 1
		)
		if defined LDFLAGS if not defined BUILD (
			call :println "[^!]: --ldflags requires --build option!." red endl
			exit /b 1
		)
		if defined ARGS if not defined RUN (
			call :println "[^!]: --args requires --run option!." red endl
			exit /b 1
		)
		
		if defined HELP (
			if %OPTIONS_COUNT% GTR 1 call :println "[^!] '--help' cannot be combined with other options. All other options will be ignored." yellow endl
			goto :help
		)
		
		REM == Install option ==
		if defined UPDATE_TOOL (
			if %OPTIONS_COUNT% GTR 1 call :println "[^!] '--update' cannot be combined with other options. All other options will be ignored." yellow endl
			goto :updateTool
		)
		
		REM == Install option ==
		if defined INSTALL_MINGW (
			if %OPTIONS_COUNT% GTR 1 call :println "[^!] '--install' cannot be combined with other options. All other options will be ignored." yellow endl
			goto :installMinGW
		)
		
		REM == Uninstall option ==
		if defined UNINSTALL_MINGW (
			if %OPTIONS_COUNT% GTR 1 call :println "[^!] '--uninstall' cannot be combined with other options. All other options will be ignored." yellow endl
			goto :uninstallMinGW
		)
		
		REM == Clean option ==
		if defined CLEAN (
			if %OPTIONS_COUNT% GTR 1 call :println "[^!] '--clean' cannot be combined with other options. All other options will be ignored." yellow endl
			goto :clean
		)
		
		REM === BUILD ===
		if defined BUILD (
			if not defined CC (
				call :println "[^!] Language is not specified." red endl
				echo For more information type: 'crun --help'
				exit /b 1
			)
			
			REM === Compiler checking step ===
			call :println "========== CHECK ==========" magenta endl
			call :println "[CHECK] Checking for compiler..." magenta endl
			
			where %CC% >nul 2>&1
			if errorlevel 1 (
				endlocal DisableDelayedExpansion
				
				call :println "  [!] Compiler not found." red endl
				call :println "  [TIP]  Make sure the compiler is installed and added to your PATH environment variable." yellow endl
				
				echo.
				call :println "Compiler not detected. Would you like to install it now? [Y/n]: " cyan
				choice /N /C NY
				if errorlevel 2 (
					echo.
					goto :installMinGW
				)
				
				call :println "Installation skipped. Exiting..." magenta endl
				exit /b 0
			)
			call :println "  [+] Compiler found." green endl
			
			REM Step 2 — Check if gcc is working properly
			call :println "[CHECK] Verifying compiler functionality..." magenta endl
			gcc --version >nul 2>&1
			if errorlevel 1 (
				call :println "  [^!] Compiler found but not working correctly." red endl
				exit /b 1
			)
			call :println "  [+] Compiler is working properly." green endl
			
			call :build
		)
		
		REM == Running the program in an external console window ==
		REM <nul supress "Terminate batch job (Y/N)" confirmation.
		if %errorlevel% EQU 0 if defined RUN call :run <nul
	endlocal
exit /b 0

:isDefined
	if defined %1 (
		call :println "[^!] The '%~1' specified more than once." red endl & exit /b 1
		exit /b 1
	)
exit /b 0

:isKeyworkd
	if /i "%~1" == "--new" exit /b 1
	if /i "%~1" == "--lang" exit /b 1
	if /i "%~1" == "--build" exit /b 1
	if /i "%~1" == "--smart-build" exit /b 1
	if /i "%~1" == "--config" exit /b 1
	if /i "%~1" == "--cflags" exit /b 1
	if /i "%~1" == "--ldflags" exit /b 1
	if /i "%~1" == "--run" exit /b 1
	if /i "%~1" == "--args" exit /b 1
	if /i "%~1" == "--clean" exit /b 1
	if /i "%~1" == "--clear" exit /b 1
	if /i "%~1" == "--install" exit /b 1
	if /i "%~1" == "--uninstall" exit /b 1
	if /i "%~1" == "--update" exit /b 1
	if /i "%~1" == "--version" exit /b 1
	if /i "%~1" == "--help" exit /b 1
exit /b 0

:checkOption
	if "%~2" == "" (
		call :println "[^!] %1 requires one argument." endl red
		exit /b 1
	)
	
	set "var=%2"
	set "firstChar=%var:~0,1%"
	set "lastChar=%var:~-1%"
	set "firstChar=%firstChar:"=+%"
	set "lastChar=%lastChar:"=+%"
	set "isQuoted="
	
	if "%firstChar%" == "+" if "%lastChar%" == "+" set "isQuoted=1"
	if not defined isQuoted (
		call :println "[^!] The %1 argument must be enclosed in double quotes." red endl
		exit /b 1
	)
exit /b 0

:createProject
	REM Shift --new
	shift
	set "PROJECT_NAME=%~1"
	SET "LANG_OP=%~2"
	set "LANG=%~3"
	set "PROJECT_DIR=%PROJECT_DIR%\%PROJECT_NAME%"
	
	if "%PROJECT_NAME%" == "" (
		call :println "[^!] Missing project name." red endl
		echo Try: crun --new projectName --lang ^<c^|cpp^>
		exit /b 1
	) else if /i exist "%PROJECT_NAME%" (
		call :println "[^!] There is already a file with the same name in this location." red endl
		exit /b 1
	)
	
	if /i "%LANG_OP%" == "" (
		call :println "[^!] Missing '--lang' option." red endl
		exit /b 1
	) else if /i not "%LANG_OP%" == "--lang" (
		call :println "crun: unrecognized option: '%LANG_OP%'." red endl
		echo for more information type: crun --help
		exit /b 1
	)
	
	if /i "%LANG%"=="" (
		call :println "[^!] Missing language type." red endl
		exit /b 1
	) else if /i "%LANG%"=="c" (
		set "EXT=c"
	) else if /i "%LANG%"=="cpp" (
		set "EXT=cpp"
	) else (
		call :println "[^!] Unknown language: '%LANG%'." red endl
		exit /b 1
	)
	
	mkdir "%PROJECT_NAME%" >nul 2>&1
	mkdir "%PROJECT_DIR%\src" >nul 2>&1
	mkdir "%PROJECT_DIR%\include" >nul 2>&1
	
	setlocal DisableDelayedExpansion
	(	if "%EXT%" == "c" (echo #include ^<stdio.h^>) else echo #include ^<iostream^>
		echo.
		echo.
		echo.
		echo int main^(int argc, char *argv[]^) {
		if "%EXT%" == "c" (echo     puts^("Hello, World!"^);) else echo     std::cout ^<^<^ ^"Hello, World!^" ^<^< std::endl;
		echo.
		echo.
		echo.
		echo     return 0;
		echo }
	) >>"%PROJECT_NAME%\src\main.%EXT%"
	
	if exist "%PROJECT_NAME%\src\main.%EXT%" (
		call :println "[+] Project created successfully." green endl
		echo.
		echo To build and run your project:
		echo.
		echo   1^) cd "%PROJECT_DIR%"
		if "%EXT%" == "c" (echo   2^) crun --lang c --build --run) else echo   2^) crun --lang cpp --build --run
		echo.
		echo   or type: 'crun --help' for more information.
		echo.
		echo Your main code is located at "%PROJECT_DIR%\src\main.%EXT%"
	) else (
		call :println "Failed to create project." red endl
		exit /b 1
	)
exit /b 0

:build
	call :isExeLocked "%EXE_PATH%"
	if errorlevel 1 (
		call :println "[^!] Cannot build: "%EXE_PATH%" is running or used by another process." red endl
		call :println "[TIP]  Stop it and try again." blue endl
		exit /b 1
	)
	
	REM == Configurations step ==
	set "CFLAGS=%CFLAGS% %CONFIG% -c"
	echo.
	call :println "========== Build Configurations ==========" pastelPurple endl
	call :println "[CONFIG] Compiler: %CC%" pastelPurple endl
	call :println "[CONFIG] CFLAGS: %CFLAGS%" pastelPurple endl
	if defined LDFLAGS call :println "[CONFIG] LDFLAGS: %LDFLAGS%" pastelPurple endl
	if defined ARGS echo [38;5;147m[CONFIG] ARGS: %ARGS%[0m
	if defined SMART_BUILD call :println "[CONFIG] SMART BUILD: enabled" pastelPurple endl
	
	REM == Compiling step ==
	echo.
	call :println "========== BUILD ==========" orange endl
	dir /s /b "%SRC_DIR%" 2>nul | findstr /c:"." >nul 2>&1 || (
		call :println "[BUILD] No source files found to compile." red endl
		exit /b 1
	)
	
	call :println "[BUILD] Compiling source files..." orange endl
	set "SUCCESS_COUNT=0"
	set "FAIL_COUNT=0"
	set "EXIT_CODE="
	set "COMPILED_SOURCES="
	set "LOG_FILE=build_log.log"
    (	echo ==================== BUILD LOG ====================
		echo Build started: %date% %time%
		echo Compiler: %CC%
		echo CFLAGS  : %CFLAGS%
		echo LDFLAGS : %LDFLAGS%
		echo.
		echo Source directory : %SRC_DIR%
		echo Include directory: %INC_DIR%
		echo Output directory : %OBJ_DIR%
		echo Executable       : %EXE_PATH%
		echo.
		echo Compiled files:
	) >> "%LOG_FILE%"
	
	REM Create obj and bin directories if they don't exist.
	if not exist "%OBJ_DIR%" mkdir "%OBJ_DIR%"
	if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
	
	for /r "%SRC_DIR%" %%i in (%WILDCARD%) do (
		if defined SMART_BUILD if exist "%OBJ_DIR%\%%~ni.o" (
			xcopy <nul /l /d /y "%%~i" "%OBJ_DIR%\%%~ni.o" | findstr /b /c:"1 " >nul 2>&1
		)
		
		if errorlevel 1 (
			call :println "  [++] Up-to-date: %%i" green endl
		) else (
			call :println "  [BUILD]  Compiling: %%i..." orange endl
			%CC% %CFLAGS% -I"%INC_DIR%" -o"%OBJ_DIR%\%%~ni.o" "%%i"
			
			REM == Check the compiling process status code ==
			if not errorlevel 1 (
				set "COMPILED_SOURCES=!COMPILED_SOURCES!;%OBJ_DIR%\%%~ni.o"
				set /a SUCCESS_COUNT+=1
				call :println "    [+] %OBJ_DIR%\%%~ni.o" green endl
				echo   - %%i : Success>> "%LOG_FILE%"
			) else (
				set "EXIT_CODE=!errorlevel!"
				call :println "    [^!] %%i - failed" red endl
				echo   - %%i : Failed>> "%LOG_FILE%"
				set /a FAIL_COUNT+=1
				
				call :println "[BUILD] Compilation failed with exit code: !EXIT_CODE!" red endl
				(	echo.
					echo Linking stage: Skipped ^(build failed^)
					echo.
					echo Summary:
					echo   Total files compiled: %SUCCESS_COUNT%
					echo   Successful: %SUCCESS_COUNT%
					echo   Failed: %FAIL_COUNT%
					echo   Build finished: %date% %time%
					echo ===================================================
					echo.
				) >> "%LOG_FILE%"
				exit /b !EXIT_CODE!
			)
		)
	)
	
	if %SUCCESS_COUNT% GTR 0 (
		call :println "[BUILD] Compilation completed successfully." green endl
	) else (
		call :println "    [BUILD] [4mAll source file(s) are up-to-date." green endl
		call :println "[BUILD] Compiling step is (Skipped)." orange endl
	)
	
	REM == Linking step ==
	echo.
	call :println "[BUILD] Linking..." yellow endl
	if %SUCCESS_COUNT% GTR 0 (
		call :link
	) else if not exist "%EXE_PATH%" (
		if %SUCCESS_COUNT% EQU 0 (
			call :println "[BUILD] Object file(s) are up-to-date. but [31mthe executable is missing[0m [33m— forcing relinking." yellow endl
		)
		call :link
	) else (
		for %%i in ("%OBJ_DIR%\*.o") do (
			call :println "  [+] Up-to-date: %%i" green endl
		)
		
		call :println "    [BUILD] [4mAll object file(s) are up-to-date." green endl
		call :println "[BUILD] Linking step is (Skipped)." yellow endl
		call :println "  [+] Executable located at: %EXE_PATH%" green endl
		call :println "[BUILD] All is done." green endl
		echo. >>"%LOG_FILE%"
		echo Linking stage: Skipped ^(Source files are up-to-date^) >>"%LOG_FILE%"
		if not defined run (
			echo. & call :println "[TIP] In order to run your program type: crun --run" cyan endl
		)
	)
	
	(	echo.
		echo Summary:
		echo   Total files compiled: %SUCCESS_COUNT%
		echo   Successful: %SUCCESS_COUNT%
		echo   Failed: %FAIL_COUNT%
		echo   Build finished: %date% %time%
		echo ===================================================
		echo.
	) >> "%LOG_FILE%"
goto :eof

:link
	REM Check missing source files.
	set "count=1"
	call :println "[BUILD] The following object files(s) will be linked:" yellow endl
	for %%i in ("%OBJ_DIR%\*.o") do (
		dir /s /b "src\%%~ni.c" "src\%%~ni.cpp" "src\%%~ni.cxx" "src\%%~ni.c++" >nul 2>&1 && (
			call :println "  !count!^) %%~i" yellow endl
			set /a "count+=1"
		) || (
			call :println "  [^!] The '%%~nxi' object file will be removed. Its source file is missing." brightyellow endl
			del /q /f "%%~i" >nul 2>&1
		)
	)
	
	REM Check for release mode so it starts with -O2.
	if /i "%CONFIG:~0,3%" == "-O2" (set "CONFIG=-s") else set "CONFIG="
	
	%CC% -o "%EXE_PATH%" "%OBJ_DIR%\*.o" %LDFLAGS% %CONFIG%
	if errorlevel 1 (
		call :println "[BUILD] Linking failed with exit code: !errorlevel!" red endl
		echo Linking failed.>> "%LOG_FILE%"
		exit /b 1
	)
	
	call :println "[BUILD] Linking completed successfully." green endl
	call :println "  [+] Executable generated at: %EXE_PATH%" green endl
	call :println "[BUILD] Build finished successfully." green endl
	if not defined run (
		echo. & call :println "[TIP] In order to run your program type: crun --run" cyan endl
	)
goto :eof

:run
	if defined BUILD echo.
	call :println "========== RUN ==========" cyan endl
	call :println "[RUN] Checking executable..." cyan endl
	if not exist "%EXE_PATH%" (
		call :println "[RUN] Executable not found. Did you forget to build?" red endl
		exit /b 1
	)
	
	setlocal DisableDelayedExpansion
		if not defined ARGS set "ARGS= "
		set "EXIT_CODE="
		set "START=%TIME%"
		
		call :println "[RUN] Launching: %EXE_PATH%..." cyan
		start "%EXE_NAME%" /wait cmd /v:on /c ""%EXE_PATH%" !ARGS! & set err=!errorlevel! & (cmd /c <nul set /p=[93mPress any key to close this window . . .[0m)& pause >nul & exit !err!"
		set "EXIT_CODE=%errorlevel%"
		set "END=%TIME%"
		
		REM == Print the exit status code ==
		echo. & echo.
		if %EXIT_CODE% EQU 0 (
			call :println "[DONE] Program ended with exit code: %EXIT_CODE%" green endl
		) else (
			call :println "[DONE] Program ended with exit code: %EXIT_CODE%" red endl
		)
		
		call :getExecutionDuration %START% %END%
	endlocal
goto :eof

:clean
	call :println "========== Clean ==========" blue endl
	call :println "[CLEAN] Cleaning BUILD directories..." blue endl

	set "EXIT_CODE=0"
	set "BUILD_DIRS=%OBJ_DIR%;%BIN_DIR%"

	for %%i in ("%BUILD_DIRS:;=" "%") do (
		if exist "%%~i" (
			call :println "  [CLEAN] Cleaning '%%~i'..." blue endl
			del /q /f "%%~i\*.*" >nul 2>&1
			
			dir /b "%%~i" 2>nul | findstr /C:"." && (
				call :println "    [^!] Could not fully clean '%%~i' (access denied)." red endl
				set "EXIT_CODE=1"
			) || (
				call :println "    [+] '%%~i' cleaned successfully." green endl
			)
		)
	)

	if %EXIT_CODE% EQU 0 (
		call :println "[CLEAN] Clean completed." green endl
	) else (
		call :println "[CLEAN] Cleaning build directories failed." red endl
	)
goto :eof

:help
    echo Create, build, and run a C/C++ project in an external command line window.
    echo.
    echo Usage: %~n0 [--new ^<name^> --lang ^<c^|cpp^>] [--build --lang ^<c^|cpp^>] [--cflags ^<"flags..."^>] [--ldflags ^<"flags..."^>]
    echo        [--smart-build] [--config ^<debug^|release^>] [--run] [--args ^<arguments...^>]
	echo        [--clean] [--clear] [--install] [--uninstall] [--update] [--version] [--help]
    echo.
    echo  --new ^<name^> --lang ^<c^|cpp^>  Create a new C/C++ project and exit.
    echo  --lang ^<c^|cpp^>               Select the language used to build the project.
    echo  --build --lang ^<c^|cpp^>       Compile the C/C++ project.
    echo  --smart-build                Compile and link only modified source files.
    echo  --cflags "flags..."          Additional compiler flags.
    echo  --ldflags "flags..."         Additional linker flags.
	echo  --config ^<debug^|release^>     Select build configuration (debug or release).
    echo  --run                        Run the compiled project.
    echo  --args ^<arguments...^>        Arguments to pass to the program. Make sure this option is the last one.
    echo  --clean                      Clean the build directories and exit.
    echo  --clear                      Clear the console screen at startup.
	echo  --install                    Install the MinGW-w64 (GCC) compiler.
	echo  --uninstall                  Uninstall the currently installed MinGW-w64 (GCC) compiler.
	echo  --update                     Update the CRun tool.
	echo  --version                    Print the CRun version and exit.
    echo  --help                       Display this help message and exit.
    echo.
    echo Examples:
    echo  crun --new example --lang c                Create a new C project named example.
    echo  crun --new HelloWorld --lang cpp           Create a new C++ project named HelloWorld.
    echo  crun --build --lang c                      Build the project only.
    echo  crun --build --lang c --run                Build and then run the project.
    echo  crun --build --lang c --cflags "-Wall -g"  Compile using extra compiler flags.
    echo        (e.g. -Wall enables all warnings, -g includes debug information).
    echo.
    echo  crun --build --lang c --ldflags "-lm"      Compile using extra linker flags (e.g. -lm links the math library).
    echo  crun --run                                 Run the built project only.
    echo  crun --run --args arg1 arg2                Run the built project with arguments.
    echo  crun --clean                               Remove build files.
goto :eof

REM === INSTALLATION ===
:installMinGW
	endlocal DisableDelayedExpansion
	setlocal
	set "URL="
	set "TEMP7Z=%tmp%\mingw-w64.7z"
	set "INSTDIR=%LOCALAPPDATA%\Programs"
	set "GCC_DIR="
	set "ARCH="
	set "CRT=%CRUN_DIR%\tools\curl-ca-bundle.crt"

	echo Checking system architecture...
	if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
		echo   You are using 64-bit operating system.
		set "URL=https://drive.usercontent.google.com/download?id=15r21jfjZT1q9DZfWS8A_OoMzJHLebHLR&confirm"
		set "ARCH=64"
		set "GCC_DIR=%INSTDIR%\mingw64"
	) else (
		echo   You are using 32-bit operating system.
		set "URL=https://drive.usercontent.google.com/download?id=1VOCwZI619mLthCFOS-V0PnREX5CRWtjL&confirm"
		set "ARCH=32"
		set "GCC_DIR=%INSTDIR%\mingw32"
	)
	
	timeout /t 2 /nobreak >nul 2>&1
	echo. & echo Checking for existing MinGW-w64 (GCC) installation...
	if exist "%GCC_DIR%" (
		echo   A GCC installation was found. & echo.
		
		<nul set /p=Do you want to reinstall it? [Y/n]: 
		choice /N /C NY
		if errorlevel 2 (
			echo. & echo Removing the existing GCC installation...
			rmdir /s /q "%GCC_DIR%" >nul 2>&1
			if exist "%GCC_DIR%" (
				echo   [^!] Failed to remove the existing GCC directory.
				exit /b 1
			) else (
				echo   [+] Existing GCC directory removed successfully.
			)
		) else if errorlevel 1 (
			echo   Installation cancelled by user.
			exit /b 0
		)
	)
	
	timeout /t 2 /nobreak >nul 2>&1
	echo. & echo Downloading the %ARCH%-bit MinGW-w64(GCC) package...
	"%CRUN_DIR%\tools\curl.exe" --cacert "%CRT%" --retry 5 --retry-delay 3 --retry-connrefused "%URL%" -o "%TEMP7Z%"
	if errorlevel 1 (
		echo. & echo [^!] Download failed. Exiting...
		echo   1^) Try downloading it manually from this URL:
		echo       %URL%
		echo   2^) Extract the downloaded file.
		echo   3^) Add the extracted 'bin' folder to your Path environment variable.
		exit /b 1
	)
	echo   [+] Download completed successfully.
	
	timeout /t 2 /nobreak >nul 2>&1
	echo. & echo Creating installation directory...
	mkdir "%INSTDIR%" >nul 2>&1
	if not exist "%INSTDIR%" (
		echo   [^!] directory creation failed. Exiting...
		exit /b 1
	)
	echo   [+] Directory created successfully.
	
	timeout /t 2 /nobreak >nul 2>&1
	echo. & echo Extracting MinGW-w64(GCC) package...
	"%CRUN_DIR%\tools\7za.exe" x -t7z "%TEMP7Z%" -o"%INSTDIR%" -bso0 -y
	if errorlevel 1 (
		echo   [^!] GCC extraction failed. Exiting...
		exit /b 1
	)
	echo   [+] Extraction completed successfully.
	
	timeout /t 2 /nobreak >nul 2>&1
	echo. & echo Removing temporary file...
	del /q /f "%TEMP7Z%" >nul 2>&1
	if exist "%TEMP7Z%" (
		echo [^!] failed to remove the temporary file.
	) else (
		echo   [+] Temporary file removed successfully.
	)
	
	timeout /t 2 /nobreak >nul 2>&1
	echo. & echo Adding MinGW-w64(GCC) to the Path environment variable...
	set "GCC_BIN_DIR=%GCC_DIR%\bin"
	set "NEW_PATH="
	set "KEY=HKCU\Environment"
		
	for /f "tokens=2,*" %%a in ('reg query "%KEY%" /v Path') do (
		set "NEW_PATH=%%b"
	)
	
	call set "RESULT=%%NEW_PATH:%GCC_BIN_DIR%=%%"
	if "%RESULT%"=="%NEW_PATH%" (
		reg add HKCU\Environment /v Path /t REG_EXPAND_SZ /d "%GCC_BIN_DIR%;%NEW_PATH%" /f >nul 2>&1
		if errorlevel 1 (
			echo   [^!] Failed to add GCC to the Path Environment variable.
		) else (
			echo   [+] GCC successfully added to the Path environment variable.
			
			echo. & echo Notifying Windows to refresh environment variables...
			call :updateEnv
		)
	) else (
		echo   [+] The GCC environment variable is already added.
	)
	echo. & echo [+] All setup is complete^!
	endlocal
	
	if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
		set "PATH=%PATH%;%LOCALAPPDATA%\Programs\mingw64\bin"
	) else (
		set "PATH=%PATH%;%LOCALAPPDATA%\Programs\mingw32\bin"
	)
		
	REM timeout /t 2 /nobreak >nul 2>&1
	echo. & <nul set /p=Verifying GCC installation...
	gcc --version 2>nul && (echo   [+] All done^!.) || (echo   [^!] An unknown error occurred^! & exit /b 1)
exit /b 0

REM === UNINSTALLATION ===
:uninstallMinGW
	setlocal
	set "GCC_DIR="
	
	if /i "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
		set "GCC_DIR=%LOCALAPPDATA%\Programs\mingw64"
	) else (
		set "GCC_DIR=%LOCALAPPDATA%\Programs\mingw32"
	)

	echo Checking if MinGW-w64(GCC) is installed...
	if not exist "%GCC_DIR%" (
		echo   [+] GCC is not installed. Nothing to uninstall.
		exit /b 0
	)

	echo. & echo Removing MinGW-w64(GCC) installation directory...
	rmdir /s /q "%GCC_DIR%" >nul 2>&1
	if exist "%GCC_DIR%" (
		echo   [^!] Failed to delete GCC directory. Please remove it manually.
		exit /b 1
	) else (
		echo   [+] GCC directory removed successfully.
	)

	echo. & echo Removing MinGW-w64(GCC) from Path environment variable...
	set "GCC_BIN_DIR=%GCC_DIR%\bin"
	set "KEY=HKCU\Environment"
	set "NEW_PATH="

	for /f "tokens=2,*" %%a in ('reg query "%KEY%" /v Path') do (
		set "NEW_PATH=%%b"
	)

	call set "RESULT=%%NEW_PATH:%GCC_BIN_DIR%=%%"
	if "%RESULT%" == "%NEW_PATH%" (
		echo   [+] GCC path not found in Path environment variable. Nothing to remove.
		exit /b 0
	) else (
		reg add "%KEY%" /v Path /t REG_EXPAND_SZ /d "%RESULT%" /f >nul 2>&1
		if errorlevel 1 (
			echo [^!] Failed to remove GCC path from the Path environment variable.
			exit /b 1
		) else (
			echo   [+] GCC removed from Path successfully.
			
			echo. & echo Notifying Windows to refresh environment variables...
			call :updateEnv
		)
	)
	
	echo. & echo [+] MinGW-w64^(GCC^) has been successfully uninstalled.
	endlocal
exit /b 0

:updateTool
	setlocal DisableDelayedExpansion
	set "CRUN_URL=https://drive.usercontent.google.com/download?id=1o2MjlUmB6SiTtLli5FxxVkymhHIr94tN&confirm"
	set "UPDATE_VERSION_URL=https://drive.usercontent.google.com/download?id=1FRV6efhm8ovoMAQsNiprdqR9XMJ0iYHd&confirm"
	set "CRUN_TMPFILE=%TEMP%\CRun%RANDOM%.exe"
	set "UPDATE_VERSION_TMPFILE=%TEMP%\crun_version%RANDOM%.txt"
	set "CRT=%CRUN_DIR%\tools\curl-ca-bundle.crt"
	
	echo Checking for updates...
	"%CRUN_DIR%\tools\curl.exe" --cacert "%CRT%" -s -f --retry 5 --retry-delay 3 --retry-connrefused "%UPDATE_VERSION_URL%" -o "%UPDATE_VERSION_TMPFILE%"
	if errorlevel 1 (
		echo.
		echo [^!] Unable to check for updates. An unknown error occurred.
		exit /b 1
	)
	
	set /p LATEST_VERSION=<"%UPDATE_VERSION_TMPFILE%"
	del /q /f "%UPDATE_VERSION_TMPFILE%" >nul 2>&1
	
	if /i "%CRUN_VERSION%"=="%LATEST_VERSION%" (
		echo.
		echo [+] CRun is already up to date. ^(version %CRUN_VERSION%^) 
		del /q /f "%UPDATE_VERSION_TMPFILE%" >nul 2>&1
		exit /b 0
	)
	
	echo.
	echo Update available^!
	echo   Installed version : %CRUN_VERSION%
	echo   Latest version    : %LATEST_VERSION%
	echo.
	
	<nul set /p="Would you like to update now? [Y/n]: "
	choice /n /c YN
	if %errorlevel% equ 2 (
		echo [^!] Updating canceled by user.
		exit /b 0
	)
	set "errorlevel=0"
	
	echo.
	echo Downloading update package...
	"%CRUN_DIR%\tools\curl.exe" --cacert "%CRT%" --retry 5 --retry-delay 3 --retry-connrefused "%CRUN_URL%" -o "%CRUN_TMPFILE%"
	if errorlevel 1 (
		echo [^!] Failed to download the update.
		exit /b 1
	)
	
    if exist "%CRUN_TMPFILE%" (
        echo [+] Update package downloaded successfully.
		
        rem Run uninstaller if present
        if exist "%CRUN_DIR%\uninstall.exe" (
            "%CRUN_DIR%\uninstall.exe" /S
        )
		
		echo.
        echo Applying update...
		
        rem Run the installer
        "%CRUN_TMPFILE%" /S
        if errorlevel 1 (
            echo [^!] Installation failed. The update could not be applied.
            exit /b 1
        )

        echo [+] Update installed successfully.
        echo.
        echo [+] CRun has been updated to version %LATEST_VERSION%.
		
		del /q /f "%CRUN_TMPFILE%" >nul 2>&1
    ) else (
        echo [^!] Update package is missing or failed to download.
        exit /b 1
    )
	endlocal
exit /b 0

:updateEnv
	if exist "%SystemRoot%\SysWOW64" (
		%SystemRoot%\SysWOW64\rundll32.exe "%CRUN_DIR%\tools\envNotify.dll",UpdateEnv
	) else (
		%SystemRoot%\System32\rundll32.exe "%CRUN_DIR%\tools\envNotify.dll",UpdateEnv
	)
goto :eof

:isExeLocked
	if exist "%~1" (
		2>nul (type nul >>"%~1") && exit /b 0 || exit /b 1
	)
exit /b 0

:getExecutionDuration
	set "START_TIME=%~1"
	set "END_TIME=%~2"
	
	if "%START_TIME:~0,1%" == " " (
		set "START_TIME=0%START_TIME:~1,6%"
	) else if "%START_TIME:~1,1%" == ":" (
		set "START_TIME=0%START_TIME%"
	)
	
	if "%END_TIME:~0,1%"   == " " (
		set "END_TIME=0%END_TIME:~1,6%"
	) else if "%END_TIME:~1,1%"   == ":" (
		set "END_TIME=0%END_TIME%"
	)
	
	REM Calculate HOUR, MINUTE, SECOND differences.
	set /a "HOUR=60%END_TIME:~0,2%   %% 60 - 60%START_TIME:~0,2% %% 60"
	set /a "MINUTE=60%END_TIME:~3,2% %% 60 - 60%START_TIME:~3,2% %% 60"
	set /a "SECOND=60%END_TIME:~6,2% %% 60 - 60%START_TIME:~6,2% %% 60"
	
	if %HOUR% LSS 0 (
		set /a "HOUR+=24"
	)
	if %MINUTE% LSS 0 (
		set /a "MINUTE+=60"
		set /a "HOUR-=1"
	)
	if %SECOND% LSS 0 (
		set /a "SECOND+=60"
		set /a "MINUTE-=1"
	)
	
	REM Prefix HOUR, MINUTE and SECOND with 0.
	set "HOUR=0%HOUR%"
	set "MINUTE=0%MINUTE%"
	set "SECOND=0%SECOND%"
	
	REM Extract last two digits.
	set "HOUR=%HOUR:~-2%"
	set "MINUTE=%MINUTE:~-2%"
	set "SECOND=%SECOND:~-2%"
	
	REM Print the time.
	call :println "[Execution Duration] %HOUR%:%MINUTE%:%SECOND%" cyan endl
goto :eof

:enableAnsicon
	setlocal
	set "arch=x86"
	set "version="
	
	if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "arch=x64"
	
	for /f "tokens=4,5 delims=. " %%i in ('ver') do set "version=%%i.%%j"
	
	if /i not "%version%"=="10.0" (
		"%CRUN_DIR%\tools\ansicon\%arch%\ansicon.exe" -p
		if errorlevel 1 (
			echo Failed to enable ANSICON for Windows older than Windows 10.
			exit /b 1
		)
	)
	endlocal
goto :eof

:println
	setlocal DisableDelayedExpansion
	set "TEXT=%~1"
	set "COLOR=%~2"
	set "ENDL=%~3"
	
	if /I "%COLOR%"=="red" set "COLOR=[91m"
	if /I "%COLOR%"=="green" set "COLOR=[38;5;46m"
	if /I "%COLOR%"=="yellow" set "COLOR=[38;5;226m"
	if /I "%COLOR%"=="brightyellow" set "COLOR=[93m"
	if /I "%COLOR%"=="orange" set "COLOR=[38;5;208m"
	if /I "%COLOR%"=="blue" set "COLOR=[94m"
	if /I "%COLOR%"=="magenta" set "COLOR=[38;5;201m"
	if /I "%COLOR%"=="cyan" set "COLOR=[38;5;51m"
	if /I "%COLOR%"=="pastelPurple" set "COLOR=[38;5;147m"
	
	if "%ENDL%" == "" goto :print
	
	echo %COLOR%%TEXT%[0m
exit /b 0

:print
	<nul set /p=%COLOR%%TEXT%[0m
exit /b 0
