# simple_video_compress_build

windows环境下使用将`ffmpeg.exe`文件拷贝至项目目录下，或`%PATH%`的路径中，将视频文件拖拽到cmd文件上执行压制。

> **NOTE**: cmd脚本缺乏维护，本人实在无能力写复杂的cmd脚本，建议有条件的在mingw32/cygwin环境下运行，使用`convert.sh`脚本，将拥有更多灵活的转码参数(自动压制字幕功能`--sub`参数)

cygwin/linux/mac os环境下将`ffmpeg`文件给可执行权限，安装到`$PATH`路径中，使用`/path/to/convert.sh  /path/to/your_video(s)`执行

`convert.sh`脚本参考命令行：

```
./convert.sh [-h|--help] [--loglevel quiet|panic|fatal|error|warning|info|verbose|debug] [--nostats] [--h265] [--hwencoder encoder] [--sub] [--subenc charenc] [--subsuffix suffix] [--subdir /path/to/subdir] [--scale width:height] [--videocopy] [--audiocopy] [--samplerate <int>] [--opts "ffmpeg_opts"] [-d|--dir /path/to/output/dir/] video1 [video2 [... videon]]
-h|--help     Print this help
--format      Use specified output format instead of mp4. E.g: mkv, avi, and so on.
              NOTE: You should know which format supports your video and audio encoding.
--h265        Use h265 instead of h264 (extremely slow but compressed size is very small)
--opus        Use opus instead of aac for audio encoding
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
-j|--join     Join all videos(use ffmpeg concat demuxer). All videos MUST BE the same encodings.
-o|--out      Set specified out file name instead of "video_join.mp4" or "<name>_enc.mp4".
-d|--dir      Output director for all videos. Default is the same as every video
--loglevel    Set ffmpeg loglevel. quiet|panic|fatal|error|warning|info|verbose|debug
--nostats     Disable print encoding progress/statistics.

Avaliable hardware encoders for h264:
nvenc
omx
qsv
v4l2m2m
vaapi

Avaliable hardware encoders for h265:
nvenc
qsv
v4l2m2m
vaapi
```

空参运行将使用交互式模式运行。
