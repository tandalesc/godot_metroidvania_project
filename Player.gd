extends KinematicBody2D

const ACCELERATION = 20
const RUNNING_THRESHOLD = 0.5

const DEFAULT_JUMP_STRENGTH = 250
const DEFAULT_MAX_SPEED = 120
const DEFAULT_MAX_JUMPS = 1

const UNDERWATER_MAX_SPEED_Y = 40
const UNDERWATER_MAX_SPEED_X = 45

var state_machine
var max_speed = DEFAULT_MAX_SPEED
var jump_strength = DEFAULT_JUMP_STRENGTH
var max_jumps = DEFAULT_MAX_JUMPS
var jumps_taken = 0
var underwater = false
var velocity = Vector2()

func _ready():
	state_machine = $AnimationTree['parameters/playback']
	for water in get_parent().get_node('World/WaterAreas').get_children():
		water.connect('body_entered', self, 'potential_water_immersion')
		water.connect('body_exited', self, 'potential_water_departure')
	update_properties()

func potential_water_immersion(body):
	if !underwater and body.name == self.name:
		underwater = true
		update_properties()

func potential_water_departure(body):
	if underwater and body.name == self.name:
		underwater = false
		update_properties()

func update_properties():
	var bubble_emitter = get_node('UnderwaterBubbles')
	if underwater:
		max_speed = UNDERWATER_MAX_SPEED_X
		jump_strength = 180
		bubble_emitter.emitting = true
		bubble_emitter.show()
	else:
		max_speed = DEFAULT_MAX_SPEED
		jump_strength = DEFAULT_JUMP_STRENGTH
		bubble_emitter.emitting = false
		bubble_emitter.hide()

func accept_power_up(key):
	match key:
		'double_jump':
			max_jumps = 2
		_:
			print('unsure what to do with this power-up')

func process_inputs(gravity, dampening):
	if Input.is_action_pressed('ui_right'):
		$Sprite.flip_h = false
		velocity.x = min(velocity.x+ACCELERATION, max_speed)
	elif Input.is_action_pressed('ui_left'):
		$Sprite.flip_h = true
		velocity.x = max(velocity.x-ACCELERATION, -max_speed)
	else:
		velocity.x = lerp(velocity.x, 0, dampening if is_on_floor() else dampening/2)
		
	if Input.is_action_just_pressed('ui_accept'):
		#allow multiple jumps upto a soft limit
		if is_on_floor() or jumps_taken < max_jumps:
			jumps_taken += 1
			velocity.y = -jump_strength
			state_machine.start('jump_start')

func update_animations():
	var anim_name = state_machine.get_current_node()
	#handle compound jump animation
	if anim_name == 'jump_start' and velocity.y>5:
		state_machine.travel('jump_peak')
	if anim_name == 'jump_peak' and is_on_floor():
		#state machine will take us through jump_landing and then to idle
		state_machine.travel('idle')
		jumps_taken = 0
		
	if anim_name == 'run' or anim_name == 'idle':
		if is_on_floor():
			state_machine.travel('run' if abs(velocity.x)>RUNNING_THRESHOLD else 'idle')
		else:
			#handle running off the edge of a platform
			state_machine.start('jump_peak')
			#allow user one extra jump, not two
			jumps_taken += 1

func _process(delta):
	update_animations()

func _physics_process(delta):
	#fetch totaled values for gravity and dampening, inclusive of any area modifications
	var space_state = Physics2DServer.body_get_direct_state(get_rid())
	var gravity = space_state.total_gravity
	var dampening = space_state.total_linear_damp
	velocity += gravity
	process_inputs(gravity, dampening)
	#dampen all vertical motion in bodies of water
	if underwater and abs(velocity.y) > UNDERWATER_MAX_SPEED_Y:
		var clamped_velocity = clamp(velocity.y, -UNDERWATER_MAX_SPEED_Y, UNDERWATER_MAX_SPEED_Y)
		velocity.y = lerp(velocity.y, clamped_velocity, 0.04)
	velocity = move_and_slide(velocity, Vector2.UP, 100, 4, PI/4)