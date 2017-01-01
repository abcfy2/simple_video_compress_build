#!/bin/bash
# 批量视频压制脚本for linux

help() {
    cat <<EOF
$0 [-h|--help] [--x265] [--sub] [--subenc charenc] [--subsuffix suffix] [--subdir /path/to/subdir] [--scale width:height] [--videocopy] [--audiocopy] [--samplerate <int>] [--opts "ffmpeg_opts"] [-d|--dir /path/to/output/dir/] video1 [video2 [... videon]]
-h|--help     Print this help
--x265        Use libx265 instead of libx264 (extremely slow but compressed size is very small. Experimental)
--sub         Enable subtitiles encoding. Matching order: ass > ssa > srt
--subenc      Set subtitles input character encoding. Only useful if not UTF-8. Useless if it's ass/ssa
--subsuffix   Suffix of subtitles file name. Do not append file extension, and support globbing.
              Valid arguments like _zh/tc*, etc. Default ""
--subdir      Directory of subtitles. Default is the same directory as video
--scale       Scale video. E.g 320:240,-1:720,-1:1080
--videocopy   Copy video stream. Thus the convert video args are all inoperative
--audiocopy   Copy audio stream. Thus the convert audio args are all inoperative
--samplerate  Sample rate of audio. E.g 44100,22500, etc. Default is the same as origin audio
--opts        Other ffmpeg output args
-d|--dir      Output director for all videos. Default is the same as every video
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
        --x265)
            ENABLE_X265=1
            ;;
        --sub)
            ENABLE_SUB=1
            ;;
        --subenc)
            SUBENC="$2"
            shift
            ;;
        --subsuffix)
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
        --samplerate)
            SAMPLE_RATE="$2"
            shift
            ;;
        --opts)
            FFMPEG_OPTS="$2"
            shift
            ;;
        -d|--dir)
            DIR="$2"
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
        find "${sub_dir}" -mindepth 1 -maxdepth 1 \
            -iname \
            "${video_base_name:+$(echo ${video_base_name} | sed -r 's@([].*?\\[])@\\\1@g')}*${SUBSUFFIX}.${sub_extension}" \
            2>/dev/null \
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
        echo "ass='${subfile//\'/\\\\\\\'}'"
    else
        sub_opts[${#sub_opts[@]}]="filename='${subfile//\'/\\\\\\\'}'"
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
            || warn "Could not find any subtitles for video '${video}'"
        fi
        
        VIDEO_NAME=$(basename "${video}")
        DIR=${DIR:-$(dirname "${video}")}
        "$FFMPEG" -y -i "$video" $SCALE_OPTS $VIDEO_OPTS ${SUB_OPTS:+-vf "${SUB_OPTS}"} $AUDIO_OPTS $FFMPEG_OPTS "${DIR}/${VIDEO_NAME%.*}_enc.mp4"
    done
}

parse_args "$@"

selfpath="`dirname \"$0\"`"
FFMPEG="ffmpeg"
# --crf 24 --preset 8 -r 6 -b 6 -i 1 --scenecut 60 -f 1:1 --qcomp 0.5 --psy-rd 0.3:0 --aq-mode 2 --aq-strength 0.8 --vf resize:960,540,,,,lanczos #小丸工具箱默参
#VIDEO_OPTS="-c:v libx264 -crf:v 24 -preset:v veryslow -x264opts me=umh:subme=7:no-fast-pskip:cqm=jvt -pix_fmt yuv420p" #视频编码参数(旧)
if [ "$VIDEOCOPY" = 1 ]; then
    VIDEO_OPTS="-c:v copy"
elif [ "${ENABLE_X265}" = 1 ]; then
    "${FFMPEG}" -codecs 2>/dev/null | grep -q libx265 \
    && VIDEO_OPTS="-c:v libx265 -preset slower -crf 28 -pix_fmt yuv420p" \
    || warn "FFmpeg does not compile with libx265, fallback with libx264 encoder."
fi

VIDEO_OPTS=${VIDEO_OPTS:-"-c:v libx264 -crf:v 24 -preset 8 -subq 7 -refs 6 -bf 6 -keyint_min 1 -sc_threshold 60 -deblock 1:1 -qcomp 0.5 -psy-rd 0.3:0 -aq-mode 2 -aq-strength 0.8 -pix_fmt yuv420p"} #视频编码参数

[ -n "$SCALE" ] && SCALE_OPTS="-vf scale=$SCALE"

if [ "$AUDIOCOPY" = 1 ]; then
    AUDIO_OPTS="-c:a copy"
else
    if "${FFMPEG}" -codecs 2>/dev/null | grep -q libfdk_aac; then
        AUDIO_OPTS="-c:a libfdk_aac -vbr 2" #音频编码参数
    else
        warn "FFmpeg does not compile with libfdk_aac, fallback with aac encoder."
        AUDIO_OPTS="-c:a aac -strict -2 -aq 0.5" #音频编码参数
    fi
    
    [ -n "${SAMPLE_RATE}" ] && AUDIO_OPTS="${AUDIO_OPTS} -ar ${SAMPLE_RATE}"
fi

if [[ ${#video_list[@]} -eq 0 ]]; then
    read -p "Please type the video path for converting. Multiple videos use space to split(Or you can drag and drop videos on this terminal): " str
    video_list=("${str[@]}")
fi

convert_video
