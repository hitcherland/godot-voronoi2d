extends Node2D 

#var Voronoi = load("res://voronoi.gd");
var directrix = 0
var arcs = []

class Parabola:
	extends Node2D

	var directrix setget _set_directrix
	var _v; var _f;
	var left_limit = null
	var right_limit = null
	
	func _init().():
		directrix = position.y
		_update_vertex()

	func _update_vertex():
		_f = (directrix - position.y) / 2.0
		_v = Vector2(0, _f)

	func _set_directrix(value):
		if not value:
			return directrix
		else:
			directrix = value
			_update_vertex()

	func calculate_y(x):
		if _f == 0:
			return null
		return pow(x - _v.x, 2.0) / (-4.0 * _f) + _v.y

	func _draw():
		var rect = get_viewport_rect()
		draw_circle(Vector2.ZERO, 2.0, Color.black)

		if _f == 0:
			draw_line(Vector2.ZERO, Vector2(0, -position.y), Color.white)
			return

		var points : PoolVector2Array;
		
		var left = rect.position.x - position.x
		if left_limit and left < left_limit:
			left = left_limit
		
		var right = rect.end.x - position.x
		if right_limit and right < right_limit:
			right = right_limit
		
		for x in range(rect.position.x - position.x, rect.end.x - position.x):
			points.append(Vector2(x, calculate_y(x)))
			points.append(Vector2(x, calculate_y(x+1)))
	
		draw_polyline(points, Color.white)
		
	
	func inside(x):
		if _f == 0:
			return x == position.x
		elif not left_limit and not right_limit:
			return true
		elif not left_limit:
			return x <= right_limit
		elif not right_limit:
			return x >= left_limit
		else:
			return x >= left_limit and x <= right_limit
	
	func get_intersection_points(parabola):
		# if no parabola, then we don't intersect
		if not parabola:
			return []
			
		# if we are the same parabola, we intersect everywhere, but we're going to
		# mark this as no intersection
		if _f == 0 and parabola._f == 0:
			return []
		
		# if we are both vertical line parabolas, we don't intersect
		# if one of us is a vertical line parabola, this makes our job easier
		if _f == 0 and parabola._f == 0:
			return []
		elif _f == 0:
			if parabola.inside(position.x):	
				return [Vector2(0, parabola.calculate_y(position.x - position.y) + position.y - parabola.position.y)]
			else:
				return []
		elif parabola._f == 0:
			if inside(parabola.position.x):
				return [Vector2(parabola.position.x - position.x, calculate_y(parabola.position.x - position.x))]
			else:
				return []
		
		# each parabola is described by y = (x-v.x)^2 / (4*f) + v.y
		var F1 = 0.25 / _f
		var F2 = 0.25 / parabola._f
		var V1 = _v
		var V2 = parabola._v + (parabola.position - position)
		
		var a = F1 - F2
		var b = - 2.0 * ( F1 * V1.x - F2 * V2.x )
		var c = V1.y - V2.y + F1 * pow(V1.x, 2) - F2 * pow(V2.x, 2)
		
		if b * b < 4 * a * c:
			return []
			
		if a == 0:
			if b == 0:
				return []
			var x = -c / b
			return [Vector2(x, calculate_y(x))]
		
		var x_1 = (-b + sqrt(b * b - 4 * a * c)) / (2 * a)
		var y_1 = calculate_y(x_1)
		var x_2 = (-b - sqrt(b * b - 4 * a * c)) / (2 * a)
		var y_2 = calculate_y(x_2)
		
		var output = []
		if typeof(y_1) != 0:
			output.append(Vector2(x_1, y_1))
			
		if typeof(y_2) != 0:
			output.append(Vector2(x_2, y_2))
			
		return output

func _draw():
	var rect = get_viewport_rect()
	draw_line(Vector2(rect.position.x - position.x, directrix),
			  Vector2(rect.end.x - position.x, directrix),
			  Color.white)
			
	var parabolas = []
	for child in get_children():
		if child is Parabola:
			parabolas.append(child)
	
	for i in range(parabolas.size()):
		var parabola_1 = parabolas[i]
		for j in range(i + 1, parabolas.size()):
			var parabola_2 = parabolas[j]
			var ips = parabola_1.get_intersection_points(parabola_2)
			print(parabola_1, ips)
			for ip in ips:
				if ip:
					print('\t', parabola_1.position + ip)
					draw_circle( parabola_1.position + ip, 3.0, Color.red)

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			get_tree().quit()

	if event is InputEventMouseButton and event.pressed:
		var parabola = Parabola.new()
		add_child(parabola)
		print(get_viewport_rect(), " ", event.position)
		parabola.position = event.position
	
	if event is InputEventMouseMotion:
		directrix = event.position.y
		for child in get_children():
			if child is Parabola:
				child.directrix = event.position.y
				child.update()
		update()

func _on_clear_all():
	for child in get_children():
		remove_child(child)
	update()
	
func _ready():
	var a = Parabola.new();
	a.position = Vector2(412, 300)
	add_child(a)
	var b = Parabola.new();
	b.position = Vector2(612, 400)
	add_child(b)
