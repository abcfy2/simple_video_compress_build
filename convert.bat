@echo off
setlocal EnableDelayedExpansion

chcp 65001 >nul 2>&1
cd /d "%~dp0"

:: ANSI color codes (Windows 10 v1511+ and modern terminals)
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "RED=%ESC%[31m"
set "GREEN=%ESC%[32m"
set "YELLOW=%ESC%[33m"
set "RESET=%ESC%[0m"

set "FFMPEG=ffmpeg"
set "OVERRIDE_OPTS=-y"
set "OUTPUT_FORMAT=mp4"
set "FFMPEG_PRE_OPTS=-hide_banner"
set "video_count=0"

if "%~1"=="" (
  set /p "video_input=Please type the video path for converting. Multiple videos use space to split(Or you can drag and drop videos on this terminal): "
  if defined video_input (
    for %%V in (!video_input!) do (
      set /a video_count+=1
      set "v_!video_count!=%%~V"
    )
  )
  if !video_count! equ 0 (
    echo %RED%[ERROR] No video files specified.%RESET%
    goto :end
  )
  goto :start_process
)

if /I "%~1"=="-h" goto :help
if /I "%~1"=="--help" goto :help

goto :main

:help
echo %~nx0 [-h^|--help] [--loglevel quiet^|panic^|fatal^|error^|warning^|info^|verbose^|debug] [--nostats] [--h265] [--hwencoder encoder] [--sub] [--subenc charenc] [--subsuffix suffix] [--subdir /path/to/subdir] [--scale width:height] [--videocopy] [--audiocopy] [--samplerate ^<int^>] [--opts "ffmpeg_opts"] [-d^|--dir /path/to/output/dir/] video1 [video2 [... videon]]
echo -h^|--help     Print this help
echo -n            Do not override existing files (Override by default)
echo --format      Use specified output format instead of mp4. E.g: mkv, avi, and so on.
echo               NOTE: You should know which format supports your video and audio encoding.
echo --h265        Use h265 instead of h264 (extremely slow but compressed size is very small)
echo --opus        Use opus instead of aac for audio encoding
echo --hwencoder   Select one hardware encoder for encoding, default is using software. Avaliable encoders see below.
echo               NOTE: You should know which encoder is supporting your GPU first.
echo --sub         Enable subtitiles encoding. Matching order: ass ^> ssa ^> srt
echo --subenc      Set subtitles input character encoding. Only useful if not UTF-8. Useless if it's ass/ssa
echo --subsuffix   Suffix of subtitles file name. Do not append file extension, and support globbing.
echo               Valid arguments like _zh/tc*, etc. Default ""
echo --subdir      Directory of subtitles. Default is the same directory as video
echo --scale       Scale video. E.g 320:240,-1:720,-1:1080
echo --framerate   Set output video frame rates. E.g --framerate 25
echo --videocopy   Copy video stream. Thus the convert video args are all inoperative
echo --audiocopy   Copy audio stream. Thus the convert audio args are all inoperative
echo --samplerate  Sample rate of audio. E.g 44100,22500, etc. Default is the same as origin audio
echo --opts        Other ffmpeg output args
echo -j^|--join     Join all videos(use ffmpeg concat demuxer). All videos MUST BE the same encodings.
echo -o^|--out      Set specified out file name instead of "video_join.mp4" or "^<name^>_enc.mp4".
echo -d^|--dir      Output director for all videos. Default is the same as every video
echo --loglevel    Set ffmpeg loglevel. quiet^|panic^|fatal^|error^|warning^|info^|verbose^|debug
echo --nostats     Disable print encoding progress/statistics.
echo.
echo Avaliable hardware encoders for h264:
for /f "tokens=2" %%a in ('%FFMPEG% -encoders 2^>nul ^| findstr "h264_"') do @for /f "tokens=2 delims=_" %%b in ("%%a") do @echo   %%b
echo.
echo Avaliable hardware encoders for h265:
for /f "tokens=2" %%a in ('%FFMPEG% -encoders 2^>nul ^| findstr "hevc_"') do @for /f "tokens=2 delims=_" %%b in ("%%a") do @echo   %%b
goto :end

