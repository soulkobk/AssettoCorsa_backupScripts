@echo off
setlocal enableextensions enabledelayedexpansion

:: change these paths...

set sourcedir="D:\Games\Steam\steamapps\common\assettocorsa\content\cars"
set zipdir="G:\AssettoCorsaBackupsNew"

:: don't change anything below!

set filenameext="zip"

set "sourcedir=%sourcedir:"=%"
set "zipdir=%zipdir:"=%"
set "filenameext=%filenameext:"=%"

set PATH=%PATH%;C:\Program Files\7-Zip;C:\Program Files Portable\zipcomp

for /f "delims=" %%a in ('dir /b /o- "%sourcedir%"') do (
	set "dirname=%%~na"
	set "filename=%%~a"
	echo [PROCESSING CAR] !filename!
	for /f "delims=" %%b in ('dir /b "%zipdir%" ^| findstr "^^!filename!.!filenameext!"') do (
		set "zipfile=%%~b"
	)
	if not [!zipfile!]==[] (
		REM echo     ^? found existing !filenameext! file !zipfile!, checking verification...
		echo     ^? verifying existing !filenameext! file !zipfile!...
		for /f "delims=" %%d in ('7z t "!zipdir!\!filename!.!filenameext!" 2^>^&1 ^| findstr "Everything is Ok"') do (
			set "zipfileverification=%%~d"
		)
		if not [!zipfileverification!]==[] (
			echo     ^+ !filenameext! file has passed verification...
		) else (
			echo     ^^! !filenameext! file has failed verification, recompressing...
			del /f "!zipdir!\!filename!.!filenameext!" >nul 2>&1
			7z a "%zipdir%\!filename!.!filenameext!" "%sourcedir%\!filename!\*" >nul 2>&1
		)
		for /f "delims=" %%c in ('zipcomp "!zipdir!\!zipfile!" "%sourcedir%\!filename!" 2^>^&1 ^| findstr /R "NONE SIZE CRC"') do (
			set "zipfilehasdifference=%%~c"
		)
		if not [!zipfilehasdifference!]==[] (
			echo     ^^! !filenameext! file has differences, updating...
			del /f "!zipdir!\!zipfile!" >nul 2>&1
			7z a "%zipdir%\!zipfile!" "%sourcedir%\!filename!\*" >nul 2>&1
		) else (
			echo     ^- !filenameext! file has no differences, skipping...
		)
	) else (
		echo     ^^! !filenameext! file is missing, compressing...
		7z a "%zipdir%\!filename!.!filenameext!" "%sourcedir%\!filename!\*" >nul 2>&1
		echo     ^? verifying newly compressed !filenameext! file !filename!.!filenameext!...
		REM for /f "delims=" %%d in ('zipcomp "!zipdir!\!filename!.!filenameext!" "%sourcedir%\!filename!" 2^>^&1 ^| findstr /R "NONE SIZE CRC"') do (
			REM set "zipfileverification=%%~d"
		REM )
		for /f "delims=" %%d in ('7z t "!zipdir!\!filename!.!filenameext!" 2^>^&1 ^| findstr "Everything is Ok"') do (
			set "zipfileverification=%%~d"
		)
		if not [!zipfileverification!]==[] (
			echo     ^+ !filenameext! file has passed verification, finishing...
		) else (
			echo     ^^! !filenameext! file has failed verification, recompressing...
			del /f "!zipdir!\!filename!.!filenameext!" >nul 2>&1
			7z a "%zipdir%\!filename!.!filenameext!" "%sourcedir%\!filename!\*" >nul 2>&1
		)
	)
	echo.
	set "zipfile="
	set "zipfilehasdifference="
	set "zipfileverification="
	REM pause
	REM exit /b
)
