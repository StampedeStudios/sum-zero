## GridGenerator
##
## Responsible for generating the grid size for the level based on the
## provided options.
class_name GridGenerator extends BaseGenerator


func _init(p_context: GenerationContext) -> void:
	super(p_context)


## Generates the grid size for the level.
func generate() -> void:
	if !_context.options.grid_opt:
		_context.level_data.width = 3
		_context.level_data.height = 3
		return

	var grid_options := _context.options.grid_opt
	var size := grid_options.std_grid_sizes.pick_random() as Vector2i

	match _get_rule(grid_options.size_rules):
		"STANDARD":
			pass

		"LOWER":
			while true:
				await Engine.get_main_loop().process_frame
				if size.x > 2 or size.y > 2:
					size = grid_options.get_lower_size(size)
				else:
					break
				if !_check_probability(grid_options.lower_odd):
					break

		"UPPER":
			while true:
				await Engine.get_main_loop().process_frame
				if size.x < 5 or size.y < 5:
					size = grid_options.get_upper_size(size)
				else:
					break
				if !_check_probability(grid_options.upper_odd):
					break

	_context.level_data.width = size.x
	_context.level_data.height = size.y
	await Engine.get_main_loop().process_frame
