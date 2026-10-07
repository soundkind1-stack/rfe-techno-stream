FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        tzdata \
        liquidsoap \
        ffmpeg \
        python3 \
        curl \
        dos2unix \
        coreutils \
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
rm -f /home/radio/live.pipe && \
mkfifo -m 666 /home/radio/live.pipe && \
python3 -m http.server 10000 --bind 0.0.0.0 --directory /home/radio > /tmp/http.log 2>&1 & \
liquidsoap /home/radio/script.liq > /tmp/liquidsoap.log 2>&1 & \
sleep 4 && \
ffmpeg \
-re \
-thread_queue_size 2048 \
-f image2 \
-framerate 3 \
-start_number 1 \
-stream_loop -1 \
-i /home/radio/dj%d.png \
-thread_queue_size 2048 \
-f s16le \
-ar 44100 \
-ac 2 \
-i /home/radio/live.pipe \
-vf scale=1280:720,format=yuv420p \
-c:v libx264 \
-preset medium \
-tune stillimage \
-pix_fmt yuv420p \
-r 3 \
-g 6 \
-b:v 600k \
-maxrate 600k \
-bufsize 1800k \
-c:a aac \
-b:a 128k \
-ar 44100 \
-ac 2 \
-f flv \
rtmp://live.twitch.tv/app/live_432847037_OcLuZavV9YI0OD7jKjgYweXBhCxhy6 \
"]
