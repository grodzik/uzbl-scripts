#!/bin/sh
keydir=${XDG_DATA_HOME:-$HOME/.local/share}/uzbl/

[ -d "`dirname $keydir`" ] || exit 1
[ -d $keydir ] || mkdir $keydir || exit 1

editor=${VISUAL}
if [ -z ${editor} ]; then
    if [ -z ${EDITOR} ]; then
        editor='xterm -e vim'
    else
        editor="xterm -e ${EDITOR}"
    fi
fi

config=$1; 
shift
pid=$1;    
shift
xid=$1;    
shift
fifo=$1;   
shift
socket=$1; 
shift
url=$1;    
shift
title=$1;  
shift
action=$1

domain=$(echo $url | sed 's/\(http\|https\):\/\/\([^\/]\+\)\/.*/\2/')

scripts_state=`sed -n "s/$domain \([01]\)/\1/p" $keydir/scriptblock.txt`
scripts_state=${scripts_state:-`sed -n 's/set[[:blank:]]\+disable_scripts[[:blank:]]\+=[[:blank:]]\+\([01]\)/\1/p' $config`}
plugins_state=`sed -n "s/$domain [01] \([01]\)/\1/p" $keydir/scriptblock.txt`
plugins_state=${plugins_state:-`sed -n 's/set[[:blank:]]\+disable_plugins[[:blank:]]\+=[[:blank:]]\+\([01]\)/\1/p' $config`}

scripts_state=${scripts_state:-0}
plugins_state=${plugins_state:-1}

if [ -z "$action" ]
then
    echo "set disable_plugins = $plugins_state" >> $fifo
    echo "set disable_scripts = $scripts_state" >> $fifo
    if [ "$scripts_state" == "1" ] 
    then
        echo "set scripts_status = <span foreground=\"#ff0000\">scripts</span>" >> $fifo
    else
        echo "set scripts_status = <span foreground=\"#00ff00\">scripts</span>" >> $fifo
    fi
    if [ "$plugins_state" == "1" ] 
    then
        echo "set plugins_status = <span foreground=\"#ff0000\">plugins</span>" >> $fifo
    else
        echo "set plugins_status = <span foreground=\"#00ff00\">plugins</span>" >> $fifo
    fi
elif [ "$action" == 'unblock_scripts' ]
then
    if [ "`grep $domain $keydir/scriptblock.txt`x" == "x" ]
    then
        echo $domain 0 0 >> $keydir/scriptblock.txt
    else
        sed "s/\($domain\) [01] \([01]\)/\1 0 \2/" -i $keydir/scriptblock.txt
    fi
elif [ "$action" == 'unblock_plugins' ]
then 
    if [ "`grep $domain  $keydir/scriptblock.txt`x" == "x" ]
    then
        echo $domain 0 0 >> $keydir/scriptblock.txt
    else
        sed "s/\($domain\) \([01]\) [01]/\1 \2 0/" -i $keydir/scriptblock.txt
    fi
elif [ "$action" == 'block_scripts' ]
then
    if [ "`grep $domain  $keydir/scriptblock.txt`x" == "x" ]
    then
        echo $domain 1 0 >> $keydir/scriptblock.txt
    else
        sed "s/\($domain\) [01] \([01]\)/\1 1 \2/" -i $keydir/scriptblock.txt
    fi
elif [ "$action" == 'block_plugins' ]
then
    if [ "`grep $domain  $keydir/scriptblock.txt`x" == "x" ]
    then
        echo $domain 0 1 >> $keydir/scriptblock.txt
    else
        sed "s/\($domain\) \([01]\) [01]/\1 \2 1/" -i $keydir/scriptblock.txt
    fi
fi
