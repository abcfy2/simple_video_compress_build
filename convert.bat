@echo off
setlocal EnableExtensions EnableDelayedExpansion

chcp 65001 >nul 2>&1
cd /d "%~dp0"

for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "RED=%ESC%[31m"
set "GREEN=%ESC%[32m"
set "YELLOW=%ESC%[33m"
set "RESET=%ESC%[0m"

if not defined FFMPEG set "FFMPEG=ffmpeg"

set "OVERRIDE_OPTS=-y"
set "OUTPUT_FORMAT=mp4"
set "FFMPEG_PRE_OPTS=-hide_banner"
set "video_count=0"
set "JOIN=0"
set "SUCCESS_COUNT=0"
set "FAILED_COUNT=0"
set "SUBSUFFIX="
set "BASE_FILTERS="

if /I "%~1"=="-h" goto :help
if /I "%~1"=="--help" goto :help

if "%~1"=="" goto :prompt_videos

:parse_args
if "%~1"=="" goto :after_parse

if /I "%~1"=="-n" (
  set "OVERRIDE_OPTS=-n"
  shift
  goto :parse_args
)
if /I "%~1"=="--format" (
  if "%~2"=="" (call :error "Option --format requires a value." & goto :end)
  set "OUTPUT_FORMAT=%~2"
  shift
  shift
  goto :parse_args
)
if /I "%~1"=="--h265" (
  set "ENABLE_h265=1"
  shift
  goto :parse_args
)
if /I "%~1"=="--opus" (
  set "ENABLE_OPUS=1"
  shift
  goto :parse_args
)
if /I "%~1"=="--hwencoder" (
  if "%~2"=="" (call :error "Option --hwencoder requires a value." & goto :end)
  set "HWENCODER=%~2"
  shift
  shift
  goto :parse_args
)
if /I "%~1"=="--sub" (
  set "ENABLE_SUB=1"
  shift
  goto :parse_args
)
if /I "%~1"=="--subenc" (
  if "%~2"=="" (call :error "Option --subenc requires a value." & goto :end)
  set "SUBENC=%~2"
  shift
  shift
  goto :parse_args
)
if /I "%~1"=="--subsuffix" (
  if "%~2"=="" (call :error "Option --subsuffix requires a value." & goto :end)
  set "SUBSUFFIX=%~2"
  shift
  shift
  goto :parse_args
)
if /I "%~1"=="--subdir" (
  if "%~2"=="" (call :error "Option --subdir requires a value." & goto :end)
  set "SUBDIR=%~2"
  shift
  shift
  goto :parse_args
)
if /I "%~1"=="--scale" (
  if "%~2"=="" (call :error "Option --scale requires a value." & goto :end)
  set "SCALE=%~2"
  shift
  shift
  goto :parse_args
)
if /I "%~1"=="--framerate" (
  if "%~2"=="" (call :error "Option --framerate requires a value." & goto :end)
  set "FRAMERATE=%~2"
  shift
  shift
  goto :parse_args
)
if /I "%~1"=="--videocopy" (
  set "VIDEOCOPY=1"
  shift
  goto :parse_args
)
if /I "%~1"=="--audiocopy" (
  set "AUDIOCOPY=1"
  shift
  goto :parse_args
)
if /I "%~1"=="--samplerate" (
  if "%~2"=="" (call :error "Option --samplerate requires a value." & goto :end)
  set "SAMPLE_RATE=%~2"
  shift
  shift
  goto :parse_args
)
if /I "%~1"=="--opts" (
  if "%~2"=="" (call :error "Option --opts requires a value." & goto :end)
  set "FFMPEG_OPTS=%~2"
  shift
  shift
  goto :parse_args
)
if /I "%~1"=="-j" (
  set "JOIN=1"
  shift
  goto :parse_args
)
if /I "%~1"=="--join" (
  set "JOIN=1"
  shift
  goto :parse_args
)
if /I "%~1"=="-o" (
  if "%~2"=="" (call :error "Option -o requires a value." & goto :end)
  set "OUT=%~2"
  shift
  shift
  goto :parse_args
)
if /I "%~1"=="--out" (
  if "%~2"=="" (call :error "Option --out requires a value." & goto :end)
  set "OUT=%~2"
  shift
  shift
  goto :parse_args
)
if /I "%~1"=="-d" (
  if "%~2"=="" (call :error "Option -d requires a value." & goto :end)
  set "DIR=%~2"
  shift
  shift
  goto :parse_args
)
if /I "%~1"=="--dir" (
  if "%~2"=="" (call :error "Option --dir requires a value." & goto :end)
  set "DIR=%~2"
  shift
  shift
  goto :parse_args
)
if /I "%~1"=="--loglevel" (
  if "%~2"=="" (call :error "Option --loglevel requires a value." & goto :end)
  set "FFMPEG_PRE_OPTS=%FFMPEG_PRE_OPTS% -loglevel %~2"
  shift
  shift
  goto :parse_args
)
if /I "%~1"=="--nostats" (
  set "FFMPEG_PRE_OPTS=%FFMPEG_PRE_OPTS% -nostats"
  shift
  goto :parse_args
)

