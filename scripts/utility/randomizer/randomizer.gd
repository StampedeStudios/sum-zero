## The Randomizer class is responsible for procedurally generating game levels.
## It uses a RandomizerOptions resource to configure the generation process.
## The class can generate the grid, create holes, blocks, and sliders.
## It also ensures that the generated level is valid and playable.
class_name Randomizer extends Node

var _options: RandomizerOptions


## Initializes the Randomizer with the provided options.
## @param new_options The RandomizerOptions resource to use for generation.
func _init(new_options: RandomizerOptions) -> void:
	_options = new_options


## Generates a new level based on the provided LevelData object.
## This function orchestrates the entire level generation process,
## including grid generation, hole creation, block placement, and slider setup.
## @param data The LevelData object to populate with the generated level.
func generate_level(data: LevelData) -> void:
	var context := GenerationContext.new(data, _options)
	var grid_generator := GridGenerator.new(context)
	var hole_generator := HoleGenerator.new(context)
	var block_generator := BlockGenerator.new(context)
	var slider_generator := SliderGenerator.new(context)

	while true:
		await grid_generator.generate()
		await hole_generator.generate()
		await block_generator.generate()
		await slider_generator.generate()

		var valid_cell: bool
		for cell_data: CellData in data.cells_list.values():
			if cell_data.value > 0:
				valid_cell = true
				break

		if valid_cell:
			break

		push_warning("Generated a level with no moves needed. Generating again")
		data.cells_list.clear()


func create_holes(data: LevelData) -> void:
	var context := GenerationContext.new(data, _options)
	var hole_generator := HoleGenerator.new(context)
	await hole_generator.generate()


func create_block(data: LevelData) -> void:
	var context := GenerationContext.new(data, _options)
	var block_generator := BlockGenerator.new(context)
	await block_generator.generate()


func create_sliders(data: LevelData) -> void:
	var context := GenerationContext.new(data, _options)
	var slider_generator := SliderGenerator.new(context)
	await slider_generator.generate()
