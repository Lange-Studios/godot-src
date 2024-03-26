extends Node3D

var scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	scene = load("res://box.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	add_child(scene.instantiate())