:main
set VIDEO_OPTS=-c:v libx264 -crf:v 20 -preset 8 -subq 7 -refs 6 -bf 6 -keyint_min 1 -sc_threshold 60 -deblock 1:1 -qcomp 0.5 -psy-rd 0.3:0 -aq-mode 2 -aq-strength 0.8 -pix_fmt yuv420p
set AUDIO_OPTS=-c:a aac -strict -2 -q:a 0.5
set join_mode=0

:parse_args
if "%~1"=="" goto :process_args_done

if /I "%~1"=="-n" (
  set OVERRIDE_OPTS=-n
  shift
  goto :parse_args
)

if /I "%~1"=="--format" (
  set OUTPUT_FORMAT=%~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--h265" (
  set ENABLE_h265=1
  shift
  goto :parse_args
)

if /I "%~1"=="--opus" (
  set ENABLE_OPUS=1
  shift
  goto :parse_args
)

if /I "%~1"=="--hwencoder" (
  set HWENCODER=%~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--sub" (
  set ENABLE_SUB=1
  shift
  goto :parse_args
)

if /I "%~1"=="--subenc" (
  set SUBENC=%~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--subsuffix" (
  set SUBSUFFIX=%~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--subdir" (
  set SUBDIR=%~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--scale" (
  set SCALE=%~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--framerate" (
  set FRAMERATE=%~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--videocopy" (
  set VIDEOCOPY=1
  shift
  goto :parse_args
)

if /I "%~1"=="--audiocopy" (
  set AUDIOCOPY=1
  shift
  goto :parse_args
)

