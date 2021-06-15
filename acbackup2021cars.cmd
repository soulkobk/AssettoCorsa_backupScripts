@echo off
setlocal enableextensions enabledelayedexpansion

:: change these paths...

set sourcedir="D:\Games\Steam\steamapps\common\assettocorsa\content\cars"
set zipdir="G:\AssettoCorsaBackups"

:: don't change anything below!

:: script updated 20210614 - added in :CRCFAIL and :UPDATE routines
:: script updated 20210615 - added in :MAINSTART, :LOOPSTART, :LOOPSTOP, :LOOPRESULT routines

call :MAINSTART

set filenameext="zip"

set "sourcedir=%sourcedir:"=%"
set "zipdir=%zipdir:"=%"
set "filenameext=%filenameext:"=%"

set PATH=%PATH%;C:\Program Files\7-Zip;C:\Program Files Portable\zipcomp

for /f %%a in ('"prompt $H&for %%b in (1) do rem"') do set "BS=%%a"

set count=0
for /f "delims=" %%a in ('dir /a:d /b "%sourcedir%\*"') do (
	set /a count+=1
)
set "countdisplaytotal=000!count!"
set "countdisplaytotal=!countdisplaytotal:~-4!

set count=0
for /f "delims=" %%a in ('dir /b /o-d "%sourcedir%"') do (
	call :LOOPSTART
	set /a count+=1
    set "countdisplay=000!count!"
    set "countdisplay=!countdisplay:~-4!
	set "dirname=%%~na"
	set "filename=%%~a"
	echo [!countdisplay!^/!countdisplaytotal!] processing folder !filename!...
	for /f "delims=" %%b in ('dir /b "%zipdir%" ^| findstr "^^!filename!.!filenameext!"') do (
		set "zipfile=%%~b"
	)
	if not [!zipfile!]==[] (
		set "zipfile=!filename!.!filenameext!"
		call :VERIFY
		call :UPDATE
		call :COMPARE
	) else (
		set "zipfile=!filename!.!filenameext!"
		call :7ZFILE
	)
	set "zipfile="
	call :LOOPSTOP
	call :LOOPRESULT
	echo.
)

:UPDATE
	for /f "delims=" %%d in ('7z u "!zipdir!\!zipfile!" "%sourcedir%\!filename!\*" 2^>^&1 ^| findstr "Files read from disk:" ^| findstr /R [1-999999]') do (
		set "zipupdateverification=%%~d"
	)
	if not [!zipupdateverification!]==[] (
		echo | set/p=.%BS%            ^? updating !filenameext! file !zipfile!...
		echo  UPDATED
	)
	set "zipupdateverification="
	goto :EOF

:VERIFY
	if [!zipfile!]==[] (
		echo        ^^! BACKUP COMPLETE, SEE !zipdir!
		pause
		exit /b
	)
	echo | set/p=.%BS%            ^? verifying !filenameext! file !zipfile!...
	for /f "delims=" %%d in ('7z t "!zipdir!\!zipfile!" 2^>^&1 ^| findstr "Everything is Ok"') do (
		set "zipfileverification=%%~d"
	)
	if not [!zipfileverification!]==[] (
		echo  PASSED
	) else (
		call :CRCFAIL
	)
	set "zipfileverification="
	goto :EOF
	
:CRCFAIL
	del /f "!zipdir!\!filename!.!filenameext!" >nul 2>&1
	echo  CRC FAIL
	call :7ZFILE
	goto :EOF
	
:COMPARE
	echo | set/p=.%BS%            ^? comparing contents of !filename! with !zipfile!...
	for /f "delims=" %%c in ('zipcomp "!zipdir!\!zipfile!" "%sourcedir%\!filename!" 2^>^&1 ^| findstr /R "NONE SIZE CRC"') do (
		set "zipfilehasdifference=%%~c"
	)
	if not [!zipfilehasdifference!]==[] (
		call :MISMATCH
	) else (
		echo  MATCHED
	)
	set "zipfilehasdifference="
	goto :EOF
	
:MISMATCH
	del /f "!zipdir!\!filename!.!filenameext!" >nul 2>&1
	echo  MISMATCH
	call :7ZFILE
	goto :EOF

:7ZFILE
	echo | set/p=.%BS%            ^? compressing !filenameext! file !zipfile!...
	7z a "%zipdir%\!zipfile!" "%sourcedir%\!filename!\*" >nul 2>&1
	echo  COMPLETE
	call :VERIFY
	goto :EOF
	
:MAINSTART
	set MAINSTARTTIME=%TIME%
	for /f "usebackq tokens=1-4 delims=:., " %%f in (`echo %MAINSTARTTIME: =0%`) do set /a MAINSTART100S=1%%f*360000+1%%g*6000+1%%h*100+1%%i-36610100
	goto :EOF

:LOOPSTART
	set LOOPSTARTTIME=%TIME%
	for /f "usebackq tokens=1-4 delims=:., " %%f in (`echo %LOOPSTARTTIME: =0%`) do set /a START100S=1%%f*360000+1%%g*6000+1%%h*100+1%%i-36610100
	goto :EOF

:LOOPSTOP
	set LOOPSTOPTIME=%TIME%
	for /f "usebackq tokens=1-4 delims=:., " %%f in (`echo %LOOPSTOPTIME: =0%`) do set /a STOP100S=1%%f*360000+1%%g*6000+1%%h*100+1%%i-36610100
	if %STOP100S% LSS %START100S% set /a STOP100S+=8640000
	set /a LOOPTIME=%STOP100S%-%START100S%
	set LOOPTIMEPADDED=0%LOOPTIME%
	set /a TOTALTIME=%STOP100S%-%MAINSTART100S%
	set TOTALTIMEPADDED=0%TOTALTIME%
	goto :EOF

:LOOPRESULT
	set LOOPTIMERESULT=%LOOPTIME:~0,-2%.%LOOPTIMEPADDED:~-4%
	set TOTALTIMERESULTSEC=%TOTALTIME:~0,-2%.%TOTALTIMEPADDED:~-4%
	for /f %%a in ('powershell !TOTALTIMERESULTSEC! -gt 60') do set TOTALTIMESECGT60=%%a
	if %TOTALTIMESECGT60%==True (
		for /f %%b in ('powershell [math]::Round^(!TOTALTIMERESULTSEC!/60^,4^)') do set TOTALTIMERESULTMIN=%%b
		for /f %%c in ('powershell !TOTALTIMERESULTMIN! -gt 60') do set TOTALTIMEMINGT60=%%c
		if !TOTALTIMEMINGT60!==True (
			for /f %%d in ('powershell [math]::Round^(!TOTALTIMERESULTMIN!/60^,4^)') do set TOTALTIMERESULTHRS=%%d
			echo             ^? process time !LOOPTIMERESULT! SECONDS ^(!TOTALTIMERESULTHRS! HOURS TOTAL^)
		) else (
			echo             ^? process time !LOOPTIMERESULT! SECONDS ^(!TOTALTIMERESULTMIN! MINUTES TOTAL^)
		)

	) else (
		echo             ^? process time !LOOPTIMERESULT! SECONDS ^(!TOTALTIMERESULTSEC! SECONDS TOTAL^)
	)
	goto :EOF
