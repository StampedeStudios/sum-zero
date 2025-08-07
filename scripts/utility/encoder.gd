## Provides a simple way to encode and decode defined puzzle and the amount of moves required for
## the resolution.
##
## The encoding structure is not human readable but represents an effort to reduce to the minimum
## the amount of characters required to completely define a puzzle constraints. For instance,
## "2go-9k-1cbb1a" describes a 3x3 puzzle with 4 sliders.
## The short string is helpful when users want to manually import a friend level.
##
## Encoding rules are detailed below.
##
## Format:
##   1st character  - Minimum amount of required moves encoded as a string. See MOVES.
##   2nd character  - Grid size encoded as a single letter. See SIZE.
##   3rd character  - Cell reading order as a single letter. See CELL_ORDER.
##   4th character  - Separator (always '-')
##
##   Next characters: Encoded cell data
##     - Read according to the specified cell order.
##     - Cell types are encoded as single characters. See CELL_VALUE.
##     - Optimization: Repeated cells (2 or more) are prefixed by the repetition count,
##       e.g., fffff = 5f
##
##   Next character: Separator (always '-')
##
##   Next characters: Encoded slider data
##     - Ordered clockwise starting from the top-left corner.
##     - Slider steps are encoded as characters. See SLIDER.
##     - Optimization: Repeated sliders (2 or more) are prefixed by the repetition count,
##       e.g., aaa = 3a
##
##   Next character: Separator (always '-')
##
##   Last string: name of the level
##
## Example:
##   "2go-9k-1cbb1a-test" encodes:
##     - Moves left: 2
##     - Grid size: g = 3x3
##     - Cell order: o = Horizontal
##     - Cells: 9k = Nine cells all equals to 1
##     - Sliders: 1 = empty slider slot, c = change sign slider, bb = 2 consecutive subtract sliders, 1 = empty slider slot, a = add slider
class_name Encoder

enum CellOrder { HORIZONTAL, VERTICAL }

## One character to define the number of required moves. This approach limit the required moves to 62.
const MOVES: PackedStringArray = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" ]

## Maps characters to grid sizes, from 2x2 (a) to 5x5 (s).
## Used in encoding to minimize character length.
const SIZE: Dictionary[String, Vector2i] = {
	"a": Vector2i(2, 2),
	"b": Vector2i(2, 3),
	"c": Vector2i(2, 4),
	"d": Vector2i(2, 5),
	"f": Vector2i(3, 2),
	"g": Vector2i(3, 3),
	"h": Vector2i(3, 4),
	"i": Vector2i(3, 5),
	"k": Vector2i(4, 2),
	"l": Vector2i(4, 3),
	"m": Vector2i(4, 4),
	"n": Vector2i(4, 5),
	"p": Vector2i(5, 2),
	"q": Vector2i(5, 3),
	"r": Vector2i(5, 4),
	"s": Vector2i(5, 5)
}

const CELL_ORDER: Dictionary[String, CellOrder] = {
	"o": CellOrder.HORIZONTAL,
	"v": CellOrder.VERTICAL
}

## Encodes cell value from -4 up to +4. This limit is set by design since the maximum amount of
## sliders that can have effect over a cell is 4.
const CELL_VALUE: Dictionary[String, int] = { "f": -4, "g": -3, "h": -2, "i": -1, "j": 0, "k": 1, "l": 2, "m": 3, "n": 4 }
## Placeholder to highlight a missing cell, which is different from a cell defined as zero.
const CELL_EMPTY := "z"
## Placeholder to highlight a permanently blocked cell.
const CELL_BLOCKED := "x"

## Defines slider encoding characters based on effect and behavior.
## Format: [effect + "_" + behavior]
## See also: ADD_EFFECT, FULL_BEHAVIOR
const SLIDER: Dictionary[String, String] = {
	"a": ADD_EFFECT + "_" + BY_STEP_BEHAVIOR,
	"b": SUBTRACT_EFFECT + "_" + BY_STEP_BEHAVIOR,
	"c": CHANGE_SIGN_EFFECT + "_" + BY_STEP_BEHAVIOR,
	"d": BLOCK_EFFECT + "_" + BY_STEP_BEHAVIOR,
	"i": ADD_EFFECT + "_" + FULL_BEHAVIOR,
	"j": SUBTRACT_EFFECT + "_" + FULL_BEHAVIOR,
	"k": CHANGE_SIGN_EFFECT + "_" + FULL_BEHAVIOR,
	"l": BLOCK_EFFECT + "_" + FULL_BEHAVIOR
}
const ADD_EFFECT := "plus"
const SUBTRACT_EFFECT := "minus"
const CHANGE_SIGN_EFFECT := "invert"
const BLOCK_EFFECT := "block"
const BY_STEP_BEHAVIOR := "bystep"
const FULL_BEHAVIOR := "full"

