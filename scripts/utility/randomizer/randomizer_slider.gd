class_name RandomizerSlider

var reachable: Array[Vector2i]
var reached: Array[Vector2i]
var is_stopped: bool
var effect: GlobalConst.AreaEffect
var behavior: GlobalConst.AreaBehavior


func is_full() -> bool:
	return reachable.size() == reached.size()


func is_none() -> bool:
	return reached.is_empty()
