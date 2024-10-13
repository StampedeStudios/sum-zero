class_name GlobalConst

enum AreaEffect { ADD, SUBTRACT, CHANGE_SIGN, BLOCK }
enum AreaBehavior { BY_STEP, FULL }
enum GameState {
	MAIN_MENU,
	LEVEL_START,
	LEVEL_END,
	BUILDER_IDLE,
	BUILDER_SELECTION,
	BUILDER_SAVE,
	BUILDER_TEST,
	BUILDER_RESIZE
}

const CELL_SIZE: float = 256
const SLIDER_SIZE: float = 128

const MIN_LEVEL_SIZE: int = 2
const MAX_LEVEL_SIZE: int = 5

const MIN_CELL_VALUE: int = -4
const MAX_CELL_VALUE: int = 4

const HALF_BUILDER_SELECTION: int = 300
