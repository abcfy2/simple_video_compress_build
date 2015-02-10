@cd /d %~dp0
:start
@IF "%~1"=="" GOTO :end
@set input=%1
@set output=%~dpn1_enc

set FFMPEG="ffmpeg"
::��Ƶ�������
set VIDEO_OPTS=-c:v libx264 -crf:v 24 -preset:v veryslow -x264opts me=umh:subme=7:no-fast-pskip:cqm=jvt 
::��Ƶ�������
set AUDIO_OPTS=-c:a libfdk_aac -profile:a aac_he_v2 -vbr 2 
::������Ƶ
::set SCALE_OPTS="-vf scale=-1:720" 

%FFMPEG% -y -i %input% %SCALE_OPTS% %VIDEO_OPTS% %AUDIO_OPTS% %output%.mp4

:next
@shift /1
@goto start

:end
@pause
