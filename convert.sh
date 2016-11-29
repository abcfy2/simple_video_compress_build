#!/bin/bash
# 批量视频压制脚本for linux

help() {
    cat <<EOF
$0 [-h|--help] [--sub] [--subenc charenc] [--subsuffix suffix] [--subdir /path/to/subdir] [--scale width:height] [--videocopy] [--audiocopy] [--opts "ffmpeg_opts"] video1 [video2 [... videon]]
-h|--help   打印帮助
--sub       启用字幕,会自动按照ass-ssa-srt的优先级进行匹配
--subenc    字幕文件的编码,只有不是UTF-8才需要指定，ass/ssa不需要
--subsuffix 字幕后缀,不用带扩展名。如_zh,_cn等。默认""
--subdir    字幕所在路径,默认和视频在同一目录下
--scale     缩放视频。如320:240,-1:720,-1:1080
--videocopy 不转码视频
--audiocopy 不转码音频
--opts      其他ffmpeg的输出参数
EOF
}

declare -a video_list

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
        -h|--help)
            help
            exit
            ;;
        --sub)
            ENABLE_SUB=1
            ;;
        --subenc)
            SUBENC="$2"
            shift
            ;;
        --subsufix)
            SUBSUFFIX="$2"
            shift
            ;;
        --subdir)
            SUBDIR="$2"
            shift
            ;;
        --scale)
            SCALE="$2"
            shift
            ;;
        --videocopy)
            VIDEOCOPY=1
            ;;
        --audiocopy)
            AUDIOCOPY=1
            ;;
        --opts)
            FFMPEG_OPTS="$2"
            shift
            ;;
        *)
            video_list[${#video_list[@]}]="$1"
            ;;
    esac
    shift
    done
}

# 打印警告信息
warn() {
    echo -e '\033[1;33m'WARN: "$1" '\033[0m' >&2
}

# join字符串
str_join() {
    delim="$1"      # join delimiter
    shift
    oldIFS=$IFS   # save IFS, the field separator
    IFS=$delim
    result="$*"
    IFS=$oldIFS   # restore IFS
    echo "$result"
}

# 找到对应的字幕文件
find_subtitle() {
    video="$1"
    video_prefix="${video%.*}"
    video_base_name=$(basename "${video_prefix}")
    sub_dir="${SUBDIR:-$(dirname "${video}")}"
    sub_avaliable_extension="ass ssa srt"

    for sub_extension in $sub_avaliable_extension; do
        find "${sub_dir}" -mindepth 1 -maxdepth 1 -iname "${video_base_name}*${SUBSUFFIX}.${sub_extension}" 2>/dev/null \
        | head -1 \
        | grep '.*' \
        && break
    done
}

get_subtitle_opts() {
    declare -a sub_opts
    subfile=$1
    sub_file_extension="${sub_file##*.}"

    if [ "${sub_file_extension,,}" = ass ]; then
        echo "ass=${subfile//\'/\\\\\\\'}"
    else
        sub_opts[${#sub_opts[@]}]="filename=${subfile//\'/\\\\\\\'}"
        [ -n "${SUBENC}" ] && sub_opts[${#sub_opts[@]}]="charenc=${SUBENC}"
        echo subtitles=$(str_join : "${sub_opts[@]}")
    fi
}

convert_video() {
    for video in "${video_list[@]}"; do
        if [ "$ENABLE_SUB" = 1 ]; then
            sub_file=$(find_subtitle "${video}")
            [ -n "${sub_file}" ] \
            && SUB_OPTS=$(get_subtitle_opts "${sub_file}") \
            || warn " Could not find any subtitles for video '${video}'"
        fi

        "$FFMPEG" -y -i "$video" $SCALE_OPTS $VIDEO_OPTS ${SUB_OPTS:+-vf "${SUB_OPTS}"} $AUDIO_OPTS $FFMPEG_OPTS "${video%.*}_enc.mp4"
    done
}

parse_args "$@"

selfpath="`dirname \"$0\"`"
FFMPEG="ffmpeg"
# --crf 24 --preset 8 -r 6 -b 6 -i 1 --scenecut 60 -f 1:1 --qcomp 0.5 --psy-rd 0.3:0 --aq-mode 2 --aq-strength 0.8 --vf resize:960,540,,,,lanczos #小丸工具箱默参
#VIDEO_OPTS="-c:v libx264 -crf:v 24 -preset:v veryslow -x264opts me=umh:subme=7:no-fast-pskip:cqm=jvt -pix_fmt yuv420p" #视频编码参数(旧)
[ "$VIDEOCOPY" = 1 ] && VIDEO_OPTS="-c:v copy" || \
    VIDEO_OPTS="-c:v libx264 -crf:v 24 -preset 8 -subq 7 -refs 6 -bf 6 -keyint_min 1 -sc_threshold 60 -deblock 1:1 -qcomp 0.5 -psy-rd 0.3:0 -aq-mode 2 -aq-strength 0.8 -pix_fmt yuv420p" #视频编码参数
#SCALE_OPTS="-vf scale=-1:720" #缩放视频
[ -n "$SCALE" ] && SCALE_OPTS="-vf scale=$SCALE"

if [ "$AUDIOCOPY" = 1 ]; then
    AUDIO_OPTS="-c:a copy"
else
    if "${FFMPEG}" -codecs 2>/dev/null | grep -q libfdk_aac; then
        AUDIO_OPTS="-c:a libfdk_aac -vbr 2" #音频编码参数
    else
        warn "FFmpeg does not compile with libfdk_aac, fall back with aac encoder."
        AUDIO_OPTS="-c:a aac -strict -2 -aq 0.5" #音频编码参数
    fi
fi

if [[ ${#video_list[@]} -eq 0 ]]; then
    read -p "请输入要转码的视频路径,多个视频请用空格分割(可拖拽视频进入终端): " str
    video_list=("${str[@]}")
fi

convert_video
