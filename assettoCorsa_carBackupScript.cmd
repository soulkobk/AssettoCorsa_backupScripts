@echo off
setlocal enableextensions enabledelayedexpansion

:: change these paths...

set sourcedir="C:\Program Files (x86)\Steam\steamapps\common\assettocorsa\content\cars"
set destinationdir=F:\AssettoCorsaBackups"

set /a updateolderthanseconds=6*60*60

:: don't change anything below!

set "sourcedir=%sourcedir:"=%"
set "destinationdir=%destinationdir:"=%"

set PATH=%PATH%;C:\Program Files\7-Zip

if exist "%destinationdir%\backupLogTEMP.txt" (
	if not exist "%destinationdir%\backupLog.txt" (
		move /Y "%destinationdir%\backupLogTEMP.txt" "%destinationdir%\backupLog.txt" >nul 2>&1
	) else (
		del /F "%destinationdir%\backupLogTEMP.txt"
	)
)

set count=0
for /f "delims=" %%a in ('dir /a:d /b "%sourcedir%\*"') do (
	set /a count+=1
)
set "countdisplay=000!count!"
set "countdisplay=!countdisplay:~-4!
echo found [%countdisplay%] assetto corsa cars to backup...

pause

set count=0
for /f "delims=" %%a in ('dir /a:d /b "%sourcedir%\*"') do (
	set /a count+=1
    set "countdisplay=000!count!"
    set "countdisplay=!countdisplay:~-4!
	set "modname=%%~a"
	set /a "nowdate=!date:~10,4!!date:~7,2!!date:~4,2!"
	set /a "nowtime=!time:~0,2!!time:~3,2!!time:~6,2!"
	echo [!countdisplay!] processing !modname! ^^^(!nowdate! !nowtime!^^^)...

:: if zip already exists...
	if exist "%destinationdir%\!modname!.zip" (
:: initial check for zip file integrity
		echo        found zip file, doing integrity check...
		call :GETZIPINTEGRITY "%destinationdir%\!modname!.zip", zipresult
		if "!zipresult!"=="BAD" (
			REM echo        zip integrity bad, deleted file
			echo        zip integrity bad, recompressing !modname! to %destinationdir%\!modname!.zip
			del /f "%destinationdir%\!modname!.zip" >nul 2>&1
			call :GETUNIXTIME nowunix
			7z a "%destinationdir%\!modname!.zip" "%sourcedir%\!modname!\*" >nul 2>&1
			if exist "%destinationdir%\!modname!.zip" (
				for /f "tokens=1,* delims=:" %%a in ('7z h "%destinationdir%\!modname!.zip" -scrcSHA256 ^| findstr /n "^^" ^| findstr "^^9:"') do (
					set str=%%b: =%
					for /f "tokens=1,2,3,4,* delims= " %%a in ('echo !str!') do (
						set "sha256=%%a"
						set "filesize=%%b"
						set "filename=%%c"
					)
					echo !nowunix!,!nowdate!,!nowtime!,!sha256!,!modname!.zip>>%destinationdir%\backupLog.txt
					echo !nowunix!,!nowdate!,!nowtime!,!sha256!,!modname!.zip>>%destinationdir%\backupLogTEMP.txt
				)
			)
		) else (
			echo        zip integrity good, doing further checks...
		)
:: if backup log exists...		
		if exist "%destinationdir%\backupLog.txt" (
			REM echo        checking log file...
			for /f "delims=" %%a in ('findstr /C:!modname!.zip "%destinationdir%\backupLog.txt"') do set backupdetails=%%~a
			if not "!backupdetails!"=="" (
				REM echo        !modname!.zip log entry found...
				for /f "delims=, tokens=1,2,3,4,5" %%a in ('echo !backupdetails!') do (
					set "logunix=%%~a"
					set "logdate=%%~b"
					set "logtime=%%~c"
					set "loghash=%%~d"
					set "logfile=%%~e"
					call :GETUNIXTIME nowunix
					if "!logfile!"=="!modname!.zip" (
						set /a nowunixcompared=!nowunix!-!logunix!
						if !nowunixcompared! GTR %updateolderthanseconds% (
							echo        file older than %updateolderthanseconds% seconds...
							echo        updating !modname!.zip to %destinationdir%\!modname!.zip
							del /F "%destinationdir%\!modname!.zip"
							7z a "%destinationdir%\!modname!.zip" "%sourcedir%\!modname!\*" >nul 2>&1
							if exist "%destinationdir%\!modname!.zip" (
								for /f "tokens=1,* delims=:" %%a in ('7z h "%destinationdir%\!modname!.zip" -scrcSHA256 ^| findstr /n "^^" ^| findstr "^^9:"') do (
									set str=%%b: =%
									for /f "tokens=1,2,3,4,* delims= " %%a in ('echo !str!') do (
										set "sha256=%%a"
										set "filesize=%%b"
										set "filename=%%c"
									)
									echo !nowunix!,!nowdate!,!nowtime!,!sha256!,!modname!.zip>>%destinationdir%\backupLogTEMP.txt
								)
							)
						) else (
							if not "!zipresult!"=="BAD" (
								echo        skipped !modname!.zip
								echo !nowunix!,!logdate!,!logtime!,!loghash!,!logfile!>>%destinationdir%\backupLogTEMP.txt
							)
						)
					)
				)
			) else (
				echo        compressing !modname!.zip to %destinationdir%\!modname!.zip ^^^(log entry not found, processing backup^^^)
				del /F "%destinationdir%\!modname!.zip"
				call :GETUNIXTIME nowunix
				7z a "%destinationdir%\!modname!.zip" "%sourcedir%\!modname!\*" >nul 2>&1
				if exist "%destinationdir%\!modname!.zip" (
					for /f "tokens=1,* delims=:" %%a in ('7z h "%destinationdir%\!modname!.zip" -scrcSHA256 ^| findstr /n "^^" ^| findstr "^^9:"') do (
						set str=%%b: =%
						for /f "tokens=1,2,3,4,* delims= " %%a in ('echo !str!') do (
							set "sha256=%%a"
							set "filesize=%%b"
							set "filename=%%c"
						)
						echo !nowunix!,!nowdate!,!nowtime!,!sha256!,!modname!.zip>>%destinationdir%\backupLogTEMP.txt
					)
				)
			)
		) else (
			echo        unable to check log file
			echo        skipped !modname!.zip
			call :GETUNIXTIME nowunix
			if exist "%destinationdir%\!modname!.zip" (
				for /f "tokens=1,* delims=:" %%a in ('7z h "%destinationdir%\!modname!.zip" -scrcSHA256 ^| findstr /n "^^" ^| findstr "^^9:"') do (
					set str=%%b: =%
					for /f "tokens=1,2,3,4,* delims= " %%a in ('echo !str!') do (
						set "sha256=%%a"
						set "filesize=%%b"
						set "filename=%%c"
					)
					echo !nowunix!,!nowdate!,!nowtime!,!sha256!,!modname!.zip>>%destinationdir%\backupLogTEMP.txt
				)
			)
		)
	) else (
:: if zip file does NOT exit, compress it.
		echo        !modname!.zip doesn't exist...
		echo        compressing !modname! to %destinationdir%\!modname!.zip
		call :GETUNIXTIME nowunix
		7z a "%destinationdir%\!modname!.zip" "%sourcedir%\!modname!\*" >nul 2>&1
		if exist "%destinationdir%\!modname!.zip" (
			for /f "tokens=1,* delims=:" %%a in ('7z h "%destinationdir%\!modname!.zip" -scrcSHA256 ^| findstr /n "^^" ^| findstr "^^9:"') do (
				set str=%%b: =%
				for /f "tokens=1,2,3,4,* delims= " %%a in ('echo !str!') do (
					set "sha256=%%a"
					set "filesize=%%b"
					set "filename=%%c"
				)
				echo !nowunix!,!nowdate!,!nowtime!,!sha256!,!modname!.zip>>%destinationdir%\backupLog.txt
				echo !nowunix!,!nowdate!,!nowtime!,!sha256!,!modname!.zip>>%destinationdir%\backupLogTEMP.txt
			)
		)
	)
:: pause used in debug
REM pause
)

