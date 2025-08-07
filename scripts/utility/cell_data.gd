## Defines basic information of a cell.
class_name CellData extends Resource

## If blocked by default.
@export var is_blocked: bool

## Value of the cell. Typically all values are in range -4, +4 because out of this range,
## values cannot be reduced to zero. However, each tile needs to support up to 16 different
## colors since in builder is allowed to create such conditions.
@export_range(-8, 8) var value: int
