extends CanvasLayer

export (float, 1, 300) var padding_left = 150
export (float, 1, 300) var padding_right = 150
export (float, 1, 300) var padding_bottom = 120

onready var joystick_group = $JoystickGroup
onready var button_group = $ButtonGroup

func _ready():
	get_viewport().connect('size_changed', self, 'place_controls')
	place_controls()

func place_controls():
	var width = get_viewport().get_visible_rect().size.x
	var height = get_viewport().get_visible_rect().size.y
	joystick_group.set_position(Vector2(padding_left, height-padding_bottom))
	button_group.set_position(Vector2(width-padding_right, height-padding_bottom))
