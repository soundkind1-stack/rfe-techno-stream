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

CMD ["bash", "-c", "rm -f /home/radio/live.pipe /home/radio/news.txt && mkfifo -m 666 /home/radio/live.pipe && echo '+++ GERMAN VAULT LIVE TICKER +++' > /home/radio/news.txt && python3 -m http.server 10000 & (while true; do python3 -c \"import urllib.request, re; xml=urllib.request.urlopen('https://blitz.cloud').read().decode('utf-8'); titles=re.findall(r'<title>(.*?)</title>', xml)[1:6]; text=' +++ '.join(titles); open('/home/radio/news.txt', 'w').write('+++ ' + text + ' +++')\" 2>/dev/null || echo '+++ GERMAN VAULT SYSTEM ACTIVE +++' > /home/radio/news.txt; sleep 300; done) & liquidsoap /home/radio/script.liq > /tmp/liquidsoap.log 2>&1 & sleep 4 && ffmpeg -re -loop 1 -i /home/radio/background.png -f s16le -ar 44100 -ac 2 -i /home/radio/live.pipe -vf \"drawtext=textfile=/home/radio/news.txt:reload=1:fontcolor=white:fontsize=54:font='DejaVu Sans':box=1:boxcolor=black@0.6:boxborderw=10:y=h-75:x=w-mod(t*90\\,w+tw),scale=1024:576,format=yuv420p\" -c:v libx264 -preset ultrafast -tune zerolatency -pix_fmt yuv420p -r 1 -g 2 -b:v 150k -maxrate 150k -bufsize 300k -c:a aac -b:a 64k -ar 44100 -ac 2 -f flv \"rtmp://live.twitch.tv/app/live_432847037_vgIqhjQqAIXoS94SUgWTkqVmeyrYJF\""]
