set("init.allow_root", true)
set("decoder.priorities", ["ffmpeg", "mad"])
set("root.sync.buffer", 2.0)

# 1. Playlist einlesen
my_music = playlist(mode="random", reload_mode="watch", "/home/radio/music")

# 2. Funktion für den Titel-Export (Schreibt in unser sicheres Hauptverzeichnis)
def print_title(m) =
  title = m["filename"]
  clean_title = string.replace(pattern="/home/radio/music/", substitution="", title)
  clean_title = string.replace(pattern=".mp3", substitution="", clean_title)
  
  log("=== RFE-TRACK-CHANGE ===: #{clean_title}")
  system("echo '#{clean_title}' > /home/radio/current_track.txt")
end

my_music.on_track(print_title)

# 3. Der DJ-Mix-Hack (Crossfade)
my_music = crossfade(smart=true, duration=3.0, fade_out=2.5, fade_in=1.5, my_music)

# 4. Audio absichern & ausgeben
final_audio = mksafe(my_music)
output.file(
  %wav(stereo=true, channels=2, samplesize=16, header=false),
  append=false,
  "/home/radio/live.pipe",
  final_audio
)
