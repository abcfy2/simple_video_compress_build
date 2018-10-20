#!/bin/bash
# 批量视频压制脚本for linux

help() {
    cat <<EOF
$0 [-h|--help] [--loglevel quiet|panic|fatal|error|warning|info|verbose|debug] [--nostats] [--h265] [--hwencoder encoder] [--sub] [--subenc charenc] [--subsuffix suffix] [--subdir /path/to/subdir] [--scale width:height] [--videocopy] [--audiocopy] [--samplerate <int>] [--opts "ffmpeg_opts"] [-d|--dir /path/to/output/dir/] video1 [video2 [... videon]]
-h|--help     Print this help
--h265        Use h265 instead of h264 (extremely slow but compressed size is very small. Experimental)
--hwencoder   Select one hardware encoder for encoding, default is using software. Avaliable encoders see below.
              NOTE: You should know which encoder is supporting your GPU first.
--sub         Enable subtitiles encoding. Matching order: ass > ssa > srt
--subenc      Set subtitles input character encoding. Only useful if not UTF-8. Useless if it's ass/ssa
--subsuffix   Suffix of subtitles file name. Do not append file extension, and support globbing.
              Valid arguments like _zh/tc*, etc. Default ""
--subdir      Directory of subtitles. Default is the same directory as video
--scale       Scale video. E.g 320:240,-1:720,-1:1080
--framerate   Set output video frame rates. E.g --framerate 25
--videocopy   Copy video stream. Thus the convert video args are all inoperative
--audiocopy   Copy audio stream. Thus the convert audio args are all inoperative
--samplerate  Sample rate of audio. E.g 44100,22500, etc. Default is the same as origin audio
--opts        Other ffmpeg output args
-j|join       Join all videos(use ffmpeg concat demuxer). All videos MUST BE the same encodings.
-d|--dir      Output director for all videos. Default is the same as every video
--loglevel    Set ffmpeg loglevel. quiet|panic|fatal|error|warning|info|verbose|debug
--nostats     Disable print encoding progress/statistics.

Avaliable hardware encoders for h264:
$(${FFMPEG} -encoders 2> /dev/null | grep 'h264_' | awk '{print $2}' | cut -d_ -f2)

Avaliable hardware encoders for h265:
$(${FFMPEG} -encoders 2> /dev/null | grep 'hevc_' | awk '{print $2}' | cut -d_ -f2)
EOF
}

FFMPEG="ffmpeg"
declare -a video_list

parse_args() {
    FFMPEG_PRE_OPTS="-hide_banner"
    while [ $# -gt 0 ]; do
        case "$1" in
        -h|--help)
            help
            exit
            ;;
        --h265)
            ENABLE_h265=1
            ;;
        --hwencoder)
            HWENCODER="$2"
            shift
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
        --framerate)
            FRAMERATE="$2"
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
        -j|--join)
            JOIN=1
            ;;
        -d|--dir)
            DIR="$2"
            shift
            ;;
        --loglevel)
            LOGLEVEL="$2"
            FFMPEG_PRE_OPTS="${FFMPEG_PRE_OPTS} -loglevel ${LOGLEVEL}"
            shift
            ;;
        --nostats)
            FFMPEG_PRE_OPTS="${FFMPEG_PRE_OPTS} -nostats"
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
    video_suffix="${video##*.}"
    video_base_name=$(basename "${video_prefix}")
    sub_dir="${SUBDIR:-$(dirname "${video}")}"
    sub_avaliable_extension="ass ssa srt"

    for sub_extension in $sub_avaliable_extension; do
        find "${sub_dir}" -mindepth 1 -maxdepth 1 \
            -iname \
            "${video_base_name:+$(echo "${video_base_name}" | sed -r 's@([].*?\\[])@\\\1@g')}*${SUBSUFFIX}.${sub_extension}" \
            2>/dev/null \
        | head -1 \
        | grep '.*' \
        && return
    done

    # 对于后缀为mkv的视频，检测是否有内嵌字幕
    if [ "${video_suffix,,}" = "mkv" ] && "${FFMPEG}" -i "$video" 2>&1 | grep -q 'Stream .*: Subtitle'; then
        echo "Find embedded subtitles in ${video}. So use it." >&2
        echo "${video}"
        return
    fi
}