call :append_video "%~1"
shift
goto :parse_args

:prompt_videos
set /p "video_input=Please type the video path for converting. Multiple videos use space to split(Or you can drag and drop videos on this terminal): "
if not defined video_input (
  call :error "No video files specified."
  goto :end
)
for %%V in (%video_input%) do call :append_video "%%~V"

:after_parse
if !video_count! equ 0 (
  call :error "No videos to process."
  goto :end
)

if "!JOIN!"=="0" if !video_count! gtr 1 if defined OUT (
  call :warn "set -o|--out for multiple videos doesn't allow."
  set "OUT="
)

call :build_opts
if errorlevel 1 goto :end

if "!JOIN!"=="1" (
  call :do_join
  goto :end
)

call :convert_videos
goto :end

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
echo -j^|--join    Join all videos(use ffmpeg concat demuxer). All videos MUST BE the same encodings.
echo -o^|--out     Set specified out file name instead of "video_join.mp4" or "^<name^>_enc.mp4".
echo -d^|--dir     Output director for all videos. Default is the same as every video
echo --loglevel    Set ffmpeg loglevel. quiet^|panic^|fatal^|error^|warning^|info^|verbose^|debug
echo --nostats     Disable print encoding progress/statistics.
echo.
echo Avaliable hardware encoders for h264:
for /f "tokens=2" %%a in ('%FFMPEG% -hide_banner -encoders 2^>nul ^| findstr /I "h264_"') do @for /f "tokens=2 delims=_" %%b in ("%%a") do @echo   %%b
echo.
echo Avaliable hardware encoders for h265:
for /f "tokens=2" %%a in ('%FFMPEG% -hide_banner -encoders 2^>nul ^| findstr /I "hevc_"') do @for /f "tokens=2 delims=_" %%b in ("%%a") do @echo   %%b
goto :end

:append_video
set "arg=%~1"
if not defined arg exit /b 0

