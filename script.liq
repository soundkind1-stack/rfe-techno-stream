set("init.allow_root", true)
set("decoder.priorities", ["ffmpeg", "mad"])
set("root.sync.buffer", 2.0)

my_music = playlist(mode="random", reload_mode="watch", "/home/radio/music")
final_audio = mksafe(my_music)

def print_title(m) =
  title = m["filename"]
  clean_title = string.replace(pattern="/home/radio/music/", substitution="", title)
  clean_title = string.replace(pattern=".mp3", substitution="", clean_title)
  
  log("=== RFE-TRACK-CHANGE ===: #{clean_title}")
  system("echo '#{clean_title}' > /home/radio/current_track.txt")
end

my_music.on_track(print_title)

output.file(
  %wav(stereo=true, channels=2, samplesize=16, header=false),
  append=false,
  "/home/radio/live.pipe",
  final_audio
)
