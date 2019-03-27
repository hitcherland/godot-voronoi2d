extends Node2D

var Voronoi = load("res://voronoi.gd").new();

export var child_count = 3 setget update_child_count
export(float) var boundary_size = 100 setget update_boundary_size
export(bool) var refresh_random = true
export(bool) var use_mouse_as_limit = false
var limit = null

func _ready():
	if refresh_random:
		randomize()
	var rect = get_viewport_rect()
	var min_value = min(rect.size.x/2.0, rect.size.y/2.0) * 0.8
	generate_children()
	update_boundary_size(min_value)

func draw_parabola(parabola, directrix):
	var rect = get_viewport_rect()
	var width = rect.size.x
	var height = rect.size.y
	var focus = parabola.focus

	if parabola.left_edge:
		draw_circle(parabola.left_edge.start,3.0, Color.black)
		draw_line(parabola.left_edge.start, parabola.left_edge.start + 100 * parabola.left_edge.direction, Color.blue)

	if parabola.right_edge:
		draw_circle(parabola.right_edge.start,3.0, Color.black)
		draw_line(parabola.right_edge.start, parabola.right_edge.start + 100 * parabola.right_edge.direction, Color.black)

	if directrix == focus.y:
		draw_line(focus, Vector2(focus.x, focus.y - height / 2.0), Color.white)
		return

	var limits = parabola.get_limits(directrix)
	print(limits)
	if not limits[0]:
		limits[0] = -width / 2.0

	if not limits[1]:
		limits[1] = width / 2.0
	print('\t',limits)

	var points : PoolVector2Array;
	var V = Vector2(focus.x, (focus.y + directrix) / 2.0)
	var d = (directrix - focus.y) / 2.0
	for x in range(limits[0], limits[1]):
		points.append(
			Vector2(x, 
					pow(x - V.x, 2) / (-4 * d) + V.y)
		)
		points.append(
			Vector2(x + 1,
					pow(x + 1 - V.x, 2) / (-4 * d) + V.y)
		)
	draw_polyline(points, Color.white)




func _draw():
	for child in get_children():
		draw_circle(child.position, 2, Color.green)

	var rect = get_viewport_rect()
	var width = rect.size.x

	if not use_mouse_as_limit:
		limit = null
	elif limit:
		draw_line(Vector2(-width/2.0, limit), Vector2(width/2.0, limit), Color.red)
	
	var output = Voronoi.voronoi(get_children(), limit)
	var polygons = output[0]
	var leftovers = output[1]
		
	for polygon in polygons:
		for line in polygon:
			if line.stop:
				draw_circle(line.stop, line.stop.distance_to(line.nodes[0].position), Color(1,1,0,0.1))
				draw_line(line.start, line.stop, Color.green)
			else:
				draw_line(line.start, line.start + 100 * line.direction, Color.pink)

	if limit:
		while leftovers:
			draw_parabola(leftovers, limit)
			leftovers = leftovers.right

func _input(event):
	if use_mouse_as_limit and event is InputEventMouseMotion:
		limit = event.position.y - get_viewport_rect().size.y / 2.0
		update()
	
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			get_tree().quit()

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
