extends Node2D

var Voronoi = load("res://voronoi.gd").new();

export(int) var child_count = 3 setget update_child_count
export(float) var boundary_size = 100 setget update_boundary_size
export(bool) var refresh_random = true
export(bool) var use_mouse_as_limit = false
var limit = null
# Called when the node enters the scene tree for the first time.
func _ready():
	if refresh_random:
		randomize()
	var rect = get_viewport_rect()
	var min_value = min(rect.size.x/2.0, rect.size.y/2.0)
	generate_children()
	update_boundary_size(min_value)

func draw_parabola(focus, directrix):
	var points : PoolVector2Array;
	var dt = 0.1
	for x in range(-3 / dt, 3 / dt):
		points.append(Vector2(x * dt, pow(x * dt, 2) / (-4 * directrix)))
		points.append(Vector2((x +1)* dt, pow((x + 1)* dt, 2) / (-4 * directrix)))
	print("drawing parabola")
	draw_polyline(points, Color.white)

func _draw():
	for child in get_children():
		draw_circle(child.position, 2, Color.green)

	var rect = get_viewport_rect()
	var width = rect.size.x
	var height = rect.size.y

	if not use_mouse_as_limit:
		limit = null
	elif limit:
		draw_line(Vector2(-width/2.0, limit), Vector2(width/2.0, limit), Color.red)
	
	print(limit)
	var output = Voronoi.voronoi(get_children(), limit)
	var polygons = output[0]
	var leftovers = output[1]
		
	for polygon in polygons:
		for line in polygon:
			draw_line(line.start, line.stop, Color.blue)
	
	if limit:
		print("trying to draw leftovers...", leftovers)
		while leftovers:
			draw_parabola(leftovers.focus, limit)
			leftovers = leftovers.right

func _input(event):
	if use_mouse_as_limit and event is InputEventMouseMotion:
		limit = event.position.y - get_viewport_rect().size.y / 2.0
		update()

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

func generate_child():
	var child = Node2D.new()
	add_child(child)
	child.position.x = boundary_size * rand_range(-1,1)
	child.position.y = boundary_size * rand_range(-1,1)	
	
func generate_children():
	for i in range(child_count):
		generate_child()
	
func _on_randomise():
	cleanup()
	generate_children()
	update()
	
func _on_add_node_1():
	child_count += 1
	generate_child()
	update()

func _on_add_node_10():
	child_count += 10
	for i in range(10):
		generate_child()
	update()
	
func _on_remove_node_1():
	child_count -= 1
	remove_child(get_child(get_child_count()-1))
	update()

func _on_remove_node_10():
	child_count -= 10
	for i in range(10):
		remove_child(get_child(get_child_count()-1))
	update()