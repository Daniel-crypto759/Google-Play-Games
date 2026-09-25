extends Node
## Persistent save data: best score, crystal currency, owned/equipped skins, settings.

const SAVE_PATH := "user://crystalrush_save.json"

var best_score: int = 0
var crystals: int = 0
var owned_skins: Array = ["prism"]
var equipped_skin: String = "prism"
var music_on: bool = true
var sfx_on: bool = true

const SKINS := {
	"prism": {"name": "Prism", "cost": 0, "color": Color(0.35, 0.85, 1.0)},
	"ember": {"name": "Ember Core", "cost": 250, "color": Color(1.0, 0.42, 0.2)},
	"toxic": {"name": "Toxic Shard", "cost": 500, "color": Color(0.55, 1.0, 0.25)},
	"void": {"name": "Void Fragment", "cost": 900, "color": Color(0.75, 0.3, 1.0)},
	"gold": {"name": "Solar Gold", "cost": 1500, "color": Color(1.0, 0.82, 0.2)},
}

func _ready() -> void:
	load_game()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return
	best_score = int(data.get("best_score", 0))
	crystals = int(data.get("crystals", 0))
	owned_skins = data.get("owned_skins", ["prism"])
	equipped_skin = data.get("equipped_skin", "prism")
	music_on = bool(data.get("music_on", true))
	sfx_on = bool(data.get("sfx_on", true))

func save_game() -> void:
	var data := {
		"best_score": best_score,
		"crystals": crystals,
		"owned_skins": owned_skins,
		"equipped_skin": equipped_skin,
		"music_on": music_on,
		"sfx_on": sfx_on,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func register_run(score: int, earned_crystals: int) -> void:
	crystals += earned_crystals
	if score > best_score:
		best_score = score
	save_game()

func buy_skin(id: String) -> bool:
	if not SKINS.has(id):
		return false
	if owned_skins.has(id):
		return false
	var cost: int = SKINS[id]["cost"]
	if crystals < cost:
		return false
	crystals -= cost
	owned_skins.append(id)
	save_game()
	return true

func equip_skin(id: String) -> void:
	if owned_skins.has(id):
		equipped_skin = id
		save_game()
