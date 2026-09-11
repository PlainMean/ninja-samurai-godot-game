class_name StrikeSpec
extends Resource
enum Defense { NONE, BLOCK, DODGE }
@export var defense_required: Defense = Defense.BLOCK
@export var warning_ms: int = 900
