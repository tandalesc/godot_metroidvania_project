extends Area2D

export (float, 1, 1000) var attack_strength = 300

onready var parent = $"../.."
onready var effects = $"../Effects"

var attack = false
	
func do_damage():
	if !attack:
		attack = true

func _physics_process(delta):
	var bodies = get_overlapping_bodies()
	if attack and len(bodies)>0:
		for body in bodies:
#			if body.name == 'Enemy':
#				hurt_enemy(body)
#			elif body.is_in_group('bodies'):
#				hurt_rigid_body(body)
			#generate sparks
			if body.name=='Foreground':
				effects.create_sparks()
		attack = false

func hurt_rigid_body(body):
	body.apply_central_impulse((body.global_position-parent.global_position).normalized() * parent.pushing_force * attack_strength)

func hurt_enemy(body):
	body.impulse += (body.global_position-parent.global_position).normalized().rotated(randf()) * 50 * attack_strength
	body.hurt(attack_strength)
