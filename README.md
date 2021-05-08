# AssettoCorsa_backupScripts

these scripts will backup your \cars and \tracks to zip files (with verification).

how it works...


[1] it scans the assetto corsa directory (for cars or tracks) and parses each found directory.


[2] it then searches for an existing backup zip file (as per the path set within the top of the script).


[3.x] if an existing backup zip file is found...


[3.1] it verifies the existing zip file is valid.


[3.2] it then compares the current assetto corsa directory with the existing zip file (yes, compares the directory contents with the zip file contents... uses zipcomp).


[3.3] if the comparisson matches, it continues on to the next one. if the comparisson differs, it deletes the old backup zip file and creates a new one and then verifies the new zip file is valid.


[3.x] if existing backup zip file is NOT found...


[3.1] creates a new backup zip file.


[3.2] verifies new zip file is valid.


[4] it continues on the the next one.


these scripts require 7zip and zipcomp to function...


7zip = https://www.7-zip.org/


zipcomp = http://aluigi.altervista.org/mytoolz/zipcomp.zip


once installed, change the paths to them in the existing script files for 'set PATH='

cheers, soulkobk.
