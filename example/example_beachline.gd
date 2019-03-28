extends Node2D 

var Parabola = load("res://addons/Voronoi2D/parabola.gd");
var global_directrix

func _draw():
	var rect = get_viewport_rect()
	draw_line(Vector2(rect.position.x - position.x, global_directrix),
			  Vector2(rect.end.x - position.x, global_directrix),
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
			for ip in ips:
				if ip:
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
		global_directrix = event.position.y
		for child in get_children():
			if child is Parabola:
				child.directrix = event.position.y - child.position.y
				child.update()
		update()

func _on_clear_all():
	for child in get_children():
		remove_child(child)
	update()
