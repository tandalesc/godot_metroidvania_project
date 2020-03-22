extends Node2D

onready var sparks_node = preload("res://player/effects/Sparks.tscn")
onready var bubbles_node = preload("res://player/effects/Bubbles.tscn")

func create_sparks():
	var sparks = sparks_node.instance()
	sparks.one_shot = true
	sparks.emitting = true
	add_child(sparks)

func create_bubbles():
	var bubbles = bubbles_node.instance()
	bubbles.one_shot = true
	bubbles.emitting = true
	add_child(bubbles)

func _process(delta):
	for child in get_children():
		#delete all one shot Particles2D children that are done emitting
		if child is Particles2D and child.one_shot and not child.emitting:
			child.call_deferred("queue_free")
