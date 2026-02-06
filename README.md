# simple_video_compress_build

批量视频压制脚本，支持 Windows、Linux 和 macOS。

## Windows 环境

将 `ffmpeg.exe` 文件拷贝至项目目录下，或确保其在 `%PATH%` 路径中。

使用 `convert.bat` 脚本进行视频压制：

```batch
convert.bat [options] video1 [video2 ...]
```

### convert.bat 参数

```
-h, --help      显示帮助信息
-n              不覆盖已存在的文件
--format fmt    输出格式（默认：mp4）
--h265          使用 H.265/HEVC 编码
--opus          使用 Opus 音频编码
--hwencoder e   硬件编码器（nvenc/amf/qsv）
--sub           启用字幕压制（ass > ssa > srt）
--subenc enc    设置字幕输入字符编码
--subsuffix s   字幕文件名后缀
--scale WxH     缩放视频（如：-1:720）
--framerate fps 设置输出视频帧率
--videocopy     直接复制视频流（不重新编码）
--audiocopy     直接复制音频流（不重新编码）
-j, --join      合并多个视频
-o file         指定输出文件名
-d dir          指定输出目录
```

### 使用示例

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

### convert.sh 参数

```
-h|--help     显示帮助
-n            不覆盖已存在的文件（默认覆盖）
--format      指定输出格式（默认：mp4）
--h265        使用 H.265 替代 H.264（压缩率更高但较慢）
--opus        使用 Opus 替代 AAC 音频编码
--hwencoder   选择硬件编码器（见下方可用选项）
--sub         启用字幕压制（匹配顺序：ass > ssa > srt）
--subenc      设置字幕输入字符编码
--subsuffix   字幕文件名后缀
--subdir      字幕文件目录（默认：与视频同目录）
--scale       缩放视频（如：320:240, -1:720, -1:1080）
--framerate   设置输出视频帧率
--videocopy   复制视频流（忽略视频编码参数）
--audiocopy   复制音频流（忽略音频编码参数）
--samplerate  音频采样率（如：44100, 48000）
--opts        其他 ffmpeg 输出参数
-j|--join     合并所有视频（要求编码格式相同）
-o|--out      指定输出文件名
-d|--dir      指定输出目录
--loglevel    设置 ffmpeg 日志级别
--nostats     禁用编码进度统计
```

### 硬件编码器支持

**H.264 硬件编码器：**
- nvenc（NVIDIA）
- amf（AMD）
- qsv（Intel）
- vaapi

**H.265/HEVC 硬件编码器：**
- nvenc（NVIDIA）
- amf（AMD）
- qsv（Intel）
- vaapi

### 使用示例

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

## 注意事项

- `convert.sh` 支持更多高级功能（如字幕自动匹配）
- Windows 下推荐使用 `convert.bat`
- 两个脚本空参运行都将进入交互式模式（提示输入视频路径）
- 颜色高亮输出需要终端支持 ANSI 转义码
