extends Area2D

@export_file("*.tscn") var target_scene: String

func _on_body_entered(body: Node2D) -> void:
	if body.name == "SirVey" and target_scene != "":
		get_tree().change_scene_to_file(target_scene)
