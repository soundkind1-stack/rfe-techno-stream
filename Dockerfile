FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        tzdata \
        liquidsoap \
        ffmpeg \
        curl \
        dos2unix \
        coreutils \
        python3 \
        bash && \
    rm -rf /var/lib/apt/lists/*

RUN cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone

WORKDIR /home/radio

RUN mkdir -p /home/radio/music

COPY . /home/radio/

RUN dos2unix /home/radio/script.liq

EXPOSE 10000

CMD ["bash", "-c", "\
    set -m; \
    \
    rm -f /home/radio/live.wav /home/radio/live.pipe /home/radio/news.txt; \
    mkfifo -m 666 /home/radio/live.pipe; \
    echo '+++ GERMAN VAULT LIVE TICKER WAITING FOR RSS DIRECTORY +++' > /home/radio/news.txt; \
    \
    echo '=== RFE 1: Starting Health-Check Dummy on Port 10000 ==='; \
    python3 -m http.server 10000 & \
    PYTHON_PID=$!; \
    \
    bash -c 'while true; do sleep 60; curl -s -I http://localhost:10000 > /dev/null; done' & \
    \
    echo '=== RFE 1: Starting Automated News Factory background loop ==='; \
    bash -c 'while true; do curl -s \"https://blitz.cloud\" | grep -oP \"(?<=<title>).*?(?=</title>)\" | tail -n +2 | head -n 4 | tr \"\\n\" \" \" | sed \"s/  */ /g\" | sed \"s/^/+++ /; s/ $/ +++/\" > /home/radio/news.txt; sleep 300; done' & \
    \
    echo '=== RFE 1: Starting Unstoppable FFmpeg Auto-Recovery Loop with Live Ticker ==='; \
    bash -c '\
    while true; do \
      ffmpeg \
        -hide_banner \
        -loglevel info \
        -loop 1 \
        -framerate 1 \
        -video_size 1672x941 \
        -i /home/radio/background.png \
        -f s16le \
        -ar 44100 \
        -ac 2 \
        -i /home/radio/live.pipe \
        -vf \"drawtext=textfile=/home/radio/news.txt:reload=1:fontcolor=white:fontsize=28:y=h-45:x=w-mod(t*65\\,w+tw),scale=1024:576,format=yuv420p\" \
        -c:v libx264 \
        -preset ultrafast \
        -tune zerolatency \
        -pix_fmt yuv420p \
        -r 1 \
        -g 2 \
        -keyint_min 2 \
        -sc_threshold 0 \
        -b:v 150k \
        -maxrate 150k \
        -bufsize 300k \
        -c:a aac \
        -b:a 64k \
        -ar 44100 \
        -ac 2 \
        -f flv \
        \"rtmp://live.twitch.tv/app/live_1508232326_549kYQXQJHoFg89JbHbUTXfSVYRA4u\" \
        >> /tmp/ffmpeg.log 2>&1; \
      sleep 2; \
    done' & \
    \
    wait $PYTHON_PID \
"]
