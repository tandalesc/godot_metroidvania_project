extends KinematicBody2D

const ACCELERATION = 12
const RUNNING_THRESHOLD = 0.5

const DEFAULT_PUSHING_FORCE = 0
const DEFAULT_JUMP_STRENGTH = 300
const DEFAULT_MAX_SPEED = 120
const DEFAULT_MAX_JUMPS = 1
const MAX_WALL_RIDE_SPEED = 100
const JUMP_MULTIPLIER_LOW = 1.5
const JUMP_MULTIPLIER_HIGH = 1.7
const UNDERWATER_JUMP_STRENGTH = 240
const UNDERWATER_MAX_SPEED_Y = 45
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
var lookup_timer = 0
var lookdown_timer = 0
var underwater = false
var head_under_water = false
var was_on_floor = false
var velocity = Vector2()

onready var joystick = $"../TouchscreenControls/JoystickGroup/JoystickBase/Joystick"
onready var head_position = $Body/HeadPosition
onready var underwater_timer = $UnderwaterTimer
onready var hang_timer = $HangTimer
onready var camera = $Camera2D
onready var effects = $Body/Effects
onready var state_machine = $AnimationTree['parameters/playback']
onready var body = $Body

func enter_water():
	underwater = true;
	underwater_timer.start()
	#make hitting the water slow you down instantly
	if velocity.y > UNDERWATER_MAX_SPEED_Y:
		velocity.y = UNDERWATER_MAX_SPEED_Y
	max_speed = UNDERWATER_MAX_SPEED_X

func exit_water():
	underwater = false;
	underwater_timer.stop()
	max_speed = DEFAULT_MAX_SPEED

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

func process_inputs(gravity, dampening, dt):
	var analog_input = Vector2.ZERO if joystick==null else joystick.get_value()
	if Input.is_action_pressed('ui_right'):
		analog_input += Vector2.RIGHT
	if Input.is_action_pressed('ui_left'):
		analog_input += Vector2.LEFT
	if Input.is_action_pressed('ui_up'):
		analog_input += Vector2.DOWN
	if Input.is_action_pressed('ui_down'):
		analog_input += Vector2.UP
	var right_pressed = analog_input.x > 0
	var left_pressed = analog_input.x < 0
	var up_pressed = analog_input.y > 0
	var down_pressed = analog_input.y < 0
	var jump_pressed = Input.is_action_just_pressed('jump')
	var attack_pressed = Input.is_action_just_pressed('attack')
	var anim_name = state_machine.get_current_node()
	#different speed multipliers for each stance the player is in
	var speed_multiplier = max_speed/5 if player_state==State.ATTACK else max_speed
	var input_fade = pow(abs(analog_input.x), 2)
	var y_dir_not_pressed = not up_pressed and not down_pressed

	if right_pressed:
		face_direction(1)
		velocity.x = min(velocity.x+ACCELERATION, speed_multiplier)*input_fade
	elif left_pressed:
		face_direction(-1)
		velocity.x = max(velocity.x-ACCELERATION, -speed_multiplier)*input_fade
	else:
		velocity.x = lerp(velocity.x, 0, dampening if is_on_floor() else 2*dampening/3)
		camera.look_x(0)
		#loop up and down
		if up_pressed:
			lookup_timer += dt
			if lookup_timer > 0.7:
				camera.look_y(-70.0)
		elif lookup_timer > 0:
			lookup_timer = 0
		if down_pressed:
			lookdown_timer += dt
			if lookdown_timer > 0.7:
				camera.look_y(50.0)
		elif lookdown_timer > 0:
			lookdown_timer = 0
	#reset camera position if not looking up or down
	if y_dir_not_pressed:
		camera.look_y(-20.0)
		
	if jump_pressed:
		if player_state == State.ATTACK:
			state_machine.travel('sheath_sword')
		elif ((is_on_floor() or hang_timer.time_left>0) and jumps_taken < max_jumps) or jumps_taken < max_jumps:
			#allow multiple jumps upto a soft limit
			jumps_taken += 1
			velocity.y = -jump_strength
			state_machine.start('jump_start')
		if anim_name == 'wall_ride':
			var facing_left = (body.scale.x==-1)
			velocity.y = 1.3*(-jump_strength)
			velocity.x = 0.65*(jump_strength if facing_left else -jump_strength)
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
			if hang_timer.is_stopped(): hang_timer.start()
			state_machine.start('jump_peak')
		
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
	var body_state = Physics2DServer.body_get_direct_state(get_rid())
	var space_state = get_world_2d().direct_space_state
	var gravity = body_state.total_gravity
	var dampening = body_state.total_linear_damp
	velocity += gravity
	process_inputs(gravity, dampening, delta)
	#multiply gravity depending on input state
	if velocity.y > 0:
		velocity += gravity * (JUMP_MULTIPLIER_HIGH-1)
	elif !is_on_floor() and !Input.is_action_pressed('jump'):
		velocity += gravity * (JUMP_MULTIPLIER_LOW-1)
	#clamp vertical movement speed if clinging to wall
	if state_machine.get_current_node() == 'wall_ride':
		var clamped_velocity = clamp(velocity.y, 0.0, MAX_WALL_RIDE_SPEED);
		velocity.y = lerp(velocity.y, clamped_velocity, 0.4);
	#dampen all vertical motion in bodies of water
	if underwater and abs(velocity.y) > UNDERWATER_MAX_SPEED_Y:
		var clamped_velocity = clamp(velocity.y, -UNDERWATER_MAX_SPEED_Y, UNDERWATER_MAX_SPEED_Y)
		velocity.y = lerp(velocity.y, clamped_velocity, 0.08)
	#terminal velocity
	velocity.y = min(velocity.y, 1000)
	
	#required for kinematicbody physics
	#parameters: ground normal, stop on slope, max bounces, max slope angle, infinite intertia
	velocity = move_and_slide(velocity, Vector2.UP, true, 4, PI/4, false)
	
	#check if head is underwater
	if underwater:
		var head_pos_scan_result = space_state.intersect_point(head_position.global_position, 8, [self], collision_mask, false, true)
		head_under_water = false
		if not head_pos_scan_result.empty():
			for result in head_pos_scan_result:
				var collider = result.collider
				if collider.is_in_group('water'):
					head_under_water = true
	
	#apply pushing force to rigid bodies
	for index in get_slide_count():
		var collision = get_slide_collision(index)
		if collision.collider.is_in_group('bodies'):
			collision.collider.apply_central_impulse(-collision.normal * pushing_force)
	


func _on_UnderwaterTimer_timeout():
	if underwater and head_under_water:
		effects.create_bubbles()
		#make bubble particles
		underwater_timer.start()


func _on_HangTimer_timeout():
	jumps_taken += 1
