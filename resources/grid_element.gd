@abstract
class_name GridElement extends Node
## An abstract class that represent an element that can be
## part of the electric grid.

## The first connexion point, usually red.
## The i property of this borne is usually negative when used
## with a current generator,
## and positive when used with a current consumer.
@export var born1 :CnxPoint
## The second connexion point, usually black
## The i property of this borne is usually positive when used
## with a current generator,
## and negative when used with a current consumer.
@export var born2 :CnxPoint
## The dumping factor to help making converge the values
@export var dumping : float = 1.0

## The grid node of which is part the born1 (will be affected
## by the scan_circuit methode of the circuit_simulator).
var node1 : GridNode
## The grid node of which is part the born2 (will be affected
## by the scan_circuit methode of the circuit_simulator)
var node2 : GridNode

## The electric intensity that ENTERS the born1.
## Becomes negative if the current flow is outwards.
## This value is usually negative when used with a current generator,
## and positive when used with a current consumer.
## [deprecated] because the value is passed directly to the
## borne.
var i1 : float
## The electric intensity that ENTERS the born2, normally negative.
## Becomes negative if the current flow is outwards.
## This value is usually positive when used with a current generator,
## and negative when used with a current consumer.
## [deprecated] because the value is passed directly to the
## borne.
var i2 : float

## The error between precedent and new i value
var error_i : float
## The error between precedent and new u value
var error_u : float

func _ready() -> void:
	add_to_group("grid elements")


## Calculates the in and out intensities according to electric
## potensials of born1 and born2.
func update_i(dumping_override : float = 0.0):
	if (not born1) or (not born2) :
		return
	if (not node1) or (not node2):
		born1.i = 0.0
		born2.i = 0.0
		return
	var i : float = calculate_new_i()
	error_i = abs(born1.i - i)
	error_i += abs(born2.i + i)
	var d : float
	#if abs(i) > abs(born1.i):
		##d = dumping * dumping
		#d = dumping
	#else:
		#d = dumping
	d = dumping_override if dumping_override != 0.0 else dumping
	born1.i = lerp(born1.i, i, d)
	born2.i = lerp(born2.i, -i, d)


## Calculates the new intensity flow through the component.
## It is positive when the current flows from the borne1 to the borne2
## and negative otherwise.
## It generally means it is positive for current consumer and
## negative for current generator.
@abstract func calculate_new_i() -> float


## Calculates the potensial diferencial according to the
## intensity
func update_u(dumping_override : float = 0.0):
	if (not born1) or (not born2) : return
	if (not node1) or (not node2) : return
	var du := calculate_new_u()
	var target1 : float
	var target2 : float
	var old_mean : float = (born1.u + born2.u)/2
	target1 = old_mean + du / 2
	target2 = old_mean - du / 2
	error_u = abs(born1.u - target1)
	error_u += abs(born2.u - target2)
	var d : float
	if abs(du) > abs(born1.u - born2.u):
		#d = dumping * dumping
		d = dumping
	else :
		d = dumping
	d = dumping_override if dumping_override != 0.0 else dumping
	born1.u = lerp(born1.u, target1, d)
	born2.u = lerp(born2.u, target2, d)


## Calculate the new difference of potencial between borne1 and borne2
## It is positive if borne1 has higher potencial than borne2 (recommended)
@abstract func calculate_new_u() -> float #:
	#return born1.u - born2.u


## Will be executed once when the graph converged to a specific value. For
## example it can be used to set a motor velocity.
@abstract func on_converge()


## Will be executed if the graph does not converge, or if the
## layout changes.
@abstract func interrupt()

## Returns the current flowing through the component form born1
## to born2. Usually negative for current generators, and positive
## for current consumers
func get_i() -> float:
	if born1 and born2:
		return (born1.i - born2.i) / 2
	else:
		return 0.0


## Returns the difference of potencial between born1 and born2.
## Usually positive
func get_u() -> float:
	if born1 and born2:
		return born1.u - born2.u
	else:
		return 0.0
	
