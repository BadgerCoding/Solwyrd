extends CharacterBody2D
@onready var area = $Area2D
func _ready() -> void:
	area.body_entered.connect(_on_mouse_entered)

func _on_mouse_entered() -> void:
	print("test")
