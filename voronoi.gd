extends GDScript

var queue = EventList.new()
var root = null
var directrix

class EventList:
	var contents = []
	
	func pop():
		return contents.pop_front()
	
	func push(event):
		var i = 0
		while i < contents.size() and contents[i].key < event.key:
			i += 1 
		contents.insert(i, event)
		
	func size():
		return contents.size()

class SiteEvent:
	var key
	var node
	
	func _init(new_node):
		node = new_node
		key = new_node.position.x

class CircleEvent:
	var key
	var parabola
	var valid
	
	func _init(new_parabola, new_key):
		key = new_key
		parabola = new_parabola
		valid = true

class Arc:
	var node
	var event
	var focus
	var left
	var left_edge
	var right
	var right_edge
	
	func _init(new_node):
		node = new_node
		focus = new_node.position
	
	func replace_with(parabola_a, parabola_c):
		parabola_a.left = left
		parabola_a.left_edge = left_edge
		if left:
			left.right = parabola_a
			
		parabola_c.right = right
		parabola_c.right_edge = right_edge
		if right:
			right.left = parabola_c

	func get_intersection(parabola, directrix):
		if not parabola:
			return null
		
		#1: ((x-v.x)^2)/(4*f) + v.y
		#1: x
		
		var f1 = ( focus.y - directrix ) / 2.0
		var f2 = ( parabola.focus.y - directrix ) / 2.0
		
		if f1 == f2:
			return null
		
		if f1 == 0 and f2 == 0:
			return null
		
		if f1 == 0:
			return [
				focus.x
			]
		if f2 == 0:
			return [
				parabola.focus.y
			]
	
		var V1 = Vector2( focus.x, (focus.y + directrix) / 2.0)
		var V2 = Vector2( parabola.focus.x, (parabola.focus.y + directrix) / 2.0)

		var F1 = 0.25 / f1
		var F2 = 0.25 / f2
		var a = F1 - F2
		var b = - 2.0 * ( F1 * V1.x - F2 * V2.x )
		var c = V1.y - V2.y + F1 * pow(V1.x, 2) - F2 * pow(V2.x, 2)

		if b*b < 4 * a * c:
			print("  intersection nulled because of imaginary results")
			return null
			
		if a == 0:
			return [
				-c / b
			]
		
		var x_1 = (-b + sqrt( b * b - 4 * a * c)) / (2 * a)
		var x_2 = (-b - sqrt( b * b - 4 * a * c)) / (2 * a)
		
		return [x_1, x_2]

	func get_limits(directrix):
		var l = get_intersection(left, directrix)
		var r = get_intersection(right, directrix)
		
		if not l and not r:
			return [null, null]	
		elif not l:
			r.sort()
			return [null, r[0]]
		elif not r:
			l.sort()
			return [l[l.size()-1], null]
		else:
			l.sort()
			r.sort()
			return [l[0], r[r.size()-1]]
			
		
		if not l:
			l = [null]
		l.sort()
		if not r:
			r = [null]
		r.sort()
		print("\t\tl=", l, " r=", r)
		return [l[l.size()-1], r[0]]
		
	func draw(node, directrix):
		var rect = node.get_viewport_rect()
		var width = rect.size.x
		var height = rect.size.y
		var limits = get_limits(directrix)
	
		if left_edge:
			node.draw_circle(left_edge.start, 3.0, Color.black)
			node.draw_line(left_edge.start, left_edge.start + 100 * left_edge.direction, Color.blue)
	
		if right_edge:
			node.draw_circle(right_edge.start, 3.0, Color.black)
			node.draw_line(right_edge.start, right_edge.start + 100 * right_edge.direction, Color.black)
	
		if directrix == focus.y:
			node.draw_line(focus, Vector2(focus.x, - focus.y - height / 2.0), Color.white)
			return
	
		#print("prelimits", limits)
		if typeof(limits[0]) == 0 or limits[ 0 ] < - width / 2.0:
			limits[0] = -width / 2.0
		if typeof(limits[1]) == 0 or limits[ 1 ] > width / 2.0:
			limits[1] = width / 2.0
	
		var points : PoolVector2Array;
		var V = Vector2(focus.x, (focus.y + directrix) / 2.0)
		var d = (directrix - focus.y) / 2.0
		
		#print("focus=", focus, " limits=", limits)
		for x in range(limits[0],limits[1]):
			points.append(Vector2(x, pow(x - V.x, 2) / (-4 * d) + V.y))
			points.append(Vector2(x+1, pow(x + 1 - V.x, 2) / (-4 * d) + V.y))
	
		if points.size() > 1:
			node.draw_polyline(points, Color.white)
		else:
			node.draw_circle(focus, 4.0, Color.red)

