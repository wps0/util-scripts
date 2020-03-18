#!/bin/bash

#= Constant variables =#
readonly ROOT_DIR="~"
readonly OUTPUT_DIR=${ROOT_DIR}"/ytdl-output/"
# youtube-dl output file's template
readonly FILE_TEMPLATE="%(title)s.%(ext)s"
readonly PLAYLIST_TEMPLATE="%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s"
ytdlArguments="--geo-bypass -x --audio-format \"wav\" --add-metadata"

echo -n "Youtube video/playlist URL: "
read ytUrl

if [[ ${ytUrl##playlist} == $ytUrl ]]; then
    ytdlArguments="${ytdlArguments} -o '${OUTPUT_DIR}${FILE_TEMPLATE}'"
    echo "TYPE: VIDEO"
elif [[ ${ytUrl##playlist} != $ytUrl ]]; then
    ytdlArguments="${ytdlArguments} -o '${OUTPUT_DIR}${PLAYLIST_TEMPLATE}'"
    echo "TYPE: PLAYLIST"
fi

echo "Arguments: ${ytdlArguments} ${ytUrl}"

eval "youtube-dl ${ytdlArguments} ${ytUrl}"
