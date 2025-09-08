#!/usr/bin/env bash

list_link="$@"

if [ -z "$list_link" ]; then
  echo "Usage: $0 <YouTube playlist URL> (escape & as \\& or wrap in quotes)"
  exit 1
fi

read -r -p "Format (opus/mp3) [opus]: " fmt
fmt=${fmt:-opus}
case "${fmt,,}" in
  opus) sel='bestaudio[acodec=opus]/bestaudio'; out=opus ;;
  mp3) sel='bestaudio'; out=mp3 ;;
  *) echo "Invalid format"; exit 1 ;;
esac

yt-dlp -f "$sel" --extract-audio --playlist-reverse --audio-format "$out" --yes-playlist $list_link