## Encodes all relevant information about a level into a compact string format.
##
## @param data Object that describes the whole level in a structured way. @see `level_data.gd`.
## @return A string representing the encoded level.
static func encode(data: LevelData) -> String:
	var encode_data := ""
	var level_size := Vector2i(data.width, data.height)
	encode_data += MOVES[data.moves_left]
	encode_data += SIZE.find_key(level_size)
	var encode_horizontal := _encode_cells_horizontal(data.cells_list, level_size)
	var encode_vertical := _encode_cells_vertical(data.cells_list, level_size)

	if encode_vertical.length() < encode_horizontal.length():
		encode_data += CELL_ORDER.find_key(CellOrder.VERTICAL)
		encode_data += "-"
		encode_data += encode_vertical
	else:
		encode_data += CELL_ORDER.find_key(CellOrder.HORIZONTAL)
		encode_data += "-"
		encode_data += encode_horizontal

	encode_data += "-"
	encode_data += _encode_sliders(data.slider_list, level_size)
	encode_data += "-"
	encode_data += data.name
	return encode_data


## Decodes a playable level from an encoded string.
##
## @param encoded_data A string representing the encoded level.
## @return Level data in a structured object.
static func decode(encoded_data: String) -> LevelData:
	var data := LevelData.new()
	var splitted_data := encoded_data.split("-")

	if splitted_data.size() < 3:
		push_warning("Invalid code format")
		return null

	var moves_left := _decode_moves(encoded_data[0])
	if moves_left < 0:
		push_warning("Invalid moves")
		return null

	data.moves_left = moves_left
	if !SIZE.has(encoded_data[1]):
		push_warning("Invalid size")
		return null

	var level_size: Vector2i = SIZE.get(encoded_data[1])
	data.width = level_size.x
	data.height = level_size.y

	var cell_order: CellOrder = CELL_ORDER.get(encoded_data[2])
	if cell_order == null:
		push_warning("Invalid order")
		return null

	var cell_list := _decode_cell_list(splitted_data[1], level_size, cell_order)
	if cell_list.is_empty():
		push_warning("Invalid cells")
		return null

	data.cells_list = cell_list
	var slider_list := _decode_slider_list(splitted_data[2], level_size)
	if slider_list.is_empty():
		push_warning("Invalid sliders")
		return null

	data.slider_list = slider_list
	if splitted_data.size() > 3:
		data.name = splitted_data[3]
	return data


## Extract level name from an encoded string.
##
## @param encoded_data A string representing the encoded level.
## @return The name of the level.
static func decode_name(encoded_data: String) -> String:
	var splitted_data := encoded_data.split("-")
	if splitted_data.size() > 3:
		return splitted_data[3]
	return ""


static func _encode_cells_horizontal(cell_list: Dictionary[Vector2i, CellData], level_size: Vector2i) -> String:
	var encode_cells := ""
	var last := ""
	var count := 1

	for row in range(level_size.y):
		for column in range(level_size.x):
			var cell_coord := Vector2i(column, row)
			var current := ""

			if cell_list.has(cell_coord):
				var cell := cell_list.get(cell_coord) as CellData
				if cell.is_blocked:
					current = CELL_BLOCKED
				else:
					current = CELL_VALUE.find_key(cell.value)
			else:
				current = CELL_EMPTY

			if current == last:
				count += 1
			else:
				if count > 1:
					encode_cells += String.num_int64(count)
					count = 1
				encode_cells += last
				last = current
	if count > 1:
		encode_cells += String.num_int64(count)
	encode_cells += last
	return encode_cells


static func _encode_cells_vertical(cell_list: Dictionary[Vector2i, CellData], level_size: Vector2i) -> String:
	var encode_cells := ""
	var last := ""
	var count := 1

	for column in range(level_size.x):
		for row in range(level_size.y):
			var cell_coord := Vector2i(column, row)
			var current := ""

			if cell_list.has(cell_coord):
				var cell := cell_list.get(cell_coord) as CellData
				if cell.is_blocked:
					current = CELL_BLOCKED
				else:
					current = CELL_VALUE.find_key(cell.value)
			else:
				current = CELL_EMPTY

			if current == last:
				count += 1
			else:
				if count > 1:
					encode_cells += String.num_int64(count)
					count = 1
				encode_cells += last
				last = current
	if count > 1:
		encode_cells += String.num_int64(count)
	encode_cells += last
	return encode_cells


static func _encode_sliders(slider_list: Dictionary[Vector2i, SliderData], level_size: Vector2i) -> String:
	var encode_sliders := ""
	var empty_count := 0

	for edge in range(4):
		var max_pos: int = level_size.x if edge % 2 == 0 else level_size.y

		for pos in range(max_pos):
			var slider_coord := Vector2i(edge, pos)

			if slider_list.has(slider_coord):
				if empty_count > 0:
					encode_sliders += String.num_int64(empty_count)
					empty_count = 0
				encode_sliders += _encode_slider(slider_list.get(slider_coord))
			else:
				empty_count += 1

	return encode_sliders


