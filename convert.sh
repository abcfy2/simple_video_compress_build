#!/bin/bash
# 批量视频压制脚本for linux

selfpath="`dirname \"$0\"`"
FFMPEG="ffmpeg"
VIDEO_OPTS="-c:v libx264 -crf:v 24 -preset:v veryslow -x264opts me=umh:subme=7:no-fast-pskip:cqm=jvt" #视频编码参数
AUDIO_OPTS="-c:a libfdk_aac -profile:a aac_he_v2 -vbr 2" #音频编码参数
#SCALE_OPTS="-vf scale=-1:720" #缩放视频

for video in "$@"
do
    "$FFMPEG" -y -i "$video" $SCALE_OPTS $VIDEO_OPTS $AUDIO_OPTS "${video%.*}_enc.mp4"
done
