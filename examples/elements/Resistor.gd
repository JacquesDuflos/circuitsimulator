extends GridElement

## The resistor in ohm
@export var r : float = 4.7


func calculate_new_i() -> float :
	return get_u() / r


func calculate_new_u() -> float:
	return r * get_i()


func interrupt():
	pass


func on_converge():
	pass