move /Y "%destinationdir%\backupLogTEMP.txt" "%destinationdir%\backupLog.txt" >nul 2>&1

echo.
echo [0000] finished processing
echo.
pause

:GETUNIXTIME
	setlocal enableextensions
	for /f %%x in ('wmic path win32_utctime get /format:list ^| findstr "="') do (
		set %%x)
	set /a z=(14-100%Month%%%100)/12, y=10000%Year%%%10000-z
	set /a ut=y*365+y/4-y/100+y/400+(153*(100%Month%%%100+12*z-3)+2)/5+Day-719469
	set /a ut=ut*86400+100%Hour%%%100*3600+100%Minute%%%100*60+100%Second%%%100
	endlocal & set "%1=%ut%" & goto :EOF
	
:GETZIPINTEGRITY
	set /a numfiles=0, isok=0, size=0, compressed=0
	set "result="
	for /f "tokens=*" %%x in ('7z t "%1" 2^> nul') do (
		echo %%x | find /i "ok" >nul && set /a isok=1
		echo %%x | find /i "files" >nul && for /f "tokens=2 delims=:" %%y in ("%%x") do set /a numfiles=%%y
		echo %%x | find /i "size" >nul && for /f "tokens=2 delims=:" %%y in ("%%x") do set /a size=%%y
		echo %%x | find /i "compressed" >nul && for /f "tokens=2 delims=:" %%y in ("%%x") do set /a compressed=%%y
	)
	if !isok! neq 0 if !numfiles! equ 0 if !size! neq 0 set /a numfiles=1
	if !isok! equ 0 (
		set "result=BAD"
	) else (
		if !numfiles! neq 0 (
			set "result=GOOD"
		) else (
			set "result=BAD"
		)
	)
	set "%2=!result!" & goto :EOF
