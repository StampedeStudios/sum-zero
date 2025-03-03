class_name PlayMode extends Resource

@export var title: String ## Title show on selection menu
@export var icon: Texture2D ## Icon show on selection menu
@export var tutorial: TutorialData ## Tutorial show before start play
@export var unlock_level_id: int = -1 ## Level that allows unlocking (-1 to ignore)