static func _encode_slider(slider_data: SliderData) -> String:
	var encode_slider := ""

	match slider_data.area_effect:
		Constants.Sliders.Effect.ADD:
			encode_slider += ADD_EFFECT
		Constants.Sliders.Effect.SUBTRACT:
			encode_slider += SUBTRACT_EFFECT
		Constants.Sliders.Effect.CHANGE_SIGN:
			encode_slider += CHANGE_SIGN_EFFECT
		Constants.Sliders.Effect.BLOCK:
			encode_slider += BLOCK_EFFECT
	encode_slider += "_"

	match slider_data.area_behavior:
		Constants.Sliders.Behavior.FULL:
			encode_slider += FULL_BEHAVIOR
		Constants.Sliders.Behavior.BY_STEP:
			encode_slider += BY_STEP_BEHAVIOR
	return SLIDER.find_key(encode_slider)


static func _decode_moves(letter: String) -> int:
	for index in range(MOVES.size()):
		if letter == MOVES[index]:
			return index
	return -1


static func _decode_cell_list(
	encode_data: String, level_size: Vector2i, order: CellOrder
) -> Dictionary[Vector2i, CellData]:

	var cell_list: Dictionary[Vector2i, CellData]
	var cell_count := level_size.x * level_size.y
	var count := 0
	var cell_coord := Vector2i.ZERO

	for letter in encode_data:
		if letter.is_valid_int():
			if count > 0:
				count *= 10
			count += letter.to_int()
		else:
			count = maxi(1, count)
			cell_count -= count
			if cell_count < 0:
				return {}

			for i in range(count):
				if letter != CELL_EMPTY:
					var cell := CellData.new()
					if letter == CELL_BLOCKED:
						cell.is_blocked = true
					else:
						cell.value = CELL_VALUE.get(letter)
					cell_list[cell_coord] = cell
				cell_coord = _get_next_cell_coord(cell_coord, level_size, order)
			count = 0
			if cell_count == 0:
				break

	return cell_list


static func _get_next_cell_coord(
	last_coord: Vector2i, level_size: Vector2i, order: CellOrder
) -> Vector2i:
	var column := last_coord.x
	var row := last_coord.y

	match order:
		HORIZONTAL:
			column += 1
			if column >= level_size.x:
				column = 0
				row += 1

		VERTICAL:
			row += 1
			if row >= level_size.y:
				column += 1
				row = 0

	return Vector2i(column, row)


static func _decode_slider_list(encode_data: String, level_size: Vector2i) -> Dictionary[Vector2i, SliderData]:

	var slider_list: Dictionary[Vector2i, SliderData]
	var slider_count := level_size.x * 2 + level_size.y * 2
	var slider_coord := Vector2i.ZERO
	var count := 0

	for letter in encode_data:
		if letter.is_valid_int():
			if count > 0:
				count *= 10
			count += letter.to_int()
		else:
			if count > 0:
				slider_count -= count
				if slider_count < 0:
					return {}
				slider_coord = _get_next_slider_coord(slider_coord, level_size, count)
				count = 0

			var slider := SliderData.new()
			var encode_slider_data: String = SLIDER.get(letter) as String

			match encode_slider_data.split("_")[0]:
				ADD_EFFECT:
					slider.area_effect = Constants.Sliders.Effect.ADD
				SUBTRACT_EFFECT:
					slider.area_effect = Constants.Sliders.Effect.SUBTRACT
				CHANGE_SIGN_EFFECT:
					slider.area_effect = Constants.Sliders.Effect.CHANGE_SIGN
				BLOCK_EFFECT:
					slider.area_effect = Constants.Sliders.Effect.BLOCK

			match encode_slider_data.split("_")[1]:
				FULL_BEHAVIOR:
					slider.area_behavior = Constants.Sliders.Behavior.FULL
				BY_STEP_BEHAVIOR:
					slider.area_behavior = Constants.Sliders.Behavior.BY_STEP

			slider_list[slider_coord] = slider
			slider_coord = _get_next_slider_coord(slider_coord, level_size, 1)
			slider_count -= 1
			if slider_count == 0:
				break

	return slider_list


static func _get_next_slider_coord(
	last_coord: Vector2i, level_size: Vector2i, offset: int
) -> Vector2i:

	var edge := last_coord.x
	var pos := last_coord.y

	while offset > 0:
		pos += 1
		var max_pos := level_size.x if edge % 2 == 0 else level_size.y
		if pos >= max_pos:
			edge += 1
			pos = 0
		offset -= 1

	return Vector2i(edge, pos)
