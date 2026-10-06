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

CMD ["bash", "-c", "rm -f /home/radio/live.pipe && mkfifo -m 666 /home/radio/live.pipe && python3 /home/radio/fetch_news.py & python3 -m http.server 10000 & liquidsoap /home/radio/script.liq > /tmp/liquidsoap.log 2>&1 & sleep 4 && ffmpeg -re -stream_loop -1 -r 2 -pattern_type glob -i '/home/radio/dj[1-3].png' -f s16le -ar 44100 -ac 2 -i /home/radio/live.pipe -vf \"scale=1280:720,drawtext=textfile=/dev/shm/news.txt:reload=1:fontcolor=white:fontsize=40:font='DejaVu Sans':box=1:boxcolor=black@0.6:boxborderw=10:y=h-60:x=w-mod(t*120\\,w+tw),format=yuv420p\" -c:v libx264 -preset ultrafast -tune zerolatency -pix_fmt yuv420p -r 2 -g 4 -b:v 400k -maxrate 400k -bufsize 800k -c:a aac -b:a 128k -ar 44100 -ac 2 -f flv \"rtmp://live.twitch.tv/app/live_432847037_vgIqhjQqAIXoS94SUgWTkqVmeyrYJF\""]
