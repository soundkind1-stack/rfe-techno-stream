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
    echo '========================================'; \
    echo ' RFE TECHNO STREAM START'; \
    echo '========================================'; \
    \
    echo '--- Dateien im /home/radio ---'; \
    ls -lh /home/radio; \
    echo ''; \
    \
    echo '--- DJ Bilder ---'; \
    ls -lh /home/radio/dj1.png /home/radio/dj2.png /home/radio/dj3.png; \
    echo ''; \
    \
    rm -f /home/radio/live.pipe; \
    mkfifo -m 666 /home/radio/live.pipe; \
    \
    echo '=== Starte Health-Server ==='; \
    python3 -m http.server 10000 --bind 0.0.0.0 --directory /home/radio > /tmp/http.log 2>&1 & \
    HTTP_PID=$!; \
    \
    echo '=== Starte Liquidsoap ==='; \
    liquidsoap /home/radio/script.liq > /tmp/liquidsoap.log 2>&1 & \
    LIQ_PID=$!; \
    \
    sleep 5; \
    \
    echo '=== Starte FFmpeg ==='; \
    ffmpeg \
        -hide_banner \
        -loglevel info \
        -thread_queue_size 2048 \
        -f image2 \
        -framerate 0.1 \
        -start_number 1 \
        -loop 1 \
        -i /home/radio/dj%d.png \
        -thread_queue_size 2048 \
        -f s16le \
        -ar 44100 \
        -ac 2 \
        -i /home/radio/live.pipe \
        -vf 'scale=1280:720,format=yuv420p' \
        -c:v libx264 \
        -preset ultrafast \
        -tune zerolatency \
        -pix_fmt yuv420p \
        -r 2 \
        -g 4 \
        -keyint_min 4 \
        -sc_threshold 0 \
        -b:v 400k \
        -maxrate 400k \
        -bufsize 800k \
        -c:a aac \
        -b:a 128k \
        -ar 44100 \
        -ac 2 \
        -f flv \
        'rtmp://live.twitch.tv/app/live_432847037_OcLuZavV9YI0OD7jKjgYweXBhCxhy6' \
        > /tmp/ffmpeg.log 2>&1; \
    \
    FF_STATUS=$?; \
    \
    echo ''; \
    echo '========================================'; \
    echo \"FFmpeg beendet: $FF_STATUS\"; \
    echo '========================================'; \
    \
    tail -100 /tmp/ffmpeg.log; \
    echo ''; \
    echo '--- Liquidsoap Log ---'; \
    tail -100 /tmp/liquidsoap.log; \
    \
    wait $HTTP_PID \
"]
