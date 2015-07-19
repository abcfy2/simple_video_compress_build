#!/bin/bash

[[ -f config ]] && . config || exit 1

rm -fr "简易批量视频压制"
mkdir "简易批量视频压制"
cp ./convert.sh ./readme.txt ./请把视频拖拽至此处压制视频.cmd ./ffmpeg.exe "简易批量视频压制"
7za a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on 简易批量视频压制.7z 简易批量视频压制
echo "上传中,请稍后..."

echo accesskey = $accesskey
echo secretkey = $secretkey
scope="$namespace:简易批量视频压制.7z"
deadline=$((`date +%s` + 3600))
putPolicy="{\"scope\":\"$scope\",\"deadline\":$deadline}"
echo putPolicy = "$putPolicy"
encodedPutPolicy=`echo -n "$putPolicy" | base64 -w0 | sed 's/\+/-/g; s/\//_/g'`
echo encodedPutPolicy = "$encodedPutPolicy"
sign=`echo -n "$encodedPutPolicy" | openssl sha1 -hmac "$secretkey" | awk '{print $2}' | xxd -r -p`
encodedSign=`echo -n "$sign" | base64 -w0 | sed 's/\+/-/g; s/\//_/g'`
echo encodedSign = $encodedSign
uploadToken="$accesskey:$encodedSign:$encodedPutPolicy"
echo uploadToken = $uploadToken

curl -# -F token="$uploadToken" -F key='简易批量视频压制.7z' -F "file=@简易批量视频压制.7z; filename=简易批量视频压制.7z" http://upload.qiniu.com/ -o /dev/null
