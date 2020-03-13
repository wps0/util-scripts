@echo off

set options=--geo-bypass -o "output/%%(artist)s - %%(track)s.%%(ext)s" -x --audio-format "wav" --add-metadata
set loc=youtube-dl.exe
set logfile=downloads.log
set url=%*

echo Arguments: %options% %url%
echo [%date% %time%] Downloading URL(s) %url% >> %logfile%

%loc% %options% %url%
