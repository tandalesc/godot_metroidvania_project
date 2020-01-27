extends KinematicBody2D

const ACCELERATION = 20
const RUNNING_THRESHOLD = 0.5

const MAX_HEALTH = 100
const DEFAULT_PUSHING_FORCE = 25
const DEFAULT_JUMP_STRENGTH = 220
const DEFAULT_MAX_SPEED = 120
const DEFAULT_MAX_JUMPS = 1
const MAX_WALL_RIDE_SPEED = 100

const UNDERWATER_MAX_SPEED_Y = 40
const UNDERWATER_MAX_SPEED_X = 45

onready var state_machine = $AnimationTree['parameters/playback']
onready var player = $"../Player"
onready var physics_shape = $CollisionShape2D
onready var body = $Body
onready var player_detector = $"Body/PlayerDetectionArea"

var pushing_force = DEFAULT_PUSHING_FORCE
var max_speed = DEFAULT_MAX_SPEED
var jump_strength = DEFAULT_JUMP_STRENGTH
var max_jumps = DEFAULT_MAX_JUMPS

var health = MAX_HEALTH
var dist_to_player = -1
var attack_timeout = 0
var player_detected_and_visible = false
var underwater = false
var velocity = Vector2()
var impulse = Vector2()
	
func enter_water():
	underwater = true;
	max_speed = UNDERWATER_MAX_SPEED_X
	jump_strength = 180

func exit_water():
	underwater = false;
	max_speed = DEFAULT_MAX_SPEED
	jump_strength = DEFAULT_JUMP_STRENGTH

func hurt(dmg):
	if health - dmg < 0:
		die()
	else:
		health -= dmg

func die():
	queue_free()

func accept_power_up(key):
	match key:
		'double_jump':
			max_jumps = 2
		'super_strength':
			pushing_force = 150
		_:
			print('unsure what to do with this power-up')

func process_inputs(gravity, dampening):
	dist_to_player = player.global_position-global_position
	if player_detected_and_visible and dist_to_player.x > 30:
		if body.scale.x == 1:
			body.set_scale(Vector2(-1,1))
			body.translate(Vector2(12,0))
		velocity.x = min(velocity.x+ACCELERATION, max_speed)
	elif player_detected_and_visible and dist_to_player.x < -30:
		if body.scale.x == -1:
			body.set_scale(Vector2(1,1))
			body.translate(Vector2(-12,0))
		velocity.x = max(velocity.x-ACCELERATION, -max_speed)
	else:
		velocity.x = lerp(velocity.x, 0, dampening if is_on_floor() else 2*dampening/3)
	
	if player_detected_and_visible and dist_to_player.y < -50 and is_on_floor():
		velocity.y = -jump_strength

func update_state():
	var anim_name = state_machine.get_current_node()
	var is_attacking = anim_name=='attack_1'
	if is_on_floor():
		if !is_attacking:
			#should I attack?
			if dist_to_player.length() < 30 and attack_timeout<=0:
				state_machine.travel('attack_1')
				attack_timeout = 1
			else:
				state_machine.travel('run' if abs(velocity.x)>RUNNING_THRESHOLD else 'idle')

func animation_finished(anim_name):
	if anim_name=='attack_1':
		state_machine.travel('idle')

func _process(delta):
	update_state()
	if attack_timeout>0:
		attack_timeout-=delta

func _physics_process(delta):
	#fetch totaled values for gravity and dampening, inclusive of any area modifications
	var body_state = Physics2DServer.body_get_direct_state(get_rid())
	var space_state = get_world_2d().direct_space_state
	var gravity = body_state.total_gravity
	var dampening = body_state.total_linear_damp
	velocity += gravity + impulse
	process_inputs(gravity, dampening)
	#dampen all vertical motion in bodies of water
	if underwater and abs(velocity.y) > UNDERWATER_MAX_SPEED_Y:
		var clamped_velocity = clamp(velocity.y, -UNDERWATER_MAX_SPEED_Y, UNDERWATER_MAX_SPEED_Y)
		velocity.y = lerp(velocity.y, clamped_velocity, 0.04)
	velocity = move_and_slide(velocity, Vector2.UP, true, 4, PI/3, false)
	
	#if player is in the general vicinity, cast a ray to check if he's clearly visible
	if player_detector.player_detected() and !player_detected_and_visible:
		var result = space_state.intersect_ray(global_position, player.global_position, [self])
		if result and result.collider.name == "Player":
			player_detected_and_visible = true
	elif !player_detector.player_detected() and player_detected_and_visible:
		player_detected_and_visible = false
	
	impulse = Vector2.ZERO
	
	for index in get_slide_count():
		var collision = get_slide_collision(index)
		if collision.collider.is_in_group('bodies'):
			collision.collider.apply_central_impulse(-collision.normal * pushing_force)
	