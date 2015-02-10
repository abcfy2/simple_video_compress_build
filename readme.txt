This is a simple script that can convert a batch of videos to "H.264(libx264) + aac(libfdk_aac)" mp4 videos.

For Windows users:
    Just drag and drop your video file(s) onto the ``cmd`` file.

For Linux users:
    Should install ``ffmpeg`` first. Follow the ffmpeg official document: https://www.ffmpeg.org/download.html#build-linux
    Then open your terminal and type ``bash convert.sh video1 [video2] ...``
    Or you can modify convert.sh, change the line ``FFMPEG="wine ffmpeg.exe"``, so you can install wine to run ffmpeg.exe. No need to install ffmpeg at all. But it's not very well. I suggest you to install the corresponding ffmpeg.
