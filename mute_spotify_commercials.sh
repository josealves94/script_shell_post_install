#!/bin/bash
# set commercial mute, so we do not neet to listen to them
# This script works on Ubuntu 14.04 with the 0.9.17.1 release of Spotify
echo "----------------------------------------------------------"
echo ""
echo "   Mute spotify commercial"
echo ""
echo "----------------------------------------------------------"


WMTITLE="Spotify Free - Linux Preview"


xprop -spy -name "$WMTITLE" WM_ICON_NAME |
while read -r XPROPOUTPUT; do
        XPROP_TRACKDATA="$(echo "$XPROPOUTPUT" | cut -d \" -f 2 )"
        DBUS_TRACKDATA="$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify / \
        org.freedesktop.MediaPlayer2.GetMetadata | grep xesam:title -A 1 | grep variant | cut -d \" -f 2)"

        # show something
        echo "XPROP:      $XPROP_TRACKDATA"
        echo "DBUS:       $DBUS_TRACKDATA"

        # first song should not be commerical
        if [ "$OLD_XPROP" != "" ]
        then
            # check if old DBUS is the same as the new, if true then we have a commercial, so mute
            if [ "$OLD_DBUS" = "$DBUS_TRACKDATA" ]
            then
                echo "commercial: yes"
                amixer -D pulse set Master mute >> /dev/null
            else
                echo "commercial: no"
                amixer -D pulse set Master unmute >> /dev/null
            fi
        else
            echo "commercial: we don't know yet"
        fi
        echo "----------------------------------------------------------"
        OLD_XPROP=$XPROP_TRACKDATA
        OLD_DBUS=$DBUS_TRACKDATA

done

exit 0
