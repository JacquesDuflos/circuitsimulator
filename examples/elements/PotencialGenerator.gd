extends GridElement

@export var u_generated : float = 3.3


func calculate_new_i() -> float:
	return get_i()


func calculate_new_u() -> float:
	return u_generated


func on_converge():
	pass


func interrupt():
	return
