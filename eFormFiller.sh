#!/bin/sh
#
# Enhanced html form (eg for logins) filler (and manager) for uzbl.
#
# uses settings files like: $keydir/<domain>
# files contain lines like: !profile=<profile_name>
#                           <fieldname>(fieldtype): <value>
# profile_name should be replaced with a name that will tell sth about that profile
# fieldtype can be text or password - only for information pupropse (auto-generated) - don't change that
#
# user arg 1:
# edit: force editing the file (falls back to new if not found)
# new:  start with a new file.
# load: try to load from file into form
# add: try to add another profile to an existing file
#
# something else (or empty): if file not available: new, otherwise load.

# config dmenu colors and prompt
NB="#0f0f0f"
NF="#4e7093" 
SB="#003d7c" 
SF="#3a9bff" 
if [ `dmenu -h 2>&1| grep lines` ]
then
    LINES=" -l 3 "
else
    LINES=""
fi
echo ${LINES}
PROMPT="Choose profile"

keydir=${XDG_DATA_HOME:-$HOME/.local/share}/uzbl/dforms

[ -d "`dirname $keydir`" ] || exit 1
[ -d "$keydir" ] || mkdir "$keydir"

editor=${VISUAL}
if [ -z ${editor} ]; then
    if [ -z ${EDITOR} ]; then
        editor='xterm -e vim'
    else
        editor="xterm -e ${EDITOR}"
    fi
fi

echo $@
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


[ -d $keydir ] || mkdir $keydir || exit 1

if [ "$action" != 'edit' -a  "$action" != 'new' -a "$action" != 'load' -a "$action" != 'add' -a "$action" != 'once' ]
then
    action="new"
    [ -e $keydir/$domain ] && action="load"
elif [ "$action" == 'edit' ] && [ ! -e $keydir/$domain ]
then
    action="new"
fi
domain=$(echo $url | sed 's/\(http\|https\):\/\/\([^\/]\+\)\/.*/\2/')

if [ "$action" = 'load' ]
then
    [ -e $keydir/$domain ] || exit 2
    if [ `cat $keydir/$domain|grep "!profile"|wc -l` -gt 1 ]
    then
        menu=`cat $keydir/$domain| \
              sed -n 's/^!profile=\([^[:blank:]]\+\)/\1/p'`
        option=`echo -e -n "$menu"| dmenu ${LINES} -nb "${NB}" -nf "${NF}" -sb "${SB}" -sf "${SF}" -p "${PROMPT}"`
    fi

    cat $keydir/$domain | \
        sed -n -e "/^!profile=${option}/,/^!profile=/p" | \
        sed -n -e 's/\([^(]\+\)([^)]\+):[ ]*\([^[:blank:]]\+\)/js document.getElementsByName("\1")[0].value="\2";/p' | \
        sed -e 's/@/\\@/p' >> $fifo
elif [ "$action" = "once" ]
then
    tmpfile=`mktemp`
    html=`echo 'js document.documentElement.outerHTML' | \
            socat - unix-connect:$socket | \
            tr -d '\n' | \
            sed 's/>/>\n/g'`
    echo "${html}" | \
        sed -n 's/.*\(<input[^>]\+>\).*/\1/;/type="\(password\|text\)"/Ip' | \
        sed 's/\(.*\)\(type="[^"]\+"\)\(.*\)\(name="[^"]\+"\)\(.*\)/\1\4\3\2\5/I' | \
        sed 's/.*name="\([^"]\+\)".*type="\([^"]\+\)".*/\1(\2): /I' >> $tmpfile
    echo "${html}" | \
        sed -n '.*\(<textarea'
    ${editor} $tmpfile

    [ -e $tmpfile ] || exit 2

    cat $tmpfile | \
        sed -n -e 's/\([^(]\+\)([^)]\+):[ ]*\([^[:blank:]]\+\)/js document.getElementsByName("\1")[0].value="\2";/p' | \
        sed -e 's/@/\\@/p' >> $fifo
    rm -f $tmpfile
else
    if [ "$action" == 'new' -o "$action" == 'add' ]
    then
        if [ "$action" == 'new' ]
        then
            echo "!profile=NAME_THIS_PROFILE$RANDOM" > $keydir/$domain
        else
            echo "!profile=NAME_THIS_PROFILE$RANDOM" >> $keydir/$domain
        fi
        #
        # 2. and 3. line (tr -d and sed) are because, on gmail login for example, 
        # <input > tag is splited into lines
        # ex:
        # <input name="Email"
        #        type="text"
        #        value="">
        # So, tr removes all new lines, and sed inserts new line after each >
        # Next sed selects only <input> tags and only with type == "text" or == "password"
        # If type is first and name is second, then another sed will change their order
        # so the last sed will make output 
        #       text_from_the_name_attr(text or password): 
        #
        #       login(text):
        #       passwd(password):
        #
        echo 'js document.documentElement.outerHTML' | \
            socat - unix-connect:$socket | \
            tr -d '\n' | \
            sed 's/>/>\n/g' | \
            sed -n 's/.*\(<input[^>]\+>\).*/\1/;/type="\(password\|text\)"/Ip' | \
            sed 's/\(.*\)\(type="[^"]\+"\)\(.*\)\(name="[^"]\+"\)\(.*\)/\1\4\3\2\5/I' | \
            sed 's/.*name="\([^"]\+\)".*type="\([^"]\+\)".*/\1(\2): /I' >> $keydir/$domain
    fi
    [ -e $keydir/$domain ] || exit 3 #this should never happen, but you never know.
    $editor $keydir/$domain #TODO: if user aborts save in editor, the file is already overwritten
fi

# vim:fileencoding=utf-8:sw=4
