class_name Randomizer

static var slider_types = ["ADD", "SUB", "FLIP", "ADD", "SUB", "ADD", "SUB", "NONE", "NONE", "NONE"]


static func generate():
	var grid_y = randi_range(2, 5)
	var grid_x = randi_range(2, 5)
	var all_cells = {}

	var sliders = []

	var data := LevelData.new()
	for side in range(4):
		var is_horizontal = side % 2 == 0
		var max_index = grid_x if is_horizontal else grid_y
		var max_extension = grid_y if is_horizontal else grid_x

		for i in range(max_index):
			var type = slider_types[randi_range(0, len(slider_types) - 1)]
			if type == "NONE":
				break

			var slider = {
				"side": side,
				"index": i,
				"type": type,
				"is_quick": false,
				"cells": get_cells(side, i, max_extension),
			}

			var num_slider = (slider["cells"] as Array[Vector2i]).size()
			if num_slider > 0:
				data.moves_left += 1
				if num_slider == max_extension:
					slider["is_quick"] = (randi_range(0, 10) < 2)
			sliders.append(slider)

	all_cells = get_grid_cells(grid_x, grid_y)

	for slider in sliders:
		for cell in slider["cells"]:
			if all_cells.has(cell):
				apply_rule(slider["type"], all_cells[cell])
			else:
				push_error("Cell not found: %s" % cell)

	data.cells_list = all_cells
	data.slider_list = read_sliders(sliders)
	data.width = grid_x
	data.height = grid_y

	var encoded = Encoder.encode(data)
	print(encoded)
	DisplayServer.clipboard_set(encoded)


static func read_sliders(sliders):
	var encoded_sliders = {}

	for slider in sliders:
		var value := SliderData.new()
		match slider["type"]:
			"ADD":
				value.area_effect = GlobalConst.AreaEffect.ADD
			"SUB":
				value.area_effect = GlobalConst.AreaEffect.SUBTRACT
			"FLIP":
				value.area_effect = GlobalConst.AreaEffect.CHANGE_SIGN

		if slider["is_quick"]:
			value.area_behavior = GlobalConst.AreaBehavior.FULL

		encoded_sliders[Vector2i(slider["side"], slider["index"])] = value

	return encoded_sliders


static func get_cells(side, slider_index, max_extension):
	var probs = []

	for i in range(max_extension + 1):
		var j = 0
		while j <= i:
			probs.append(i)
			j += 1

	var extension = probs.pick_random()

	if extension == 0:
		return []

	var cells: Array[Vector2i]

	match side:
		# Top
		0:
			var x = slider_index
			for i in range(extension):
				var y = i
				cells.append(Vector2i(x, y))

		# Right
		1:
			var y = slider_index
			for i in range(extension):
				var x = max_extension - i - 1
				cells.append(Vector2i(x, y))
		# Bottom
		2:
			var x = slider_index
			for i in range(extension):
				var y = max_extension - i - 1
				cells.append(Vector2i(x, y))
		# Left
		3:
			var y = slider_index
			for i in range(extension):
				var x = i
				cells.append(Vector2i(x, y))

	return cells


static func get_grid_cells(grid_x, grid_y):
	var cells = {}
	for x in range(grid_x):
		for y in range(grid_y):
			var key := Vector2i(x, y)
			cells[key] = CellData.new()

	return cells


static func apply_rule(type, data):
	match type:
		"ADD":
			data.value = data.value - 1
		"SUB":
			data.value = data.value + 1
		"FLIP":
			data.value = data.value * -1
