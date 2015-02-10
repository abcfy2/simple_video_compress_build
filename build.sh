#!/bin/bash

[[ -f config ]] && . config
[[ -z "$sign_put_url" ]] && echo "未找到变量sign_put_url" && exit 1
rm -fr "简易批量视频压制"
mkdir "简易批量视频压制"
cp ./convert.sh ./readme.txt ./请把视频拖拽至此处压制视频.cmd ./ffmpeg.exe "简易批量视频压制"
7za a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on 简易批量视频压制.7z 简易批量视频压制
echo "上传中,请稍后..."
curl -# -T 简易批量视频压制.7z -H "x-bs-acl: public-read" "$sign_put_url" -o /dev/null
