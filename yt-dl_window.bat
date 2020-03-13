@echo off

rem Constant variables
set locRoot=D:\ytdl\
set loc=%locRoot%youtube-dl.exe
set logfile=D:\ytdl\downloads.log

rem File-related variables
rem set outputFile=-o "output/%%(artist)s - %%(track)s  %%(id).%%(ext)s"
set outputFile=-o "%locRoot%output/%%(title)s.%%(ext)s"
set outputPlaylist=-o "%locRoot%output/%%(playlist)s/%%(playlist_index)s - %%(title)s.%%(ext)s"

rem Other variables
set options=--geo-bypass -x --audio-format "wav" --add-metadata
rem set options=--geo-bypass -o "output/%%(artist)s - %%(track)s (%%(id)).%%(ext)s" -x --audio-format "wav" --add-metadata



rem Ask for the video
set /p url=Enter url of the youtube video: 

rem Check if the specified URL refers to a playlist or a single music video.
echo %url% | find "playlist?"

if errorlevel 1 (
	echo Music file entered. Processing...
	set options=%options% %outputFile%
) else (
	echo Playlist entered. Processing...
	set options=%outputPlaylist% %options%
)

echo Arguments: %options% %url%
echo. && echo. && echo.
echo #########################
echo.


echo [%date% %time%] Downloading URL(s) %url% >> %logfile%
%loc% %options% %url%

pause