get_subtitle_opts() {
    declare -a sub_opts
    subfile=$1
    sub_file_extension="${sub_file##*.}"

    sub_opts[${#sub_opts[@]}]="filename='${subfile//\'/\\\\\\\'}'"
    [ -n "${SUBENC}" ] && sub_opts[${#sub_opts[@]}]="charenc=${SUBENC}"
    echo subtitles=$(str_join : "${sub_opts[@]}")
}

convert_video() {
    if [ "$JOIN" = 1 ]; then
        OUTDIR=${DIR:-.}
        [ ! -d "${OUTDIR}" ] && mkdir -p "${OUTDIR}"
        tmp_list_file="${RANDOM}.txt"
        (for video in "${video_list[@]}"; do echo "file '${video}'"; done) > "${tmp_list_file}"
        set -x
        "${FFMPEG}" ${FFMPEG_PRE_OPTS} -y -f concat -safe 0 -i "${tmp_list_file}" $SCALE_OPTS $VIDEO_OPTS ${FRAMERATE_OPTS} ${SUB_OPTS:+-vf "${SUB_OPTS}"} $AUDIO_OPTS $FFMPEG_OPTS "${OUTDIR}/video_join.mp4"
        rm -f "${tmp_list_file}"
        set +x
    else
        for video in "${video_list[@]}"; do
            if [ "$ENABLE_SUB" = 1 ]; then
                sub_file=$(find_subtitle "${video}")
                [ -n "${sub_file}" ] \
                && SUB_OPTS=$(get_subtitle_opts "${sub_file}") \
                || warn "Could not find any subtitles for video '${video}'"
            fi
            
            VIDEO_NAME=$(basename "${video}")
            OUTDIR=${DIR:-$(dirname "${video}")}
            [ ! -d "${OUTDIR}" ] && mkdir -p "${OUTDIR}"
            set -x
            "${FFMPEG}" -y ${FFMPEG_PRE_OPTS} -i "$video" $SCALE_OPTS $VIDEO_OPTS ${FRAMERATE_OPTS} ${SUB_OPTS:+-vf "${SUB_OPTS}"} $AUDIO_OPTS $FFMPEG_OPTS "${OUTDIR}/${VIDEO_NAME%.*}_enc.mp4"
            set +x
        done
    fi
}

parse_args "$@"

selfpath="`dirname \"$0\"`"
# --crf 24 --preset 8 -r 6 -b 6 -i 1 --scenecut 60 -f 1:1 --qcomp 0.5 --psy-rd 0.3:0 --aq-mode 2 --aq-strength 0.8 --vf resize:960,540,,,,lanczos #小丸工具箱默参
#VIDEO_OPTS="-c:v libx264 -crf:v 24 -preset:v veryslow -x264opts me=umh:subme=7:no-fast-pskip:cqm=jvt -pix_fmt yuv420p" #视频编码参数(旧)
if [ "$VIDEOCOPY" = 1 ]; then
    VIDEO_OPTS="-c:v copy"
elif [ "${ENABLE_h265}" = 1 ]; then
    if [ -n "${HWENCODER}" ]; then
        VIDEO_OPTS="-c:v hevc_${HWENCODER}"
        [ "${HWENCODER}" = amf ] && VIDEO_OPTS="${VIDEO_OPTS} -quality quality -rc cqp"
        [ "${HWENCODER}" = nvenc ] && VIDEO_OPTS="${VIDEO_OPTS} -preset slow -profile main10 -rc constqp"
        [ "${HWENCODER}" = qsv ] && VIDEO_OPTS="${VIDEO_OPTS} -preset slower -load_plugin hevc_hw"
        [ "${HWENCODER}" = vaapi ] && FFMPEG_PRE_OPTS="${FFMPEG_PRE_OPTS} -hwaccel vaapi -hwaccel_output_format vaapi"
    else
        "${FFMPEG}" -codecs 2>/dev/null | grep -q libx265 \
        && VIDEO_OPTS="-c:v libx265 -preset slow -crf 28 -pix_fmt yuv420p10le" \
        || warn "FFmpeg does not compile with libx265, fallback with libx264 encoder."
    fi
fi

if [ -z "${VIDEO_OPTS}" ]; then
    if [ -n "${HWENCODER}" ]; then
        VIDEO_OPTS="-c:v h264_${HWENCODER}"
        [ "${HWENCODER}" = amf ] && VIDEO_OPTS="${VIDEO_OPTS} -quality quality -rc cqp"
        [ "${HWENCODER}" = nvenc ] && VIDEO_OPTS="${VIDEO_OPTS} -preset slow -rc constqp"
        [ "${HWENCODER}" = qsv ] && VIDEO_OPTS="${VIDEO_OPTS} -preset slower"
        [ "${HWENCODER}" = vaapi ] && FFMPEG_PRE_OPTS="${FFMPEG_PRE_OPTS} -hwaccel vaapi -hwaccel_output_format vaapi"
    else
        VIDEO_OPTS="-c:v libx264 -crf:v 20 -preset 8 -subq 7 -refs 6 -bf 6 -keyint_min 1 -sc_threshold 60 -deblock 1:1 -qcomp 0.5 -psy-rd 0.3:0 -aq-mode 2 -aq-strength 0.8 -pix_fmt yuv420p"
    fi
fi

[ -n "$SCALE" ] && SCALE_OPTS="-vf scale=$SCALE"
[ -n "${FRAMERATE}" ] && FRAMERATE_OPTS="-r ${FRAMERATE}"

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
