#!/bin/bash

# sizes
#monitor=1
#monitor2=0
#geometry=( $(herbstclient monitor_rect "$monitor") )
#if [ -z "$geometry" ] ;then
#    echo "Invalid monitor $monitor"
#    exit 1
#fi
# geometry has the format: WxH+X+Y
#x=${geometry[0]}
#y=${geometry[1]}
#width=${geometry[2]}
#height=16

# Separators
powerl="%{F#6E464B} %{F-}"
powerR="%{F#6E464B}%{F-}"
LR="%{B-}%{B#6E464B}%{F#60676E}%{F-}"
Ll="%{B-}%{B#B5BD68}%{F#60676E}%{F-}"
sep_m="%{B#1f1f22}%{F#833228}  %{F-}%{B-}"
sep_v="%{B#1f1f22}%{F#596875}  %{F-}%{B-}"
sep_d="%{B#1f1f22}%{F#8c5b3e} || %{F-}%{B-}"
sep_c="%{B#1f1f22}%{F#917154} || %{F-}%{B-}"
#FONT="*-siji-medium-r-*-*-10-*-*-*-*-*-*-*"
font="-xos4-terminesspowerline-medium-r-normal--12-120-72-72-c-60-iso10646-1"
iconfont="-misc-fontawesome-medium-r-normal--12-*-*-*-*-*-iso10646-1"

Volume=$(amixer get Master | grep 'Front Left:' | awk '{print $5}' | cut -d '[' -f 2 | cut -d ']' -f 1 | cut -d '%' -f 1)
Status=$(amixer get Master | grep 'Front Left:' | awk '{print $6}' | cut -d '[' -f 2 | cut -d ']' -f 1 )

set -f

function uniq_linebuffered() {
    awk -W interactive '$0 != l { print ; l=$0 ; fflush(); }' "$@"
}

monitor=${1:-0}

herbstclient pad $monitor 16

funtion statusbar
{

    # events:
    mpc idleloop player | cat &

    # date
    while true ; do
            date +'date_min %d-%m-%y, %H:%M'
            sleep 1 || break
    done > >(uniq_linebuffered) &
    date_pid=$!

    # Volume
    while true ; do
            echo "vol $(amixer get Master | tail -1 | sed 's/.*\[\([0-9]*%\)\].*/\1/')"
    done > >(uniq_linebuffered) &
    volume_pid=$!

    # MEM
    while true ; do
            echo "mem $(free -m | grep Mem: | awk '{printf $3 "/" $2 "Mb"}')"
            sleep 1 || break
    done > >(uniq_linebuffered) &
    mem_pid=$!

    #CPU
    while true ; do
            echo "cpu $(top -b -n1 | grep "Cpu" | awk '{print $3 + $4}')"
            sleep 1 || break
    done > >(uniq_linebuffered) &
    cpu_pid=$!

    # Weather
    while true ; do
            echo "weather $(curl -s http://rss.accuweather.com/rss/liveweather_rss.asp\?metric\=1\&locCode\=Queretaro | sed -n '/Currently:/ s/.*: \(.*\): \([0-9]*\)\([CF]\).*/\2°\3 \L\1/p')"
            sleep 1 || break
    done > >(uniq_linebuffered) &
    weather_pid=$!

    # Batery
    while true ; do
            echo "batery $(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "percentage" | awk '{print $2}')"
            sleep 1 || break
    done > >(uniq_linebuffered) &
    batery_pid=$!

    # hlwm events
    herbstclient --idle

    # exiting; kill stray event-emitting processes
    kill $date_pid $mpd_pid
} 2> /dev/null | {
    TAGS=( $(herbstclient tag_status $monitor) )
    unset TAGS[${#TAGS[@]}]
    date_min="--"
    nowplaying="Arch Linux"
    windowtitle="Archlinux"
    visible=true

    while true ; do
        echo -n "%{l}"
        for i in "${TAGS[@]}" ; do
            case ${i:0:1} in
                '#') # current tag
                    echo -n "%{B#505050}"
                    ;;
                '+') # active on other monitor
                    echo -n "%{B#917154}"
                    ;;
                ':')
                    echo -n "%{B-}"
                    ;;
                '!') # urgent tag
                    echo -n "%{B#917154}"
                    ;;
                *)
                    echo -n "%{B-}"
                    ;;
            esac
            echo -n " ${i:1} "
        done

	#echo -n "%{} %{F#917154}${windowtitle} %{}"
        #echo -n "%{l}%{B#1f1f22} Archlinux %{B-}"
	#echo -n "%{}%{F#917154} $nowplaying %{F-}"

        # align right
        echo -n "%{r}"

		echo -n "%{F#282A2E} %{F-}%{B#282A2E}%{F#917154} $nowplaying %{F-}"

		echo -n "%{F#282A2E}%{F-}%{B#282A2E}$weather"

		echo -n "%{F#60676E} %{F-}%{B#60676E} Mem: $mem  %{B-}"

        echo -n "%{B#60676E}%{F#FFCE935F}%{F-}%{B#FFCE935F}%{F#282A2E} cpu: $cpu "

        echo -n "%{F#282A2E} %{F-}%{B#282A2E} Bat: $batery %{B-}"

        echo -n "%{B#282A2E}%{F#979997}%{F-}%{B#979997}%{F#282A2E} Vol: $volume "

        echo -n "%{F#FFB5BD68} %{F-}%{B#FFB5BD68}%{F#282A2E} $date_min "
		echo "%{B-}%{F-}"
        # wait for next event
        read line || break
        cmd=( $line ) 
        # find out event origin
        case "${cmd[0]}" in
                tag*)
                        TAGS=( $(herbstclient tag_status $monitor) )
                        unset TAGS[${#TAGS[@]}]
                        ;;
                cpu)
                        cpu="${cmd[@]:1}"
                        ;;
                mem)
                        mem="${cmd[@]:1}"
                        ;;
                weather)
                        weather="${cmd[@]:1}"
                        ;;
                batery)
                        batery="${cmd[@]:1}"
                        ;;
                vol)
                        volume="${cmd[@]:1}"
                        ;;
                date_min)
                        date_min="${cmd[@]:1}"
                        ;;
                mpd_player|player)
                        nowplaying="$(mpc current -f '%artist% - %title%')"
                        ;;
                focus_changed|window_title_changed)
                        windowtitle="${cmd[@]:2}"
                        ;;
                quit_panel)
                        exit
                        ;;
                reload)
                        exit
                        ;;
        esac
done
} 2> /dev/null | lemonbar -g 1366x14 -B "#1f1f22" -F '#a8a8a8' -f '-xos4-terminesspowerline-medium-r-normal--12-120-72-72-c-60-iso10646-1' -f ${iconfont} $1