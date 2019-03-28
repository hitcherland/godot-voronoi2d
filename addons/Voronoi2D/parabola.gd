tool
extends Node2D

export var directrix : float = 0.0 setget _set_directrix
var _v; var _f;
export var left_limit: float = -INF setget _set_left_limit
export var right_limit: float = INF setget _set_right_limit

func _init().():
	directrix = position.y
	_update_vertex()

func _set_left_limit(value):
	if not value:
		return left_limit
	else:
		left_limit = value
		update()

func _set_right_limit(value):
	if not value:
		return right_limit
	else:
		right_limit = value
		update()

func _update_vertex():
	#_f = (directrix - position.y) / 2.0
	_f = directrix / 2.0
	_v = Vector2(0, _f)
	update()

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

func calculate_x(y):
	if _f == 0:
		return [ 0, 0 ]
		
	var F = 0.25 / _f
	var a = F
	var b = -2.0 * _v.x * F
	var c = F * _v.x * _v.x + _v.y - y
	print( b * b, " < ", 4 * a * c)
	if b * b < 4.0 * a * c:
		return null
	else:
		var output = [
			-b + sqrt(b*b - 4.0 * a * c) / (2.0 * a),
			-b - sqrt(b*b - 4.0 * a * c) / (2.0 * a),
		]
		output.sort()
		return
	

func _draw():
	var rect = get_viewport_rect()
	draw_circle(Vector2.ZERO, 2.0, Color.black)

	if _f == 0:
		draw_line(Vector2.ZERO, Vector2(0, -position.y), Color.white)
		return
	
	var top = calculate_x(rect.position.y - position.y)
	var bottom = calculate_x(rect.end.y - position.y)
	
	print("top_bottom intersects ", top, " ", bottom)
	
	var left = rect.position.x - position.x
	if left_limit and left < left_limit:
		left = left_limit
		
	if top and left < top[0]:
		left = top[0]
	if bottom and left < bottom[0]:
		left = bottom[0]
	
	var right = rect.end.x - position.x
	if right_limit and right > right_limit:
		right = right_limit
		
	if top and right > top[1]:
		right = top[1]
	if bottom and right > bottom[1]:
		right = bottom[1]

	var points : PoolVector2Array;
	for x in range(left, right):
		points.append(Vector2(x, calculate_y(x)))
		points.append(Vector2(x+1, calculate_y(x+1)))

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