class Edge:
	var start
	var stop
	var direction
	var nodes
	
	func _init(new_nodes, new_start, new_direction):
		nodes = new_nodes
		start = new_start
		direction = new_direction
	
	func get_line_constants():
		# ax + by = c
		var a = 0.0; var b = 0.0; var c = 0.0;
		
		if direction == Vector2.ZERO:
			return
		elif direction.x == 0:
			a = 1.0
			b = 0.0
			c = start.x / direction.y
		elif direction.y == 0:
			a = 0.0
			b = 1.0
			c = start.y / direction.x
		else:
			a = -direction.y / direction.x
			b = 1.0 
			c = a * start.x + b * start.y
			
		return [a, b, c]

func voronoi(nodes, stop_at_y = null):
	var leftmost
	
	queue = EventList.new()
	root = null
	directrix = 0
	var polygons = []
	if not nodes:
		print("no nodes")
		return [polygons, null]
	
	for node in nodes:
		if not stop_at_y or node.position.y < stop_at_y:
			queue.push(SiteEvent.new(node))
	
	while queue.size() > 0:
		var event = queue.pop()
		directrix = event.key
		if event is SiteEvent:
			add_parabola(event.node)
		else:
			var edges = remove_parabola(event.parabola)
			polygons.append(edges)
	
	leftmost = root
	while leftmost and leftmost.left:
		leftmost = leftmost.left
	
	#while leftmost.right:
	#	if leftmost.right_edge:
	#		remaining_edges
	#		leftmost.right_edge.stop = leftmost.right_edge.start + leftmost.right_edge.direction * 1000
	#		polygons.append([leftmost.right_edge])
	#	leftmost = leftmost.right
	
	return [
		polygons,
		leftmost
	]

func get_polygons(nodes, stop_at_y = null):
	return voronoi(nodes, stop_at_y)[0]

func solve_parabola(parabola, point):
	var focus = parabola.focus
	var directrix = point.y
	var x = point.x

	var V = Vector2(focus.x, (focus.y + directrix) / 2.0)
	var d = (directrix - focus.y) / 2.0

	return Vector2(x, pow(x - V.x, 2) / (-4 * d) + V.y)

func add_parabola(node):
	if not root:
		root = Arc.new(node)
		return
	
	var parent = find_parabola_at_point(root, node.position.x)
	if parent.event:
		parent.event.valid = false
		
	var a = Arc.new(parent.node)
	var b = Arc.new(node)
	var c = Arc.new(parent.node)

	var edge_point = solve_parabola(parent, node.position)
	
	var xl = Edge.new([node, parent.node], edge_point, (a.focus-b.focus).tangent())
	var xr = Edge.new([node, parent.node], edge_point, (b.focus-c.focus).tangent())
	
	b.left = a
	a.right = b
	b.left_edge = xl
	a.right_edge = xl
	
	b.right = c
	c.left = b
	b.right_edge = xr
	c.left_edge = xr
	
	parent.replace_with(a, c)
	if parent == root:
		root = b
	
	check_circle_event(a)
	check_circle_event(c)
	
func find_parabola_at_point(node, point):
	if node.left and point < node.left_edge.start.x:
		return find_parabola_at_point(node.left, point)
	
	if node.right and point > node.right_edge.start.x:
		return find_parabola_at_point(node.right, point)
		
	return node

