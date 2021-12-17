extends Spatial

export var animate: bool = true

func _ready():
	if animate:
		$AnimationPlayer.play("Animation")
