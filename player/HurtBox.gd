extends Area2D

export (float, 1, 1000) var attack_strength = 300

onready var player = $"../.."
onready var collision_shape = $CollisionShape2D
onready var sparks = $"../Effects/Sparks"

var attack = false
	
func do_damage():
	if !attack:
		attack = true

func _physics_process(delta):
	if attack and len(get_overlapping_bodies())>0:
		for body in get_overlapping_bodies():
			if body.name == 'Enemy':
				hurt_enemy(body)
			elif body.is_in_group('bodies'):
				hurt_rigid_body(body)
			#generate sparks
			if body.name == 'Platforms' or body.is_in_group('bodies'):
				#todo improve positioning and responsiveness
				sparks.emitting = true
				sparks.restart()
		attack = false

func hurt_rigid_body(body):
	body.apply_central_impulse((body.global_position-player.global_position).normalized() * attack_strength * 10)

func hurt_enemy(body):
	body.impulse += (body.global_position-player.global_position).normalized().rotated(randf()) * attack_strength
	body.hurt(10)