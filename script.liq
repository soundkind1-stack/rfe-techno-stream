set("init.allow_root", true)
set("decoder.priorities", ["ffmpeg", "mad"])
set("root.sync.buffer", 2.0)

# 1. Playlist aus dem music-Ordner einlesen
my_music = playlist(mode="random", reload_mode="watch", "/home/radio/music")

# 2. Der bewährte DJ-Mix-Hack (Crossfade für weiche Übergänge)
my_music = crossfade(smart=true, duration=3.0, fade_out=2.5, fade_in=1.5, my_music)

# 3. Audio absichern
final_audio = mksafe(my_music)

# 4. Saubere Übergabe an die FFmpeg-Pipe
output.file(
  %wav(stereo=true, channels=2, samplesize=16, header=false),
  append=false,
  "/home/radio/live.pipe",
  final_audio
)
