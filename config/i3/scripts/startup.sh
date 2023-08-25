#!/bin/sh	

# Autoload links file location.	
#file=$HOME/dotfiles/config/i3/scripts/autoload.txt	

# Turn built-in monitor off if an external monitor(s) is connected.	
count=$(xrandr | grep "DP-*. connected" | wc | awk '{print $1}')	
if [ "$count" -gt "1" ]; then	
    xrandr --output eDP1 --off	
fi	

count=$(xrandr | grep "DisplayPort-*. connected" | wc | awk '{print $1}')	
if [ "$count" -gt "1" ]; then	
    xrandr --output eDP1 --off	
fi	

day=$(date '+%a')	
# Start Slack only on workdays.	
[ $day != "Sat" ] && [ $day != "Sun" ] && slack > /dev/null &	

feh --bg-scale $HOME/Downloads/bg.jpg & # Set background	
$HOME/dotfiles/config/polybar/launch.sh > /dev/null &	
code > /dev/null &	
brave > /dev/null &	
obsidian > /dev/null &	
#sleep 3	
#lines=$(less $file)	
#for line in $lines	
#do	
#    brave $line &	
#done