extends Camera2D

export var duration = 0.8

onready var peek_tween = $CameraPeekTween

func look_y(y_offset):
	if self.offset.y != y_offset and not peek_tween.is_active():
		peek_tween.interpolate_property(self, ":offset:y", null, y_offset,
			duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.0)
		peek_tween.start()

func look_x(x_offset):
	if self.offset.x != x_offset and not peek_tween.is_active():
		peek_tween.interpolate_property(self, ":offset:x", null, x_offset,
			duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.0)
		peek_tween.start()
