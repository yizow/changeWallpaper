#!/bin/bash

# Get directory this script is located in. Save image here as well.
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
IMAGE_PATH=$DIR/wallpaper
IMAGE_DOWNLOADING=$IMAGE_PATH\2
URL_SAVE_FILE=$DIR/url.txt
URL='old.reddit.com/r/earthporn/top/?sort=top&t=day'

# export DBUS_SESSION_BUS_ADDRESS environment variable
GRAPHICS='cinnamon'
PID=$(pgrep $GRAPHICS)
PID=$(echo $PID | cut -d" " -f1)
export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$PID/environ|cut -d= -f2-)

# Search page source for url links ending in .jpg or .jpeg, choose a random one
IMAGES=$(wget "$URL" -O - | sed 's/data-url="/\n/g' | sed -n -E 's/(https?[^ "]*?\.jpe?g).*?/\1/p' | sort -u)
printf "Found %d images\n" $(echo $IMAGES | wc -w)
IMAGE_URL=$(echo $IMAGES | tr " " "\n" | shuf -n 1)
printf "Image URL:" $IMAGE_URL

# Save to IMAGE
wget "$IMAGE_URL" -O "$IMAGE_DOWNLOADING"

# Save IMAGE_URL 
echo "$IMAGE_URL" > $URL_SAVE_FILE

# Check if we need to change backgroudn settings
CURRENT_BACKGROUND=$(gsettings get org.cinnamon.desktop.background picture-uri)
if [ "$CURRENT_BACKGROUND" != "file://${IMAGE_PATH}" ]; then
    gsettings set org.cinnamon.desktop.background picture-uri "file://${IMAGE_PATH}"
fi

# Remove background cache, then overwrite file
rm $HOME/.cache/wallpaper/*
mv -f $IMAGE_DOWNLOADING $IMAGE_PATH

# Add this program as cron job to be run every twenty minutes (by default)
CRON_JOB='*/20 * * * * '
CRON_JOB+="$DIR/$(basename $0)"
# Check if this cron job has been added before. If not, add it.
TMP_FILE=$DIR/tmpCron
crontab -l > $TMP_FILE
if [ ! -n "$(grep -F "$CRON_JOB" $TMP_FILE)" ]; then
    echo "$CRON_JOB" >> $TMP_FILE
    crontab $TMP_FILE
    echo 'Writing cron job'
fi
rm $TMP_FILE
