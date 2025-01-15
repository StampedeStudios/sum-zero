class_name Randomizer

const HOLE_PROBABILITY := 100
const MAX_CELLS := 25
const MIN_CELLS := 4


static var slider_types = ["ADD", "SUB", "FLIP", "ADD", "SUB", "ADD", "SUB", "NONE", "NONE", "NONE"]


static func generate() -> LevelData:
	var data := LevelData.new()
	data.width = randi_range(2, 5)
	data.height = randi_range(2, 5)
#
	#var sliders = []
#
	#var data := LevelData.new()
	#for side in range(4):
		#var is_horizontal = side % 2 == 0
		#var max_index = grid_x if is_horizontal else grid_y
		#var max_extension = grid_y if is_horizontal else grid_x
#
		#for i in range(max_index):
			#var type = slider_types[randi_range(0, len(slider_types) - 1)]
			#if type == "NONE":
				#break
#
			#var slider = {
				#"side": side,
				#"index": i,
				#"type": type,
				#"is_quick": false,
				#"cells": get_cells(side, i, max_extension),
			#}
#
			#var num_slider = (slider["cells"] as Array[Vector2i]).size()
			#if num_slider > 0:
				#data.moves_left += 1
				#if num_slider == max_extension:
					#slider["is_quick"] = (randi_range(0, 10) < 2)
			#sliders.append(slider)
#
	#all_cells = get_grid_cells(grid_x, grid_y)
#
	#for slider in sliders:
		#for cell in slider["cells"]:
			#if all_cells.has(cell):
				#apply_rule(slider["type"], all_cells[cell])
			#else:
				#push_error("Cell not found: %s" % cell)

	data.cells_list = construct_grid(Vector2i(data.width, data.height))
	return data


#static func read_sliders(sliders):
	#var encoded_sliders = {}
#
	#for slider in sliders:
		#var value := SliderData.new()
		#match slider["type"]:
			#"ADD":
				#value.area_effect = GlobalConst.AreaEffect.ADD
			#"SUB":
				#value.area_effect = GlobalConst.AreaEffect.SUBTRACT
			#"FLIP":
				#value.area_effect = GlobalConst.AreaEffect.CHANGE_SIGN
#
		#if slider["is_quick"]:
			#value.area_behavior = GlobalConst.AreaBehavior.FULL
#
		#encoded_sliders[Vector2i(slider["side"], slider["index"])] = value
#
	#return encoded_sliders


#static func get_cells(side, slider_index, max_extension):
	#var probs = []
#
	#for i in range(max_extension + 1):
		#var j = 0
		#while j <= i:
			#probs.append(i)
			#j += 1
#
	#var extension = probs.pick_random()
#
	#if extension == 0:
		#return []
#
	#var cells: Array[Vector2i]
#
	#match side:
		## Top
		#0:
			#var x = slider_index
			#for i in range(extension):
				#var y = i
				#cells.append(Vector2i(x, y))
#
		## Right
		#1:
			#var y = slider_index
			#for i in range(extension):
				#var x = max_extension - i - 1
				#cells.append(Vector2i(x, y))
		## Bottom
		#2:
			#var x = slider_index
			#for i in range(extension):
				#var y = max_extension - i - 1
				#cells.append(Vector2i(x, y))
		## Left
		#3:
			#var y = slider_index
			#for i in range(extension):
				#var x = i
				#cells.append(Vector2i(x, y))
#
	#return cells

#
#static func get_grid_cells(grid_x, grid_y):
	#var cells = {}
	#for x in range(grid_x):
		#for y in range(grid_y):
			#var key := Vector2i(x, y)
			#cells[key] = CellData.new()
#
	#return cells
#
#
#static func apply_rule(type, data):
	#match type:
		#"ADD":
			#data.value = data.value - 1
		#"SUB":
			#data.value = data.value + 1
		#"FLIP":
			#data.value = data.value * -1


static func construct_grid(size: Vector2i) -> Dictionary:
	var cells = {}	
	var holes := create_holes(size)
	for x in range(size.x):
		for y in range(size.y):
			var coord := Vector2i(x, y)
			if !holes.has(coord):
				cells[coord] = CellData.new()
	return cells
	

static func create_holes(size: Vector2i) -> Array[Vector2i]:
	var holes: Array[Vector2i]
	var probability := float(size.x * size.y) / MAX_CELLS * HOLE_PROBABILITY
	if check_probability(probability):
		var origin := Vector2i(randi_range(0,size.x - 1), randi_range(0,size.y - 1))
		var adiacent := get_adiacent_cells(origin, size)
		var number := roundi(randf_range(MIN_CELLS, size.x * size.y) / randi_range(size.x * size.y, MAX_CELLS) * adiacent.size())
		while number > 0:
			var pick := randi_range(0, adiacent.size() - 1)
			holes.append(adiacent.pop_at(pick))
			number -= 1
		holes.append(origin)
	return holes
	
	
static func get_adiacent_cells(pos: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i]
	# N
	if pos.y > 0:
		result.append(Vector2i(pos.x, pos.y - 1))
	# N-E
	if pos.y > 0 and pos.x < size.x - 1:
		result.append(Vector2i(pos.x + 1, pos.y - 1))
	# E
	if pos.x < size.x - 1:
		result.append(Vector2i(pos.x + 1, pos.y))
	# S-E
	if pos.x < size.x - 1 and pos.y < size.y - 1:
		result.append(Vector2i(pos.x + 1, pos.y + 1))
	# S
	if pos.y < size.y - 1:
		result.append(Vector2i(pos.x, pos.y + 1))
	# S-O
	if pos.y < size.y - 1 and pos.x > 0:
		result.append(Vector2i(pos.x - 1, pos.y + 1))
	# O
	if pos.x > 0:
		result.append(Vector2i(pos.x - 1, pos.y))
	# N-O
	if pos.y > 0 and pos.x > 0:
		result.append(Vector2i(pos.x - 1, pos.y - 1))
	return result


static func check_probability(probability: float) -> bool:
	var random := randi_range(1,100)
	return true if random <= probability else false
