extends Node
## Tiny procedural-friendly audio bus helper so scenes don't need to know
## whether the player has muted music / sfx in Settings.

var music_player: AudioStreamPlayer
var sfx_bus_name := "SFX"
var music_bus_name := "Music"

func _ready() -> void:
	_ensure_bus("Master")
	_ensure_bus(music_bus_name)
	_ensure_bus(sfx_bus_name)
	apply_settings()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1 and bus_name != "Master":
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")

func apply_settings() -> void:
	var music_idx := AudioServer.get_bus_index(music_bus_name)
	var sfx_idx := AudioServer.get_bus_index(sfx_bus_name)
	if music_idx != -1:
		AudioServer.set_bus_mute(music_idx, not Save.music_on)
	if sfx_idx != -1:
		AudioServer.set_bus_mute(sfx_idx, not Save.sfx_on)

func play_sfx(player: AudioStreamPlayer) -> void:
	if Save.sfx_on and player:
		player.play()
