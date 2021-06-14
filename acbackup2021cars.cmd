@echo off
setlocal enableextensions enabledelayedexpansion

:: change these paths...

set sourcedir="D:\Games\Steam\steamapps\common\assettocorsa\content\cars"
set zipdir="G:\AssettoCorsaBackups"

:: don't change anything below!

:: script updated 20210614 - added in :CRCFAIL and :UPDATE routines

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
set "countdisplay=000!count!"
set "countdisplay=!countdisplay:~-4!
echo found [%countdisplay%] assetto corsa cars to backup...

pause

set count=0
for /f "delims=" %%a in ('dir /b /o-d "%sourcedir%"') do (
	set /a count+=1
    set "countdisplay=000!count!"
    set "countdisplay=!countdisplay:~-4!
	set "dirname=%%~na"
	set "filename=%%~a"
	echo [!countdisplay!] processing folder !filename!...
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
	echo.
	set "zipfile="
)

:UPDATE
	echo | set/p=.%BS%       ^? updating !filenameext! file !zipfile!...
	for /f "delims=" %%d in ('7z u "!zipdir!\!zipfile!" "%sourcedir%\!filename!\*" 2^>^&1 ^| findstr "Files read from disk:" ^| findstr /R [1-999999]') do (
		set "zipupdateverification=%%~d"
	)
	if not [!zipupdateverification!]==[] (
		echo  UPDATED
	) else (
		echo  SKIPPED
	)
	set "zipupdateverification="
	goto :EOF

:VERIFY
	if [!zipfile!]==[] (
		echo        ^^! BACKUP COMPLETE, SEE !zipdir!
		pause
		exit /b
	)
	echo | set/p=.%BS%       ^? verifying !filenameext! file !zipfile!...
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
	echo | set/p=.%BS%       ^? comparing contents of !filename! with !zipfile!...
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
	echo | set/p=.%BS%       ^? compressing !filenameext! file !zipfile!...
	7z a "%zipdir%\!zipfile!" "%sourcedir%\!filename!\*" >nul 2>&1
	echo  COMPLETE
	call :VERIFY
	goto :EOF
