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
        bash && \
    rm -rf /var/lib/apt/lists/*

RUN cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    echo "Europe/Berlin" > /etc/timezone

WORKDIR /home/radio

RUN mkdir -p /home/radio/music

COPY . /home/radio/

# Wir kopieren deine neuen alphabetischen Bilder direkt ins System-Hauptverzeichnis!
RUN cp /home/radio/dja.png /dja.png && \
    cp /home/radio/djb.png /djb.png && \
    cp /home/radio/djc.png /djc.png

RUN dos2unix /home/radio/script.liq

EXPOSE 10000

CMD ["bash", "-c", "rm -f /home/radio/live.pipe && mkfifo -m 666 /home/radio/live.pipe && python3 -m http.server 10000 & liquidsoap /home/radio/script.liq > /tmp/liquidsoap.log 2>&1 & sleep 4 && ffmpeg -re -thread_queue_size 2048 -stream_loop -1 -framerate 2.5 -pattern_type glob -i '/dj[a-c].png' -thread_queue_size 2048 -f s16le -ar 44100 -ac 2 -i /home/radio/live.pipe -vf \"scale=1280:720,format=yuv420p\" -c:v libx264 -preset ultrafast -tune zerolatency -pix_fmt yuv420p -r 2.5 -g 5 -b:v 400k -maxrate 400k -bufsize 800k -c:a aac -b:a 128k -ar 44100 -ac 2 -f flv \"rtmp://live.twitch.tv/app/live_432847037_OcLuZavV9YI0OD7jKjgYweXBhCxhy6\""]
