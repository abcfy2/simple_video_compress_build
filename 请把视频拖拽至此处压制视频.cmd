@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
cd /d %~dp0
set FFMPEG=ffmpeg
::视频编码参数
::小丸工具箱默参
::--crf 24 --preset 8 -r 6 -b 6 -i 1 --scenecut 60 -f 1:1 --qcomp 0.5 --psy-rd 0.3:0 --aq-mode 2 --aq-strength 0.8 --vf resize:960,540,,,,lanczos
::旧参数
::set VIDEO_OPTS=-c:v libx264 -crf:v 24 -preset:v veryslow -x264opts me=umh:subme=7:no-fast-pskip:cqm=jvt -pix_fmt yuv420p
set VIDEO_OPTS=-c:v libx264 -crf:v 24 -preset 8 -subq 7 -refs 6 -bf 6 -keyint_min 1 -sc_threshold 60 -deblock 1:1 -qcomp 0.5 -psy-rd 0.3:0 -aq-mode 2 -aq-strength 0.8 -pix_fmt yuv420p
::音频编码参数
set AUDIO_OPTS=-c:a libfdk_aac -vbr 2
::缩放视频(范例为缩放为720p的视频，-1代表自适应)
::set SCALE_OPTS=-vf scale=-1:720
set videolist=%*
if not defined videolist set /P videolist=请输入要转码的视频路径,多个视频空格分割(可拖拽视频文件到终端): 

:start
for %%I in (%videolist%) do (
    set input=%%I
    set output=%%~dpnI_enc.mp4
    %FFMPEG% -y -i !input! %SCALE_OPTS% %VIDEO_OPTS% %AUDIO_OPTS% "!output!" || echo 转码失败
)
echo 转码完成，如果有失败的请参考上面的错误信息解决

:end
@pause