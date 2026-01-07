## BaseGenerator
##
## Base class for all generator classes. Contains common helper functions.
class_name BaseGenerator extends Node

var _context: GenerationContext


func _init(p_context: GenerationContext) -> void:
	_context = p_context


## Checks if a random event should occur based on a given probability.
## @param probability The probability of the event (0-100).
## @return True if the event should occur, false otherwise.
func _check_probability(probability: float) -> bool:
	var random := randi_range(1, 100)
	return random <= probability


## Gets a random rule based on the provided odds.
## @param rules_odd A dictionary of rules and their odds.
## @return The selected rule.
func _get_rule(rules_odd: Dictionary[String, int]) -> String:
	var random := randi_range(1, 100)
	var counter_odd := 0

	for rule: String in rules_odd.keys():
		counter_odd += rules_odd.get(rule) as int
		if random <= counter_odd:
			return rule

	push_error("No rules found!")
	return ""
