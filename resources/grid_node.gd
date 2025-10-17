extends Node
class_name GridNode
## Un conjunto de bornes conectados por cables
## que forman un nudo del graph representando
## la red electrica.

## La lista de designaciones de bornes que son conectados por cables
## y que compoene este gridnode
@export var borns : Array[Node] #Borne]

## El potencial electrico a cual se encuentra el nodo
var u : float


func _ready() -> void:
	add_to_group("grid nodes")
