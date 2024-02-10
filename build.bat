@echo off
setlocal

rem get current folder name
for %%I in (.) do set CurrDirName=%%~nxI

rem Set default command
set "commands="

if "%1" == "" (
    rem if %1 is blank there were no arguments. Show how to use this batch
    echo Usage: %0 [option]
    echo   -c compile
    echo   -f flash .sof only, volatile
    echo   -p program .pof configuration img, perminant
    exit /b
)

if "%1" == "-h" (
    rem if %1 is blank there were no arguments. Show how to use this batch
    echo Usage: %0 [option]
    echo   -c compile
    echo   -f flash .sof only, volatile
    echo   -p program .pof configuration img, perminant
    exit /b
)

rem Process command-line arguments
:parse_args
if "%~1"=="-c" (
    set "commands=compile %commands%" 
    shift
    goto :parse_args
)
if "%~1"=="-f" (
    set "commands=%commands% flash_sof"
    shift
    goto :parse_args
)
if "%~1"=="-p" (
    set "commands=%commands% flash_pof"
    shift
    goto :parse_args
)

rem Execute Quartus Prime commands based on the selected commands
for %%c in (%commands%) do (
    rem echo %%c
    if "%%c"=="compile" (
        quartus_sh --flow compile %CurrDirName%
    ) else if "%%c"=="flash_sof" (
        quartus_pgm -z --mode=jtag --operation="p;output_files\%CurrDirName%.sof"
    ) else if "%%c"=="flash_pof" (
        quartus_pgm -z --mode=jtag --operation="p;output_files\%CurrDirName%.pof"
    ) else (
        echo Invalid command: %%c
        exit /b 1
    )
)

endlocal