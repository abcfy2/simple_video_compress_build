#!/bin/bash
# 批量视频压制脚本for linux

selfpath="`dirname \"$0\"`"
FFMPEG="ffmpeg"
VIDEO_OPTS="-c:v libx264 -crf:v 24 -preset:v veryslow -x264opts me=umh:subme=7:no-fast-pskip:cqm=jvt -pix_fmt yuv420p" #视频编码参数
AUDIO_OPTS="-c:a libfdk_aac -vbr 2" #音频编码参数
#SCALE_OPTS="-vf scale=-1:720" #缩放视频

if [[ $# -eq 0 ]]; then
    read -p "请输入要转码的视频路径,多个视频请用空格分割(可拖拽视频进入终端): " str
    video_list=("${str[@]}")
else
    video_list=("$@")
fi

for video in "${video_list[@]}"
do
    "$FFMPEG" -y -i "$video" $SCALE_OPTS $VIDEO_OPTS $AUDIO_OPTS "${video%.*}_enc.mp4"
done
