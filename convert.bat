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
if "%~1"=="" goto :start_process

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
  set VIDEO_OPTS=-c:v libx265 -crf 28 -preset medium -pix_fmt yuv420p10le
  shift
  goto :parse_args
)

if /I "%~1"=="--opus" (
  set AUDIO_OPTS=-c:a libopus -b:a 64k -vbr on -strict -2
  shift
  goto :parse_args
)

if /I "%~1"=="--hwencoder" (
  set VIDEO_OPTS=-c:v h264_%~2
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
  set SCALE=-vf scale=%~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--framerate" (
  set FRAMERATE=-r %~2
  shift
  shift
  goto :parse_args
)

if /I "%~1"=="--videocopy" (
  set VIDEO_OPTS=-c:v copy
  shift
  goto :parse_args
)

if /I "%~1"=="--audiocopy" (
  set AUDIO_OPTS=-c:a copy
  shift
  goto :parse_args
)

if /I "%~1"=="--samplerate" (
  set SAMPLE_RATE=-ar %~2
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

set /a video_count=%video_count%+1
set v_%video_count%=%~1
shift
goto :parse_args

:start_process
echo [INFO] Found %video_count% video(s)

if %video_count% equ 0 (
  echo %RED%[ERROR] No videos to process.%RESET%
  goto :end
)

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
for %%F in ("%infile%") do (
  set fpath=%%~fF
  set fname=%%~nF
)

echo.
echo [%idx%/%video_count%] Processing: %fname%

if not exist "%fpath%" (
  echo %YELLOW%[WARNING] File not found: %infile%%RESET%
  set /a failed=%failed%+1
  goto :eof
)

if defined DIR (
  set outdir=%DIR%
) else (
  for %%F in ("%infile%") do set outdir=%%~dpF
)

if not exist "%outdir%" mkdir "%outdir%"

if defined OUT (
  set outfile=%OUT%
) else (
  set outfile=%fname%_enc.%OUTPUT_FORMAT%
)

echo [CMD] %FFMPEG% -nostdin %OVERRIDE_OPTS% %FFMPEG_PRE_OPTS% -i "%fpath%" %VIDEO_OPTS% %SCALE% %FRAMERATE% %AUDIO_OPTS% %SAMPLE_RATE% %FFMPEG_OPTS% "%outdir%%outfile%"
echo.

%FFMPEG% -nostdin %OVERRIDE_OPTS% %FFMPEG_PRE_OPTS% -i "%fpath%" %VIDEO_OPTS% %SCALE% %FRAMERATE% %AUDIO_OPTS% %SAMPLE_RATE% %FFMPEG_OPTS% "%outdir%%outfile%"

if %ERRORLEVEL% equ 0 (
  echo %GREEN%[SUCCESS] %fname% -> %outfile%%RESET%
  set /a success=%success%+1
) else (
  echo %RED%[ERROR] Failed: %fname%%RESET%
  set /a failed=%failed%+1
)

goto :eof

:do_join
echo.
echo [INFO] Joining %video_count% videos...

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
for %%F in ("%curfile%") do set fullpath=%%~fF
echo file '%fullpath%' >> "%concat_file%"
goto :build_concat
:concat_done

echo [INFO] Output: %DIR%\%OUT%

%FFMPEG% -nostdin %OVERRIDE_OPTS% %FFMPEG_PRE_OPTS% -protocol_whitelist file,pipe -f concat -safe 0 -i "%concat_file%" %VIDEO_OPTS% %FRAMERATE% %AUDIO_OPTS% %SAMPLE_RATE% %FFMPEG_OPTS% "%DIR%\%OUT%"

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
