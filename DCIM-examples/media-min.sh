#!/bin/bash
# skript zmensi velikost fotek a videi pres nástroj ffmppeg
# spusti se v adresari kde jsou fotky
# zachovava geolokaci ve fotkach a dalsi metadata (pomoci nastroj exiftool)
# je mozne ho spustit i na androidu pres nastroj termux
# pokud metada fotek obsahuje v komentari retezec Lavc, komprese se neprovede

#  skript pro zmenseni fotek. Skript potrebuje BASH, ffmpeg, exiftool (exif - Exchangeable image file format)
#  ve Windows:
#    GIT BASH prostředí https://gitforwindows.org/
#    ffmpeg nástroj - https://ffmpeg.org/ proklikat
#      https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-n5.0-latest-win64-gpl-5.0.zip
#   exiftool nástroj -
#     https://exiftool.org/Image-ExifTool-12.41.tar.gz
#   ffmpeg, exiftool je moyne stahnout zde:
#     https://drive.google.com/drive/u/0/folders/1pnKocV7VZHeTlCXP_K8Q4ZZCKF3OBdnm
#		 

#	For successfully write comment tag to video (mkv)
# ren IN.mkv IN.mp4
#  ffmpeg -i IN.mp4 -f mp4 OUT.min.mp4
# exiftool -P -comment=Lavc_is_bigger out.min.mp4
# ...-P ... owrite modified date

maxsize=1500000
maxsize=1
shopt -s nocaseglob

function process_media_file() {
  filesize=$(stat -c %s "$f")
  if [ "$filesize" -gt "$maxsize" ]; then
    ffmpeg_comment=$(exiftool -comment "$f" 2>&1)
    if [[ $ffmpeg_comment == *"Lavc"* ]]; then
      echo "just reduced, comments contains Lavc string. $f"
      return
    fi
    echo "reducing $f $ffmpeg_comment ..."
    ffmpeg -i "$f" -y "reduced.$f" 1> /dev/null 2> /dev/null
    if [[ $? -eq 0 ]]; then
      exiftool -overwrite_original -TagsFromFile "$f" -All:All "reduced.$f" 1> /dev/null 2> /dev/null
      if [ "jpg" != "${f##*.}" ]; then
         #exiftool "-overwrite_original -comment<$ffmpeg_reduced_{comment}" "reduced.$f" 1> /dev/null 2> /dev/null
         exiftool -overwrite_original -comment=Lavc "reduced.$f" 1> /dev/null 2> /dev/null
      fi
      filesize_reduced=$(stat -c %s "reduced.$f")
      echo "metadata $f $filesize -> $filesize_reduced bytes..."
      if [[ $? -eq 0 ]]; then
        if [ "$filesize" -gt "$filesize_reduced" ]; then
            mv "reduced.$f" "$f"
            if [[ $? -ne 0 ]]; then
                echo "moving.. $f ERROR"
            fi
        else
            echo "reduced.$f is bigger, write comment Lavc_is_bigger to original"
            rm "reduced.$f"
			exiftool -overwrite_original -P -comment=Lavc_is_bigger "$f" 1> /dev/null 2> /dev/null
        fi
      else 
        echo "metadata $f ERROR"
      fi
    else
      echo "reducing $f ERROR "
    fi
  else
    echo "skipping $f ..."
  fi
}

for f in *.jpg *.jpeg *.mp4 *.mkv
do
  if [[ -f "$f" ]]; then
     process_media_file "%f"
  fi
done


