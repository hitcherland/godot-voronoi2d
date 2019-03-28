tool
extends EditorPlugin

var Parabola = preload("res://addons/Voronoi2D/parabola.gd");
var Icon = preload("res://addons/Voronoi2D/icon.png")

func _enter_tree():
	add_custom_type("Parabola", "Node2D", Parabola, Icon)
	
func _exit_tree():
	remove_custom_type("Parabola")