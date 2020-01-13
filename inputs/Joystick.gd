extends TouchScreenButton

export (float, 0, 100) var boundary = 80
export (float, 0, 25) var deadzone = 5
export (float, 0, 128) var offset_from_parent = 32

onready var radius = Vector2(shape.radius, shape.radius)
onready var offset = Vector2(offset_from_parent, offset_from_parent)
#handle multitouch cases
var ongoing_drag: int = -1

func _process(delta):
	#smoothly move joystick back to center
	if ongoing_drag == -1:
		var dist_from_center = offset - position
		position += dist_from_center * delta * 20

func _input(event):
	if event is InputEventScreenDrag or (event is InputEventScreenTouch and event.is_pressed()):
		var event_dist_from_center = (event.position - (global_position + radius)).length()
		#only track touches starting within the touch region on screen, but also handle multitouch cases
		if event_dist_from_center <= boundary * global_scale.x or event.get_index() == ongoing_drag:
			set_global_position(event.position - radius * global_scale)
			var button_delta = position - offset
			if button_delta.length() > boundary:
				set_position(button_delta.normalized() * boundary + offset)
			ongoing_drag = event.get_index()
	#handle releasing joystick
	if event is InputEventScreenTouch and !event.is_pressed() and event.get_index() == ongoing_drag:
		ongoing_drag = -1

func get_value():
	var button_delta = position - offset
	if button_delta.length() > deadzone:
		return button_delta.normalized()
	else: return Vector2.ZERO