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
		if left:
			parabola_a.left = left
			left.right = parabola_a
			parabola_a.left_edge = left_edge
			
		if right:
			right.left = parabola_c
			parabola_c.right = right
			parabola_c.right_edge = right_edge

class Edge:
	var start
	var stop
	var direction
	
	func _init(new_start, new_direction):
		start = new_start
		direction = new_direction

func get_polygons(nodes):
	var polygons = []
	if not nodes:
		return polygons
	
	for node in nodes:
		queue.push(SiteEvent.new(node))
	
	while queue.size() > 0:
		var event = queue.pop()
		print( "new event: ", event.key, " ", event is SiteEvent)
		directrix = event.key
		if event is SiteEvent:
			add_parabola(event.node)
		else:
			var edges = remove_parabola(event.parabola)
			polygons.append(edges)
	
	var leftmost = root
	while leftmost.left:
		leftmost = leftmost.left
	
	while leftmost.right:
		if leftmost.right_edge:
			leftmost.right_edge.stop = leftmost.right_edge.start + leftmost.right_edge.direction * 1000
			polygons.append([
				leftmost.right_edge
			])
		leftmost = leftmost.right
			
	return polygons

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
	
	var xl = Edge.new(parent.focus, (a.focus-b.focus).tangent())
	var xr = Edge.new(parent.focus, (b.focus-c.focus).tangent())
	
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
	var edge = Edge.new(s, (left.focus-right.focus).tangent())
	
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
	var a_1; var b_1; var c_1
	var a_2; var b_2; var c_2
	var p_1; var p_2

	if edge_1 is Edge:
		a_1 = edge_1.direction.x
		b_1 = edge_1.direction.y
		c_1 = a_1 * edge_1.start.x + b_1 * edge_1.start.y
		p_1 = edge_1.start
	else:
		a_1 = edge_1[0]
		b_1 = edge_1[1]
		c_1 = edge_1[2]
		p_1 = edge_1[3]
		
	if edge_2 is Edge:
		a_2 = edge_2.direction.x
		b_2 = edge_2.direction.y
		c_2 = a_2 * edge_2.start.x + b_2 * edge_2.start.y
		p_2 = edge_2.start
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
		
	if (a_1 != 0 and (point.x - p_1.x) / a_1 < 0 ) or (b_1 != 0 and (point.y - p_1.y) / b_1 < 0):
		return
	elif (a_2 != 0 and (point.x - p_2.x) / a_2 < 0) or (b_2 != 0 and (point.y - p_2.y) / b_2 < 0):
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
	if not intersection_point:
		print('\t\tno intersection point', xl.start, " ",  xl.direction, " : ", xr.start, " ", xr.direction)
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
	
	print("\tcircumcenter: ", A, " ", B, " ", C, " => ", O)
	return O