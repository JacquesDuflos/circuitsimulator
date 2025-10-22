extends GridElement

@export var i_generated : float = 1.0


func calculate_new_i() -> float:
	return i_generated


func calculate_new_u() -> float:
	return get_u()


func on_converge():
	pass


func interrupt():
	pass
