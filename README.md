# simple_video_compress_build

批量视频压制脚本，支持 Windows、Linux 和 macOS。

## Windows 环境

将 `ffmpeg.exe` 文件拷贝至项目目录下，或确保其在 `%PATH%` 路径中。

使用 `convert.bat` 脚本进行视频压制：

```batch
convert.bat [options] video1 [video2 ...]
```

### 使用示例 (Bat)

```batch
:: 基本用法
convert.bat video.mp4

:: 使用 H.265 编码
convert.bat --h265 video.mp4

:: 缩放到 720p
convert.bat --scale -1:720 video.mp4

:: 使用 NVIDIA 硬件编码
convert.bat --hwencoder nvenc video.mp4

:: 合并多个视频
convert.bat -j part1.mp4 part2.mp4 part3.mp4
```

## Linux / macOS / Cygwin 环境

将 `ffmpeg` 文件赋予可执行权限，并确保其在 `$PATH` 路径中。

使用 `convert.sh` 脚本进行视频压制：

```bash
./convert.sh [options] video1 [video2 [...]]
```

### 使用示例 (Bash)

```bash
# 基本用法
./convert.sh video.mp4

# 使用 H.265 编码并压制字幕
./convert.sh --h265 --sub video.mkv

# 使用 NVIDIA 硬件编码器
./convert.sh --hwencoder nvenc -o output.mp4 input.mp4

# 合并多个视频
./convert.sh -j part1.mp4 part2.mp4 part3.mp4

# 缩放视频
./convert.sh --scale -1:1080 video.mp4

# 指定输出目录
./convert.sh -d /path/to/output video1.mp4 video2.mp4
```

## 脚本参数帮助

完整的脚本参数帮助可以通过 `-h | --help` 参数查看：

```sh
./convert.sh [-h|--help] [--loglevel quiet|panic|fatal|error|warning|info|verbose|debug] [--nostats] [--h265] [--hwencoder encoder] [--sub] [--subenc charenc] [--subsuffix suffix] [--subdir /path/to/subdir] [--scale width:height] [--videocopy] [--audiocopy] [--samplerate <int>] [--opts "ffmpeg_opts"] [-d|--dir /path/to/output/dir/] video1 [video2 [... videon]]
-h|--help     Print this help
-n            Do not override existing files (Override by default)
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
amf
nvenc
qsv
v4l2m2m
vaapi
vulkan

Avaliable hardware encoders for h265:
amf
nvenc
qsv
v4l2m2m
vaapi
vulkan
```

## 注意事项

- `convert.sh` 支持更多高级功能（如字幕自动匹配）
- Windows 下推荐使用 `convert.bat`
- 两个脚本空参运行都将进入交互式模式（提示输入视频路径）
- 颜色高亮输出需要终端支持 ANSI 转义码