set "HAS_GLOB="
echo(%arg%| findstr /R "[*?]" >nul && set "HAS_GLOB=1"

if defined HAS_GLOB (
  set "MATCHED="
  for /f "delims=" %%G in ('dir /b /a-d /s "%arg%" 2^>nul') do (
    set /a video_count+=1
    call set "v_%%video_count%%=%%~fG"
    set "MATCHED=1"
  )
  if defined MATCHED exit /b 0
)

set /a video_count+=1
for %%F in ("%arg%") do call set "v_%%video_count%%=%%~fF"
exit /b 0

:build_opts
set "BASE_FILTERS="
set "VIDEO_OPTS="

if "!VIDEOCOPY!"=="1" (
  set "VIDEO_OPTS=-c:v copy"
) else (
  if "!ENABLE_h265!"=="1" (
    if defined HWENCODER (
      set "VIDEO_OPTS=-c:v hevc_%HWENCODER%"
      if /I "%HWENCODER%"=="amf" set "VIDEO_OPTS=!VIDEO_OPTS! -quality quality -rc cqp"
      if /I "%HWENCODER%"=="nvenc" set "VIDEO_OPTS=!VIDEO_OPTS! -preset slow -profile main10 -rc constqp"
      if /I "%HWENCODER%"=="qsv" set "VIDEO_OPTS=!VIDEO_OPTS! -preset slower -load_plugin hevc_hw"
      if /I "%HWENCODER%"=="vaapi" (
        set "FFMPEG_PRE_OPTS=!FFMPEG_PRE_OPTS! -vaapi_device /dev/dri/renderD128"
        set "VIDEO_OPTS=!VIDEO_OPTS! -b_depth 8 -qp 28"
        set "BASE_FILTERS=format=nv12,hwupload"
      )
      if /I "%HWENCODER%"=="vulkan" (
        set "FFMPEG_PRE_OPTS=!FFMPEG_PRE_OPTS! -init_hw_device vulkan"
        set "VIDEO_OPTS=!VIDEO_OPTS! -qp 23"
        set "BASE_FILTERS=hwupload=derive_device=vulkan"
      )
    ) else (
      %FFMPEG% -hide_banner -codecs 2>nul | findstr /I "libx265" >nul
      if not errorlevel 1 (
        set "VIDEO_OPTS=-c:v libx265 -x265-params min-keyint=5:scenecut=50:open-gop=0:rc-lookahead=40:lookahead-slices=0:subme=3:merange=57:ref=4:max-merge=3:no-strong-intra-smoothing=1:no-sao=1:selective-sao=0:deblock=-2,-2:ctu=32:rdoq-level=2:psy-rdoq=1.0:early-skip=0:rd=6 -crf 28 -preset medium -pix_fmt yuv420p10le"
      ) else (
        call :warn "FFmpeg does not compile with libx265, fallback with libx264 encoder."
      )
    )
  )
)

if not defined VIDEO_OPTS (
  if defined HWENCODER (
    set "VIDEO_OPTS=-c:v h264_%HWENCODER%"
    if /I "%HWENCODER%"=="amf" set "VIDEO_OPTS=!VIDEO_OPTS! -quality quality -rc cqp"
    if /I "%HWENCODER%"=="nvenc" set "VIDEO_OPTS=!VIDEO_OPTS! -preset slow -rc constqp"
    if /I "%HWENCODER%"=="qsv" set "VIDEO_OPTS=!VIDEO_OPTS! -preset slower"
    if /I "%HWENCODER%"=="vaapi" (
      set "FFMPEG_PRE_OPTS=!FFMPEG_PRE_OPTS! -vaapi_device /dev/dri/renderD128"
      set "VIDEO_OPTS=!VIDEO_OPTS! -b_depth 8 -qp 23"
      set "BASE_FILTERS=format=nv12,hwupload"
    )
    if /I "%HWENCODER%"=="vulkan" (
      set "FFMPEG_PRE_OPTS=!FFMPEG_PRE_OPTS! -init_hw_device vulkan"
      set "VIDEO_OPTS=!VIDEO_OPTS! -qp 23"
      set "BASE_FILTERS=hwupload=derive_device=vulkan"
    )
  ) else (
    set "VIDEO_OPTS=-c:v libx264 -crf:v 20 -preset 8 -subq 7 -refs 6 -bf 6 -keyint_min 1 -sc_threshold 60 -deblock 1:1 -qcomp 0.5 -psy-rd 0.3:0 -aq-mode 2 -aq-strength 0.8 -pix_fmt yuv420p"
  )
)

if not "!VIDEOCOPY!"=="1" set "VIDEO_OPTS=!VIDEO_OPTS! -fps_mode vfr"

if "!AUDIOCOPY!"=="1" (
  set "AUDIO_OPTS=-c:a copy"
) else (
  if "!ENABLE_OPUS!"=="1" (
    set "AUDIO_OPTS=-c:a libopus -b:a 64k -vbr on -strict -2"
  ) else (
    %FFMPEG% -hide_banner -codecs 2>nul | findstr /I "libfdk_aac" >nul
    if not errorlevel 1 (
      set "AUDIO_OPTS=-c:a libfdk_aac -vbr 2"
    ) else (
      call :warn "FFmpeg does not compile with libfdk_aac, fallback with aac encoder."
      set "AUDIO_OPTS=-c:a aac -strict -2 -q:a 0.5"
    )
  )
  if defined SAMPLE_RATE set "AUDIO_OPTS=!AUDIO_OPTS! -ar %SAMPLE_RATE%"
)
exit /b 0

:convert_videos
echo [INFO] Found !video_count! video(s)
for /L %%I in (1,1,!video_count!) do call :process_one %%I
echo.
echo ========================================
if !FAILED_COUNT! equ 0 (
  echo !GREEN!Done: !SUCCESS_COUNT! success, !FAILED_COUNT! failed!RESET!
) else (
  echo Done: !SUCCESS_COUNT! success, !RED!!FAILED_COUNT! failed!RESET!
)
echo ========================================
exit /b 0

:process_one
set "IDX=%~1"
call set "video=%%v_%IDX%%%"
for %%F in ("!video!") do (
  set "VIDEO_PATH=%%~fF"
  set "VIDEO_NAME=%%~nF"
  set "VIDEO_DIR=%%~dpF"
)

echo.
echo ----------------------------------------
echo [!IDX!/!video_count!] Processing: !VIDEO_NAME!
echo ----------------------------------------

if not exist "!VIDEO_PATH!" (
  call :warn "File not found: !video!"
  set /a FAILED_COUNT+=1
  exit /b 0
)

if defined DIR (
  set "OUTDIR=%DIR%"
) else (
  set "OUTDIR=!VIDEO_DIR!"
)
if not exist "!OUTDIR!" mkdir "!OUTDIR!" >nul 2>&1

if defined OUT (
  set "OUTFILE=%OUT%"
) else (
  set "OUTFILE=!VIDEO_NAME!_enc.%OUTPUT_FORMAT%"
)

set "FILTERS=!BASE_FILTERS!"

if defined SCALE (
  if defined FILTERS (
    set "FILTERS=scale=%SCALE%,!FILTERS!"
  ) else (
    set "FILTERS=scale=%SCALE%"
  )
)

if defined ENABLE_SUB (
  call :find_subtitle "!VIDEO_PATH!"
  if defined FIND_SUB_RESULT (
    echo [INFO] Found subtitle: !FIND_SUB_RESULT!
    call :build_sub_filter "!FIND_SUB_RESULT!"
    if defined SUB_FILTER (
      if defined FILTERS (
        set "FILTERS=!SUB_FILTER!,!FILTERS!"
      ) else (
        set "FILTERS=!SUB_FILTER!"
      )
    )
  ) else (
    call :warn "Could not find any subtitles for video '!VIDEO_PATH!'"
  )
)

set "FRAMERATE_OPTS="
if defined FRAMERATE set "FRAMERATE_OPTS=-r %FRAMERATE%"
set "OUTPUT_PATH=!OUTDIR!\!OUTFILE!"

if defined FILTERS (
  echo [CMD] %FFMPEG% -nostdin %OVERRIDE_OPTS% %FFMPEG_PRE_OPTS% -i "!VIDEO_PATH!" !VIDEO_OPTS! !FRAMERATE_OPTS! -vf "!FILTERS!" !AUDIO_OPTS! !FFMPEG_OPTS! "!OUTPUT_PATH!"
  echo.
  %FFMPEG% -nostdin %OVERRIDE_OPTS% %FFMPEG_PRE_OPTS% -i "!VIDEO_PATH!" !VIDEO_OPTS! !FRAMERATE_OPTS! -vf "!FILTERS!" !AUDIO_OPTS! !FFMPEG_OPTS! "!OUTPUT_PATH!"
) else (
  echo [CMD] %FFMPEG% -nostdin %OVERRIDE_OPTS% %FFMPEG_PRE_OPTS% -i "!VIDEO_PATH!" !VIDEO_OPTS! !FRAMERATE_OPTS! !AUDIO_OPTS! !FFMPEG_OPTS! "!OUTPUT_PATH!"
  echo.
  %FFMPEG% -nostdin %OVERRIDE_OPTS% %FFMPEG_PRE_OPTS% -i "!VIDEO_PATH!" !VIDEO_OPTS! !FRAMERATE_OPTS! !AUDIO_OPTS! !FFMPEG_OPTS! "!OUTPUT_PATH!"
)

if errorlevel 1 (
  call :error "Failed: !VIDEO_NAME!"
  set /a FAILED_COUNT+=1
) else (
  call :success "!VIDEO_NAME! -> !OUTFILE!"
  set /a SUCCESS_COUNT+=1
)
exit /b 0

:find_subtitle
set "FIND_SUB_RESULT="
for %%F in ("%~1") do (
  set "FS_VIDEO_DIR=%%~dpF"
  set "FS_VIDEO_NAME=%%~nF"
  set "FS_VIDEO_EXT=%%~xF"
)

if defined SUBDIR (
  set "SEARCH_DIR=%SUBDIR%"
) else (
  set "SEARCH_DIR=!FS_VIDEO_DIR!"
)

if not exist "!SEARCH_DIR!\" exit /b 0

for %%E in (ass ssa srt) do (
  set "SUB_PATTERN=!SEARCH_DIR!\!FS_VIDEO_NAME!*!SUBSUFFIX!.%%E"
  for /f "delims=" %%S in ('dir /b /a-d /s "!SUB_PATTERN!" 2^>nul') do (
    set "FIND_SUB_RESULT=%%~fS"
    goto :find_subtitle_done
  )
)

:find_subtitle_done
if defined FIND_SUB_RESULT exit /b 0

if /I "!FS_VIDEO_EXT!"==".mkv" (
  %FFMPEG% -hide_banner -i "%~1" 2>&1 | findstr /R /C:"Stream .*: Subtitle" >nul
  if not errorlevel 1 (
    >&2 echo Find embedded subtitles in %~1. So use it.
    set "FIND_SUB_RESULT=%~1"
  )
)
exit /b 0

:build_sub_filter
set "SUB_FILTER="
set "SUB_RAW=%~1"
if not defined SUB_RAW exit /b 0
set "SUB_ESC=%SUB_RAW:\=/%"
set "SUB_ESC=%SUB_ESC::=\:%"
set "SUB_FILTER=subtitles=filename='!SUB_ESC!'"
if defined SUBENC set "SUB_FILTER=!SUB_FILTER!:charenc=%SUBENC%"
exit /b 0

:do_join
set "OUTDIR=%DIR%"
if not defined OUTDIR set "OUTDIR=."
set "OUTFILE=%OUT%"
if not defined OUTFILE set "OUTFILE=video_join.%OUTPUT_FORMAT%"
if not exist "%OUTDIR%" mkdir "%OUTDIR%" >nul 2>&1

set "FILTERS=!BASE_FILTERS!"
if defined SCALE (
  if defined FILTERS (
    set "FILTERS=scale=%SCALE%,!FILTERS!"
  ) else (
    set "FILTERS=scale=%SCALE%"
  )
)
set "FRAMERATE_OPTS="
if defined FRAMERATE set "FRAMERATE_OPTS=-r %FRAMERATE%"

set "concat_file=%TEMP%\concat_%RANDOM%%RANDOM%.txt"
if exist "%concat_file%" del /f /q "%concat_file%" >nul 2>&1

for /L %%I in (1,1,!video_count!) do (
  call set "video=%%v_%%I%%"
  for %%F in ("!video!") do >>"%concat_file%" echo file '%%~fF'
)

echo.
echo ========================================
echo [INFO] Join mode: merging !video_count! videos...
echo ========================================

set "OUTPUT_PATH=%OUTDIR%\%OUTFILE%"
if defined FILTERS (
  echo [CMD] %FFMPEG% -nostdin %OVERRIDE_OPTS% %FFMPEG_PRE_OPTS% -protocol_whitelist file,pipe -f concat -safe 0 -i "%concat_file%" !VIDEO_OPTS! !FRAMERATE_OPTS! -vf "!FILTERS!" !AUDIO_OPTS! !FFMPEG_OPTS! "%OUTPUT_PATH%"
  echo.
  %FFMPEG% -nostdin %OVERRIDE_OPTS% %FFMPEG_PRE_OPTS% -protocol_whitelist file,pipe -f concat -safe 0 -i "%concat_file%" !VIDEO_OPTS! !FRAMERATE_OPTS! -vf "!FILTERS!" !AUDIO_OPTS! !FFMPEG_OPTS! "%OUTPUT_PATH%"
) else (
  echo [CMD] %FFMPEG% -nostdin %OVERRIDE_OPTS% %FFMPEG_PRE_OPTS% -protocol_whitelist file,pipe -f concat -safe 0 -i "%concat_file%" !VIDEO_OPTS! !FRAMERATE_OPTS! !AUDIO_OPTS! !FFMPEG_OPTS! "%OUTPUT_PATH%"
  echo.
  %FFMPEG% -nostdin %OVERRIDE_OPTS% %FFMPEG_PRE_OPTS% -protocol_whitelist file,pipe -f concat -safe 0 -i "%concat_file%" !VIDEO_OPTS! !FRAMERATE_OPTS! !AUDIO_OPTS! !FFMPEG_OPTS! "%OUTPUT_PATH%"
)

if errorlevel 1 (
  call :error "Join failed!"
  set "FAILED_COUNT=1"
  set "SUCCESS_COUNT=0"
) else (
  call :success "Joined successfully!"
  set "FAILED_COUNT=0"
  set "SUCCESS_COUNT=1"
)

if exist "%concat_file%" del /f /q "%concat_file%" >nul 2>&1

echo.
echo ========================================
if !FAILED_COUNT! equ 0 (
  echo !GREEN!Done: 1 success, 0 failed!RESET!
) else (
  echo Done: 0 success, !RED!1 failed!RESET!
)
echo ========================================
exit /b 0

:warn
echo !YELLOW!WARN: %~1!RESET!
exit /b 0

:error
echo !RED![ERROR] %~1!RESET! 1>&2
exit /b 0

:success
echo !GREEN![SUCCESS] %~1!RESET!
exit /b 0

:end
endlocal
