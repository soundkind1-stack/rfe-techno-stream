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
        fonts-dejavu-core \
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
    rm -f /home/radio/live.wav /home/radio/live.pipe /home/radio/current_track.txt; \
    mkfifo -m 666 /home/radio/live.pipe; \
    \
    echo '=== RFE: Seeding initial track text ==='; \
    echo 'Radio Freies Eurasien - Laedt...' > /home/radio/current_track.txt; \
    \
    echo '=== RFE: Starting Health-Check Dummy on Port 10000 ==='; \
    python3 -m http.server 10000 & \
    PYTHON_PID=$!; \
    \
    bash -c 'while true; do sleep 60; curl -s -I http://localhost:10000 > /dev/null; done' & \
    \
    echo '=== RFE: Starting Liquidsoap Engine ==='; \
    liquidsoap /home/radio/script.liq > /tmp/liquidsoap.log 2>&1 & \
    LIQ_PID=$!; \
    sleep 4; \
    \
    echo '=== RFE: Starting Unstoppable FFmpeg Auto-Recovery Loop with Song-Title Overlay ==='; \
    bash -c '\
    while true; do \
      ffmpeg \
        -hide_banner \
        -loglevel info \
        -loop 1 \
        -framerate 1 \
        -i /home/radio/background.* \
        -f s16le \
        -ar 44100 \
        -ac 2 \
        -i /home/radio/live.pipe \
        -vf \"scale=854:480,format=yuv420p,drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:textfile=/home/radio/current_track.txt:reload=1:fontcolor=white:fontsize=18:box=1:boxcolor=black@0.6:boxborderw=5:x=(w-text_w)/2:y=30\" \
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
        \"rtmp://live.twitch.tv/app/live_432847037_vgIqhjQqAIXoS94SUgWTkqVmeyrYJF\" \
        >> /tmp/ffmpeg.log 2>&1; \
      sleep 2; \
    done' & \
    \
    wait $PYTHON_PID \
"]
