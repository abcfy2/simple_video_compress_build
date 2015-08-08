@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
cd /d %~dp0
set FFMPEG=ffmpeg
::��Ƶ�������
set VIDEO_OPTS=-c:v libx264 -crf:v 24 -preset:v veryslow -x264opts me=umh:subme=7:no-fast-pskip:cqm=jvt -pix_fmt yuv420p
::��Ƶ�������
set AUDIO_OPTS=-c:a libfdk_aac -vbr 2
::������Ƶ(����Ϊ����Ϊ720p����Ƶ��-1��������Ӧ)
::set SCALE_OPTS=-vf scale=-1:720
set videolist=%*
if not defined videolist set /P videolist=������Ҫת�����Ƶ·��,�����Ƶ�ո�ָ�(����ק��Ƶ�ļ����ն�): 

:start
for %%I in (%videolist%) do (
    set input=%%I
    set output=%%~dpnI_enc.mp4
    %FFMPEG% -y -i !input! %SCALE_OPTS% %VIDEO_OPTS% %AUDIO_OPTS% "!output!" || echo ת��ʧ��
)
echo ת����ɣ������ʧ�ܵ���ο�����Ĵ�����Ϣ���

:end
@pause
