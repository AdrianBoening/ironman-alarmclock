#!/bin/bash

# format time
function displaytime {
    local t=$1
    local h=$((t/60/60%24))
    local m=$((t/60%60))
    local s=$((t%60))
    if [[ $h > 0 ]]; then
		[[ $h = 1 ]] && DISPLAYTIME="$DISPLAYTIME $h Stunde " || DISPLAYTIME="$DISPLAYTIME $h Stunden "
    fi
    if [[ $m > 0 ]]; then
		if [[ $h > 0 ]]; then
			DISPLAYTIME="$DISPLAYTIME und "
		fi
		[[ $m = 1 ]] && DISPLAYTIME="$DISPLAYTIME $m Minute " || DISPLAYTIME="$DISPLAYTIME $m Minuten "
    fi
    if [[ $d = 0 && $h = 0 && $m = 0 ]]; then
		[[ $s = 1 ]] && DISPLAYTIME="$DISPLAYTIME $s Sekunde" || DISPLAYTIME="$DISPLAYTIME $s Sekunden"
    fi  
    echo
}

# current time
HOURS=$(date +"%-H")
MINUTES=$(date +"%-M")
if [[ $MINUTES -gt 0 ]]; then
	TIME="$HOURS Uhr $MINUTES"
else
	TIME="$HOURS Uhr"
fi

# weather
WEATHER=$(curl 'http://api.openweathermap.org/data/2.5/weather?APPID=<APPID>&zip=<ZIP-CODE>,de&units=metric&lang=de' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: de-DE,de;q=0.9,en-US;q=0.8,en;q=0.7,fr;q=0.6' -H 'Upgrade-Insecure-Requests: 1' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8' -H 'Cache-Control: max-age=0' -H 'Connection: keep-alive' --compressed)
export PYTHONIOENCODING=utf8
DESCRIPTION=$(echo $WEATHER | python -c "import sys, json; print json.load(sys.stdin)['weather'][0]['description']")
TEMP=$(echo $WEATHER | python -c "import sys, json; print json.load(sys.stdin)['main']['temp']")

# sunrise
DATE=$(date +%s)
SUNRISE=$(echo $WEATHER | python -c "import sys, json; print json.load(sys.stdin)['sys']['sunrise']")
SUNRISE=$(expr $SUNRISE - $DATE)

if [[ $SUNRISE -ge 0 ]]; then
	displaytime $SUNRISE
	SUNRISE="Die Sonne geht in $DISPLAYTIME auf."
else
	displaytime ${SUNRISE#-}
	SUNRISE="Die Sonne ist vor $DISPLAYTIME aufgegangen."
fi

TEXT="Guten Morgen. Es ist $TIME. $SUNRISE Das Wetter aktuell: $DESCRIPTION bei $TEMP Grad. Ich wünsche einen guten Start in den Tag"
# text-to-speech
curl -G https://code.responsivevoice.org/getvoice.php --data-urlencode "t=$TEXT" --data "tl=de-DE" -o tts.temp.mp3
# adjust tts volume, sample rate and channels
sox -v 0.7 tts.temp.mp3 -r 44100 -c 2 tts.mp3
rm tts.temp.mp3
# create 3 seconds of silence to prepend the tts
sox -n -r 44100 -c 2 silence.mp3 trim 0.0 3.0
# combine silence and tts
sox silence.mp3 tts.mp3 tts-silence.mp3
rm silence.mp3
rm tts.mp3
# mix tts with the Lights-Up sound from Iron Man
sox --combine mix Lights-Up.mp3 tts-silence.mp3 alarm.mp3
rm tts-silence.mp3
