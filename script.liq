set("init.allow_root", true)
set("decoder.priorities", ["ffmpeg", "mad"])
set("root.sync.buffer", 2.0)

# 1. Playlist einlesen
my_music = playlist(mode="random", reload_mode="watch", "/home/radio/music")

# 2. Der DJ-Mix-Hack: Automatischer, smarter Uebergang gegen Doppel-Bass
# duration = Gesamtzeit des Ueberblendens (3 Sekunden)
# fade_out = Der alte Song blendet in 2.5 Sekunden aus
# fade_in = Der neue Song blendet in 1.5 Sekunden ein
my_music = crossfade(smart=true, duration=3.0, fade_out=2.5, fade_in=1.5, my_music)

# 3. Audio absichern
final_audio = mksafe(my_music)

# 4. Ausgabe an die FFmpeg-Pipeline
output.file(
  %wav(stereo=true, channels=2, samplesize=16, header=false),
  append=false,
  "/home/radio/live.pipe",
  final_audio
)