if /I "%~1"=="--samplerate" (
  set SAMPLE_RATE=%~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--opts" (
  set FFMPEG_OPTS=%~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="-j" (
  set join_mode=1
  shift
  goto :parse_args
)

if /I "%~1"=="--join" (
  set join_mode=1
  shift
  goto :parse_args
)

if /I "%~1"=="-o" (
  set OUT=%~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--out" (
  set OUT=%~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="-d" (
  set DIR=%~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--dir" (
  set DIR=%~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--loglevel" (
  set FFMPEG_PRE_OPTS=%FFMPEG_PRE_OPTS% -loglevel %~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--nostats" (
  set FFMPEG_PRE_OPTS=%FFMPEG_PRE_OPTS% -nostats
  shift
  goto :parse_args
)

:: Handle video files (support glob patterns like *.mp4)
set /a video_count=%video_count%+1
set v_%video_count%=%~1
shift
goto :parse_args

:process_args_done
:: Build video encoding options
call :build_video_opts
:: Build audio encoding options
call :build_audio_opts

goto :start_process

:build_video_opts
if "%VIDEOCOPY%"=="1" (
  set VIDEO_OPTS=-c:v copy
  goto :eof
)

if "%ENABLE_h265%"=="1" (
  if defined HWENCODER (
    set VIDEO_OPTS=-c:v hevc_%HWENCODER%
    if /I "%HWENCODER%"=="amf" set VIDEO_OPTS=!VIDEO_OPTS! -quality quality -rc cqp
    if /I "%HWENCODER%"=="nvenc" set VIDEO_OPTS=!VIDEO_OPTS! -preset slow -profile main10 -rc constqp
    if /I "%HWENCODER%"=="qsv" set VIDEO_OPTS=!VIDEO_OPTS! -preset slower -load_plugin hevc_hw
    if /I "%HWENCODER%"=="vaapi" (
      set FFMPEG_PRE_OPTS=!FFMPEG_PRE_OPTS! -vaapi_device /dev/dri/renderD128
      set VIDEO_OPTS=!VIDEO_OPTS! -b_depth 8 -qp 28
      set "FILTER_CHAIN=format=nv12,hwupload"
    )
    if /I "%HWENCODER%"=="vulkan" (
      set FFMPEG_PRE_OPTS=!FFMPEG_PRE_OPTS! -init_hw_device vulkan
      set VIDEO_OPTS=!VIDEO_OPTS! -qp 23
      set "FILTER_CHAIN=hwupload=derive_device=vulkan"
    )
  ) else (
    :: Check for libx265 support
    %FFMPEG% -codecs 2^>nul ^| findstr "libx265" ^>nul && (
      set VIDEO_OPTS=-c:v libx265 -x265-params min-keyint=5:scenecut=50:open-gop=0:rc-lookahead=40:lookahead-slices=0:subme=3:merange=57:ref=4:max-merge=3:no-strong-intra-smoothing=1:no-sao=1:selective-sao=0:deblock=-2,-2:ctu=32:rdoq-level=2:psy-rdoq=1.0:early-skip=0:rd=6 -crf 28 -preset medium -pix_fmt yuv420p10le
    ) || (
      echo %YELLOW%WARN: FFmpeg does not compile with libx265, fallback with libx264 encoder.%RESET%
    )
  )
  goto :eof
)

:: Default H.264
if defined HWENCODER (
  set VIDEO_OPTS=-c:v h264_%HWENCODER%
  if /I "%HWENCODER%"=="amf" set VIDEO_OPTS=!VIDEO_OPTS! -quality quality -rc cqp
  if /I "%HWENCODER%"=="nvenc" set VIDEO_OPTS=!VIDEO_OPTS! -preset slow -rc constqp
  if /I "%HWENCODER%"=="qsv" set VIDEO_OPTS=!VIDEO_OPTS! -preset slower
  if /I "%HWENCODER%"=="vaapi" (
    set FFMPEG_PRE_OPTS=!FFMPEG_PRE_OPTS! -vaapi_device /dev/dri/renderD128
    set VIDEO_OPTS=!VIDEO_OPTS! -b_depth 8 -qp 23
    set "FILTER_CHAIN=format=nv12,hwupload"
  )
  if /I "%HWENCODER%"=="vulkan" (
    set FFMPEG_PRE_OPTS=!FFMPEG_PRE_OPTS! -init_hw_device vulkan
    set VIDEO_OPTS=!VIDEO_OPTS! -qp 23
    set "FILTER_CHAIN=hwupload=derive_device=vulkan"
  )
)

goto :eof

:build_audio_opts
if "%AUDIOCOPY%"=="1" (
  set AUDIO_OPTS=-c:a copy
  goto :eof
)

if "%ENABLE_OPUS%"=="1" (
  set AUDIO_OPTS=-c:a libopus -b:a 64k -vbr on -strict -2
  goto :eof
)

:: Check for libfdk_aac
%FFMPEG% -codecs 2^>nul ^| findstr "libfdk_aac" ^>nul && (
  set AUDIO_OPTS=-c:a libfdk_aac -vbr 2
) || (
  echo %YELLOW%WARN: FFmpeg does not compile with libfdk_aac, fallback with aac encoder.%RESET%
  set AUDIO_OPTS=-c:a aac -strict -2 -q:a 0.5
)

if defined SAMPLE_RATE (
  set AUDIO_OPTS=!AUDIO_OPTS! -ar %SAMPLE_RATE%
)

goto :eof

:start_process
if %video_count% equ 0 (
  echo %RED%[ERROR] No videos to process.%RESET%
  goto :end
)

echo [INFO] Found %video_count% video(s)

if %join_mode% equ 1 goto :do_join

:: Normal processing
set success=0
set failed=0

for /L %%i in (1,1,%video_count%) do (
  call :process_one %%i
)

echo.
echo ========================================
if %failed% equ 0 (
  echo %GREEN%Done: %success% success, %failed% failed%RESET%
) else (
  echo Done: %success% success, %RED%%failed% failed%RESET%
)
echo ========================================
goto :end

:process_one
set idx=%1
set infile=
set fpath=
set fname=
set outdir=
set outfile=

call set infile=%%v_%idx%%%
for %%F in ("!infile!") do (
  set fpath=%%~fF
  set fname=%%~nF
)

echo.
echo [!idx!/%video_count%] Processing: !fname!

if not exist "!fpath!" (
  echo %YELLOW%[WARNING] File not found: !infile!%RESET%
  set /a failed=!failed!+1
  goto :eof
)

if defined DIR (
  set outdir=%DIR%
) else (
  for %%F in ("!infile!") do set outdir=%%~dpF
)

if not exist "!outdir!" mkdir "!outdir!"

if defined OUT (
  set outfile=%OUT%
) else (
  set outfile=!fname!_enc.%OUTPUT_FORMAT%
)

:: Build filter options
set FILTER_OPTS=
if defined FILTER_CHAIN (
  if defined SCALE (
    set FILTER_OPTS=-vf "!FILTER_CHAIN!,scale=!SCALE!"
  ) else (
    set FILTER_OPTS=-vf "!FILTER_CHAIN!"
  )
) else if defined SCALE (
  set FILTER_OPTS=-vf "scale=!SCALE!"
)

:: Build frame rate option
set FRAMERATE_OPTS=
if defined FRAMERATE (
  set FRAMERATE_OPTS=-r !FRAMERATE!
)

echo [CMD] %FFMPEG% -nostdin %OVERRIDE_OPTS% %FFMPEG_PRE_OPTS% -i "!fpath!" %VIDEO_OPTS% %FILTER_OPTS% %FRAMERATE_OPTS% %AUDIO_OPTS% %FFMPEG_OPTS% "!outdir!!outfile!"
echo.

%FFMPEG% -nostdin %OVERRIDE_OPTS% %FFMPEG_PRE_OPTS% -i "!fpath!" %VIDEO_OPTS% %FILTER_OPTS% %FRAMERATE_OPTS% %AUDIO_OPTS% %FFMPEG_OPTS% "!outdir!!outfile!"

if !ERRORLEVEL! equ 0 (
  echo %GREEN%[SUCCESS] !fname! -> !outfile!%RESET%
  set /a success=!success!+1
) else (
  echo %RED%[ERROR] Failed: !fname!%RESET%
  set /a failed=!failed!+1
)

goto :eof

:do_join
echo.
echo ========================================
echo [INFO] Join mode: merging %video_count% videos...
echo ========================================

if not defined DIR set DIR=%CD%
if not defined OUT set OUT=video_join.%OUTPUT_FORMAT%

if not exist "%DIR%" mkdir "%DIR%"

set concat_file=%TEMP%\concat_%RANDOM%.txt

:: Build concat file with full paths
set idx=0
:build_concat
set /a idx=%idx%+1
if %idx% gtr %video_count% goto :concat_done
call set curfile=%%v_%idx%%%
for %%F in ("!curfile!") do set fullpath=%%~fF
echo file '!fullpath!' >> "%concat_file%"
goto :build_concat
:concat_done

echo [INFO] Output: %DIR%\%OUT%

:: Build filter and framerate options for join
set FILTER_OPTS=
if defined FILTER_CHAIN set FILTER_OPTS=-vf "!FILTER_CHAIN!"
set FRAMERATE_OPTS=
if defined FRAMERATE set FRAMERATE_OPTS=-r !FRAMERATE!

%FFMPEG% -nostdin %OVERRIDE_OPTS% %FFMPEG_PRE_OPTS% -protocol_whitelist file,pipe -f concat -safe 0 -i "%concat_file%" %VIDEO_OPTS% %FILTER_OPTS% %FRAMERATE_OPTS% %AUDIO_OPTS% %FFMPEG_OPTS% "%DIR%\%OUT%"

if %ERRORLEVEL% equ 0 (
  echo %GREEN%[SUCCESS] Joined successfully!%RESET%
) else (
  echo %RED%[ERROR] Join failed!%RESET%
)

if exist "%concat_file%" del "%concat_file%"
goto :end

:end
echo.
pause
endlocal
