#!/bin/sh
# An enhanced version of the download script supplied with uzbl

# Some sites block the default wget --user-agent..
GET="wget --user-agent=Firefox --content-disposition --load-cookies=${XDG_DATA_HOME:-${HOME}/.local/share}/uzbl/cookies.txt -nv "

dest="${HOME}/Downloads/"
torrents="${HOME}/.torrents/"
images="${HOME}/OBRAZY/"
url="${8}"

http_proxy="$9"
export http_proxy

test "x$url" = "x" && { echo "you must supply a url! ($url)"; exit 1; }

cd "$dest"
afile=`${GET} "${url}" 2>&1| sed 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}[[:blank:]]\+[0-9:]\{8\}[[:blank:]]\+URL[^ ]\+ \[[0-9\/]\+\][[:blank:]]\+->[[:blank:]]\+"\([^"]\+\)".*$/\1/'`
bfile="${afile%%\?*}"
if [[ -n `echo ${bfile}| grep -i "\(gif\|jpg\|jpeg\|png\|bmp\)"` ]]
then
    bfile="${images}/$bfile"
elif [[ -n `echo ${bfile}|grep -i "torrent\$"` ]]
then
    bfile="${torrents}/$bfile"
fi
if [[ "$afile" != "$bfile" ]]
then
    if [[ -e "$bfile" ]]
    then
        bfile="$bfile".`ls "$bfile"*|wc -l`
    fi
    mv "$afile" "$bfile"
fi
notify-send "Downloaded" "$bfile"
