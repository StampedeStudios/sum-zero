class_name PlayerOptions extends Resource

@export var music_on: bool = true
@export var sfx_on: bool = true
@export var tutorial_on: bool = true
@export var hints_enabled := {"ZEN": true, "BLITZ": true, "PUZZLE": true}
@export var language: String = "en"


func set_tutorial_visibility(visible: bool) -> void:
	tutorial_on = visible
	for hint: String in hints_enabled.keys():
		hints_enabled[hint] = visible


func disable_hint(hint_name: String) -> void:
	hints_enabled[hint_name] = false


func is_visible(hint_name: String) -> bool:
	return hints_enabled[hint_name]
