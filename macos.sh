#!/bin/bash

picDir=$(find /private/var/folders/ -name com.apple.desktoppicture 2>/dev/null)

while true
do
    # using UUID so macOS reconizes it as a new file when you set it as a wallpaper
    pic=$(uuidgen | tr -d '\n')
    cpu_usage=$(printf %.f $(ps -A -o %cpu | awk '{ cpu += $1} END {print cpu}' | head -c 2)) # sum of all processes CPU usage
    mem_usage=$((100 - $(memory_pressure | tail -c 4 | grep -o '[0-9]*'))) # memory pressure (/100)
    screen_dims=$(osascript -e 'tell application "Finder" to get bounds of window of desktop')
    screen_width=$( echo $screen_dims |  tr -d ',' | awk '{print $3}')
    screen_height=$( echo $screen_dims |  tr -d ',' | awk '{print $4}')
    # ps -e -c -o pid=,ppid=,pcpu=,rss=,comm= \
    #     | pscircle --stdin=true \
    #     --root-pid=1 \
    #     --cpulist-label="${cpu_usage} %" \
    #     --memlist-label="${mem_usage} %" \
    #     --cpulist-bar-value="$(bc <<< "scale=2 ; $cpu_usage / 100")" \
    #     --memlist-bar-value="$(bc <<< "scale=2 ; $mem_usage / 100")" \
    #     --memlist-show=true \
    #     --cpulist-show=true \
    ps -e -c -o pid=,ppid=,pcpu=,rss=,comm= | pscircle \
    --stdin=true \
    --memlist-show=false \
    --cpulist-show=false \
    --output="/tmp/${pic}" \
    --output-width="${screen_width}" \
    --output-height="${screen_height}" \
    --background-color=1e2226 \
	--link-color-min=375143a0 \
	--link-color-max=375143 \
	--dot-color-min=7c762f \
	--dot-color-max=b56e46 \
	--tree-font-size=18 \
	--tree-font-color=94bfd1 \
	--tree-font-face="Noto Sans" \
	--toplists-row-height=35 \
	--toplists-font-size=24 \
	--toplists-font-color=C8D2D7 \
	--toplists-pid-font-color=7B9098 \
	--toplists-font-face="Liberation Sans" \
	--toplists-bar-height=7 \
	--toplists-bar-background=444444 \
	--toplists-bar-color=7d54dd

    # osascript -e 'tell application "Finder" to set desktop picture to POSIX file "/tmp/'$pic'" '
    osascript -e 'tell application "System Events" to tell every desktop to set picture to POSIX file "/tmp/'$pic'" '

    sleep 15

    rm /tmp/$pic $picDir/*.png 2>/dev/null

done
