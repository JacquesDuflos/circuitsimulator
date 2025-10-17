extends Node
class_name CircuitSimulator

## Ignored if set to 0.0. else will override the dumping of each
## element in the circuit.
@export var dumping : float = 0.8
@export var threashold_i : float = 0.1
@export var threashold_u : float = 0.1

## A list of connex graphs 
var grid_graphs : Array[GridGraph]
## Will be used temporally before grid_graphs is funcional
var grid_elements : Array[GridElement]
## Will be used temporally before grid_graphs is funcional
var grid_nodes : Array[GridNode]

## The sum of error rectified when calculating the intensity in the circuit
## durtin one iteration. It is reset at zero at begining of each iteration.
## If it is beneth threashold_i, the solver will consider the calculus
## converged (for intensity).
var error_i : float
## The sum of error rectified when calculating the electric tension in the circuit
## durtin one iteration. It is reset at zero at begining of each iteration.
## If it is beneth threashold_u, the solver will consider the calculus
## converged (for electric tension).
var error_u : float

## If set to True, the i and u values will be recalculage
## on the next _on_trigger_to_converge_timeout.
## It will be set to false immediatly.
var marked_to_converge : bool = false
## Number of loop that will be done before giving up on converging
const MAX_LOOP = 500


func _ready() -> void:
	CableManager.layout_changed.connect(_on_layout_changed)


## Loop through all bornes and ciruit elements to populate the
## grid_nodes and grid_elements array
func scan_circuit():
	grid_elements.clear()
	grid_nodes.clear()
	grid_graphs.clear()
	
	var layout := get_cable_layout()
	for born_array in layout:
		var no := GridNode.new()
		no.borns.append_array(born_array)
		grid_nodes.append(no)
	#grid_nodes.append_array(get_tree().get_nodes_in_group("grid nodes"))
	print("GRID NODES : " , grid_nodes)
	
	for elem:GridElement in get_tree().get_nodes_in_group("grid elements"):
		grid_elements.append(elem)
		elem.node1 = null
		elem.node2 = null
		for nod:GridNode in grid_nodes:
			if elem.born1 in nod.borns :
				elem.node1 = nod
			if elem.born2 in nod.borns :
				elem.node2 = nod
	print ("GRID ELEMENTS : " , grid_elements)
	
	grid_graphs.append_array(trouver_ilots(grid_nodes, grid_elements))
	var graph_to_erase : Array = []
	for graph:GridGraph in grid_graphs:
		if not graph.prepare_graph():
			graph_to_erase.append(graph)
			continue
		graph.dumping = dumping
	for emptyGraph in graph_to_erase:
		grid_graphs.erase(emptyGraph)
	print ( "GRID GRAPHS : ", grid_graphs)


## Scan cables form the cable manager and create
## the list representing the layout
func get_cable_layout() -> Array:
	var list_cnx : Array
	for c in CableManager.cables:
		list_cnx.append([
				c.banana_from.get_original_borne(),
				c.banana_to.get_original_borne(),
		])
	for node : GridNode in get_tree().get_nodes_in_group("grid nodes"):
		list_cnx.append(node.borns)
	return fusionner_listes(list_cnx)


## Loop through graphs to trigger their update_to_converge methode
func update_to_converge():
	for graph: GridGraph in grid_graphs:
		graph.update_to_converge(MAX_LOOP, threashold_i, threashold_u)


## Triggered when cables form the CableManager change. Should be deprecated
## to make the CircuitSimulator a stand-alone pluggin
func _on_layout_changed():
	#return
	scan_circuit()
	update_to_converge()


func _on_trigger_converge_timeout() -> void:
	if marked_to_converge :
		marked_to_converge = false
		update_to_converge()


#region les fonction suivantes sont crees par chatgpt
# https://chatgpt.com/c/6843627d-9308-8013-b720-820491a00a30
## Check if any element is in commun between two arrays
func has_any(set1: Array, set2: Array) -> bool:
	for item in set1:
		if set2.has(item):
			return true
	return false


## from a list of lists, merge all list that 
## has an element in commun
func fusionner_listes(listes: Array) -> Array:
	var groupes : Array = []

	for sous_liste in listes:
		var reste = []
		var ensemble_sous_liste = sous_liste.duplicate()

		for groupe in groupes:
			if has_any(ensemble_sous_liste, groupe):
				ensemble_sous_liste += groupe
			else:
				reste.append(groupe)

		# Nettoyer les doublons et trier
		var nouveau_groupe = []
		for e in ensemble_sous_liste:
			if not nouveau_groupe.has(e):
				nouveau_groupe.append(e)
		nouveau_groupe.sort() # tri alphabétique

		groupes = reste
		groupes.append(nouveau_groupe)

	# Trier les groupes eux-mêmes pour cohérence visuelle
	groupes.sort_custom(func(a, b): return a[0].name < b[0].name)
	
	return groupes


## Store every list alphabetically, store the list accordin
## to their first element
func trier_groupes(groupes: Array) -> Array:
	var resultats = []
	
	# 1. Trier chaque sous-liste individuellement
	for groupe in groupes:
		var copie = groupe.duplicate()
		copie.sort()
		resultats.append(copie)
	
	# 2. Trier la liste de groupes par le premier élément de chaque sous-liste
	resultats.sort_custom(func(a, b): return a[0] < b[0])
	
	return resultats


func trouver_ilots(noeuds: Array, aretes: Array) -> Array[GridGraph]:
	var voisins = {}
	var voisins_elem = {}
	
	# Construire une map {Noeud: [voisins]}
	for noeud:GridNode in noeuds:
		voisins[noeud] = []
		voisins_elem[noeud] = []
	
	for elem:GridElement in aretes:
		if elem.node1 :
			voisins_elem[elem.node1].append(elem)
		if elem.node2:
			voisins_elem[elem.node2].append(elem)
		if not elem.node1 or not elem.node2 : continue
		voisins[elem.node1].append(elem.node2)
		voisins[elem.node2].append(elem.node1)
	
	# Parcours pour trouver les ilots
	var visites = {}
	for noeud in noeuds:
		visites[noeud] = false
	
	var ilots: Array[GridGraph] = []
	
	for noeud in noeuds:
		if not visites[noeud]:
			var ilot = GridGraph.new()
			_dfs(noeud, voisins, voisins_elem, visites, ilot)
			ilots.append(ilot)
	
	return ilots


# --- Fonction auxiliaire (DFS récursif) ---
func _dfs(noeud: GridNode, voisins: Dictionary, voisins_e : Dictionary, visites: Dictionary, ilot: GridGraph) -> void:
	visites[noeud] = true
	ilot.grid_nodes.append(noeud)
	#if voisins_e.find_key(noeud):
	for _elem in voisins_e[noeud]:
		if not ilot.grid_elements.has(_elem):
			ilot.grid_elements.append(_elem)
	
	for voisin in voisins[noeud]:
		if not visites[voisin]:
			_dfs(voisin, voisins, voisins_e, visites, ilot)
#endregion
