extends Node2D

var Voronoi = load("res://Voronoi.gd").new();

export(int) var child_count = 10 setget update_child_count
export(float) var boundary_size = 100 setget update_boundary_size
export(bool) var refresh_random = true

# Called when the node enters the scene tree for the first time.
func _ready():
	if refresh_random:
		randomize()
	generate_children()
	update()

func _draw():
	for child in get_children():
		draw_circle(child.position, 2, Color.green)
	var polygons = Voronoi.get_polygons(get_children())
	for polygon in polygons:
		for line in polygon:
			draw_line(line.start, line.stop, Color.blue)

func update_child_count(value):
	child_count = value
	cleanup()
	generate_children()
	update()
	
func update_boundary_size(value):
	for child in get_children():
		child.position *= value / boundary_size
	boundary_size = value
	update()
	
func cleanup():
	for child in get_children():
		remove_child(child)

func generate_children():
	for i in range(child_count):
		var child = Node2D.new()
		add_child(child)
		child.position.x = boundary_size * rand_range(-1,1)
		child.position.y = boundary_size * rand_range(-1,1)