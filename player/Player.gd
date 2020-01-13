extends KinematicBody2D

const ACCELERATION = 12
const RUNNING_THRESHOLD = 0.5

const DEFAULT_PUSHING_FORCE = 0
const DEFAULT_JUMP_STRENGTH = 250
const DEFAULT_MAX_SPEED = 120
const DEFAULT_MAX_JUMPS = 1
const MAX_WALL_RIDE_SPEED = 100

const UNDERWATER_MAX_SPEED_Y = 40
const UNDERWATER_MAX_SPEED_X = 45

var pushing_force = DEFAULT_PUSHING_FORCE
var max_speed = DEFAULT_MAX_SPEED
var jump_strength = DEFAULT_JUMP_STRENGTH
var max_jumps = DEFAULT_MAX_JUMPS

enum State {
	MOVEMENT,
	ATTACK
}

var player_state = State.MOVEMENT
var pause_movement = false
var jumps_taken = 0
var attack_timer = 0
var underwater = false
var velocity = Vector2()

onready var joystick = $"../TouchscreenControls/JoystickGroup/JoystickBase/Joystick"
onready var state_machine = $AnimationTree['parameters/playback']
onready var body = $Body

func enter_water():
	underwater = true;
	max_speed = UNDERWATER_MAX_SPEED_X
	jump_strength = 180

func exit_water():
	underwater = false;
	max_speed = DEFAULT_MAX_SPEED
	jump_strength = DEFAULT_JUMP_STRENGTH

func accept_power_up(key):
	match key:
		'double_jump':
			max_jumps = 2
		'super_strength':
			pushing_force = 150
		_:
			print('unsure what to do with this power-up')

func face_direction(dir):
	if dir != body.scale.x:
		body.set_scale(Vector2(dir, 1))

func process_inputs(gravity, dampening):
	var analog_input = Vector2.ZERO if joystick==null else joystick.get_value()
	if Input.is_action_pressed('ui_right'):
		analog_input += Vector2.RIGHT
	if Input.is_action_pressed('ui_left'):
		analog_input += Vector2.LEFT
	var right_pressed = analog_input.x > 0
	var left_pressed = analog_input.x < 0
	var jump_pressed = Input.is_action_just_pressed('jump')
	var attack_pressed = Input.is_action_just_pressed('attack')
	var anim_name = state_machine.get_current_node()
	#different speed multipliers for each stance the player is in
	var speed_multiplier = max_speed/5 if player_state==State.ATTACK else max_speed
	var input_fade = pow(abs(analog_input.x), 2)

	if right_pressed:
		face_direction(1)
		velocity.x = min(velocity.x+ACCELERATION, speed_multiplier)*input_fade
	elif left_pressed:
		face_direction(-1)
		velocity.x = max(velocity.x-ACCELERATION, -speed_multiplier)*input_fade
	else:
		velocity.x = lerp(velocity.x, 0, dampening if is_on_floor() else 2*dampening/3)
		
	if jump_pressed:
		if player_state == State.ATTACK:
			state_machine.travel('sheath_sword')
		elif is_on_floor() or jumps_taken < max_jumps:
			#allow multiple jumps upto a soft limit
			jumps_taken += 1
			velocity.y = -jump_strength
			state_machine.start('jump_start')
		if anim_name == 'wall_ride':
			var facing_left = (body.scale.x==-1)
			velocity.y = 1.1*(-jump_strength)
			velocity.x = 1.0*(jump_strength if facing_left else -jump_strength)
			face_direction(body.scale.x * -1)
			state_machine.start('jump_start')
	
	if attack_pressed and is_on_floor():
		attack_timer = OS.get_ticks_msec() + 8000
		if player_state == State.MOVEMENT and abs(velocity.x)<max_speed*0.8:
			state_machine.travel('draw_sword')
		elif player_state == State.ATTACK and abs(velocity.x)<30:
			if anim_name=='attack_2':
				state_machine.travel('attack_3')
			elif anim_name=='attack_1':
				state_machine.travel('attack_2')
			else:
				state_machine.travel('attack_1')

func update_animations():
	var right_pressed = Input.is_action_pressed('ui_right')
	var left_pressed = Input.is_action_pressed('ui_left')
	
	var anim_name = state_machine.get_current_node()
	if is_on_floor():
		if player_state == State.MOVEMENT and anim_name != 'draw_sword':
			if abs(velocity.x)<RUNNING_THRESHOLD and !right_pressed and !left_pressed:
				state_machine.travel('idle')
			else:
				state_machine.travel('run')
		if jumps_taken > 0:
			jumps_taken = 0
	elif anim_name == 'jump_start' or anim_name == 'jump_peak':
		if velocity.y>-0.5 and is_on_wall():
			state_machine.travel('wall_ride')
		elif anim_name == 'jump_start' and velocity.y>5:
			state_machine.travel('jump_peak')
	
	#handle running off the edge of a platform
	if !is_on_floor() and (anim_name == 'idle' or anim_name == 'run' or anim_name == 'attack_stance' or (anim_name == 'wall_ride' and !is_on_wall())):
		if player_state == State.ATTACK:
			state_machine.travel('sheath_sword')
		else:
			state_machine.start('jump_peak')
		#allow user one extra jump, no more
		jumps_taken += 1
		
	if player_state == State.ATTACK:
		#end attack stance, go back to idle
		if attack_timer < OS.get_ticks_msec():
			state_machine.travel('sheath_sword')
		

func animation_finished(anim_name):
	if anim_name == 'attack_1' or anim_name == 'attack_2' or anim_name == 'attack_3':
		state_machine.travel('attack_stance')
	elif anim_name == 'sheath_sword':
		player_state = State.MOVEMENT
		state_machine.travel('idle')
	elif anim_name == 'draw_sword':
		player_state = State.ATTACK
		state_machine.travel('attack_stance')
		

func _process(delta):
	update_animations()

func _physics_process(delta):
	if pause_movement:
		return
	#fetch totaled values for gravity and dampening, inclusive of any area modifications
	var space_state = Physics2DServer.body_get_direct_state(get_rid())
	var gravity = space_state.total_gravity
	var dampening = space_state.total_linear_damp
	velocity += gravity
	process_inputs(gravity, dampening)
	#clamp vertical movement speed if clinging to wall
	if state_machine.get_current_node() == 'wall_ride':
		var clamped_velocity = clamp(velocity.y, 0.0, MAX_WALL_RIDE_SPEED);
		velocity.y = lerp(velocity.y, clamped_velocity, 0.3);
	#dampen all vertical motion in bodies of water
	if underwater and abs(velocity.y) > UNDERWATER_MAX_SPEED_Y:
		var clamped_velocity = clamp(velocity.y, -UNDERWATER_MAX_SPEED_Y, UNDERWATER_MAX_SPEED_Y)
		velocity.y = lerp(velocity.y, clamped_velocity, 0.04)
	#terminal velocity
	velocity.y = min(velocity.y, 1000)
	
	#required for kinematicbody physics
	#parameters: ground normal, stop on slope, max bounces, max slope angle, infinite intertia
	velocity = move_and_slide(velocity, Vector2.UP, true, 4, PI/4, false)
	
	#apply pushing force to rigid bodies
	for index in get_slide_count():
		var collision = get_slide_collision(index)
		if collision.collider.is_in_group('bodies'):
			collision.collider.apply_central_impulse(-collision.normal * pushing_force)
	