func remove_parabola(parabola):
	var left = parabola.left
	var right = parabola.right
	
	for side in [left, right]:
		if side.event:
			side.event.valid = false
	
	var s = circumcenter(left.focus, parabola.focus, right.focus)
	if not s:
		print("no circumcenter to remove parabola")
		return []
	var edge = Edge.new([left.node, right.node], s, (left.focus-right.focus).tangent())
	
	parabola.left_edge.stop = s
	parabola.right_edge.stop = s
	
	var output = [ parabola.left_edge, parabola.right_edge ]
	
	left.right = right
	left.right_edge = edge
	
	right.left = left
	right.left_edge = edge
	
	check_circle_event(left)
	check_circle_event(right)
	
	return output

func find_intersection(edge_1, edge_2, fail_if_behind=true):
	# a_1 * x + b_1 * y = c_1
	var a_1; var b_1; var c_1
	var a_2; var b_2; var c_2
	var p_1; var p_2

	if edge_1 is Edge:
		p_1 = edge_1.start
		var constants = edge_1.get_line_constants()
		if not constants:
			return
		a_1 = constants[0]
		b_1 = constants[1]
		c_1 = constants[2]
	else:
		a_1 = edge_1[0]
		b_1 = edge_1[1]
		c_1 = edge_1[2]
		p_1 = edge_1[3]
		
	if edge_2 is Edge:
		p_2 = edge_2.start
		var constants = edge_2.get_line_constants()
		if not constants:
			return
		a_2 = constants[0]
		b_2 = constants[1]
		c_2 = constants[2]
	else:
		a_2 = edge_2[0]
		b_2 = edge_2[1]
		c_2 = edge_2[2]
		p_2 = edge_2[3]
	
	if a_1 * b_2 == a_2 * b_1:
		return
	
	var x = (b_2 * c_1 - c_2 * b_1) / (a_1 * b_2 - a_2 * b_1 )
	var y
	
	if b_1 != 0:
		y = (c_1 - a_1 * x) / b_1
	elif b_2 != 0:
		y = (c_2 - a_2 * x) / b_2
	else:
		return
		
	var point = Vector2(x, y)
	if not fail_if_behind:
		return point
	
	if (a_1 != 0 and (point.x - p_1.x) / -a_1 < 0 ) or (b_1 != 0 and (point.y - p_1.y) / b_1 < 0):
		return
	elif (a_2 != 0 and (point.x - p_2.x) / -a_2 < 0) or (b_2 != 0 and (point.y - p_2.y) / b_2 < 0):
		return
	
	return point

func check_circle_event(parabola):
	var left = parabola.left
	var right = parabola.right
	var xl = parabola.left_edge
	var xr = parabola.right_edge

	if not left or not right or left.focus == right.focus:
		return

	var intersection_point = find_intersection(xl, xr)
	#print("intersection point for ", xl.direction, " @ ", xl.start)
	#print("                       ", xr.direction, " @ ", xr.start)
	#print("                     = ", intersection_point)
	if not intersection_point:
		return
	
	var r = intersection_point.distance_to(parabola.focus)
	if intersection_point.y + r < directrix:
		return
	
	var circle_event = CircleEvent.new(parabola, intersection_point.y + r)
	parabola.event = circle_event
	queue.push(circle_event)

func circumcenter(A, B, C):
	var AB = (A - B).tangent()
	var M_AB = (A + B) / 2.0
	
	var BC = (B - C).tangent()
	var M_BC = (B + C) / 2.0
	
	var d_AB = M_AB.y * AB.x - M_AB.x * AB.y
	var d_BC = M_BC.y * BC.x - M_BC.x * BC.y

	var O = find_intersection([
		AB.x, -AB.y, d_AB, M_AB
	], [
		BC.x, -BC.y, d_BC, M_BC
	], false)
	
	if not O:
		return
	
	return Vector2(O.y, O.x)
