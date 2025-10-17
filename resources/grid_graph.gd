extends Resource
class_name GridGraph
## A resource that represents an electric grid organized as 
## a graph. 

var grid_elements : Array[GridElement]
var grid_nodes : Array[GridNode]
var grounded_node : GridNode

var dumping : float = 1.0
var error_i : float
var error_u : float


## Prepares the graph for recursive calculus by deleting dead ends,
## setting the grounded node, and setting u and i values to 0
func prepare_graph() -> bool:
	var non_empty_graph : bool = remove_dead_ends()
	if not non_empty_graph: return false
	if grid_nodes :
		grounded_node = grid_nodes[0]
	for elem: GridElement in grid_elements :
		elem.i1 = 0.0
		elem.i2 = 0.0
		elem.born1.i = 0.0
		elem.born2.i = 0.0
		elem.born1.u = 0.0
		elem.born2.u = 0.0
	for nod: GridNode in grid_nodes:
		nod.u = 0
	return true


## look for parts of the graph that are not part of a loop and
## delete it.
func remove_dead_ends() -> bool:
	var new_check_required := true
	var give_up : int = 100
	while new_check_required:
		give_up -= 1
		if give_up == 0 :
			printerr("remove_dead_ends infinit loop")
			break
		new_check_required = false
		var voisins : Dictionary
		for node in grid_nodes:
			voisins[node] = []
		var marked_to_erase : Array = [GridElement]
		for elem: GridElement in grid_elements:
			if not elem.node1 or not elem.node2:
				new_check_required = true
				# apparament quand on erase un element d'un
				# array pendant qu'on le parcour, il aime pas.
				#grid_elements.erase(elem)
				# du coup je teste le suivant :
				marked_to_erase.append(elem)
				continue
			#if voisins.find_key(elem.node1):
			voisins[elem.node1].append(elem)
			#if voisins.find_key(elem.node2):
			voisins[elem.node2].append(elem)
		for elem in marked_to_erase:
			grid_elements.erase(elem)
			elem.interrupt()
		for key in voisins :
			if voisins[key].size() < 2 :
				new_check_required = true
				for e in voisins[key]:
					grid_elements.erase(e)
					e.interrupt()
				grid_nodes.erase(key)

				for elem:GridElement in grid_elements:
					if (not grid_nodes.has(elem.node1) or 
						not grid_nodes.has(elem.node2)):
							grid_elements.erase(elem)
							elem.interrupt()
	
	return ((not grid_nodes.is_empty()) and (not grid_elements.is_empty()))


## Loop through the graph until it converges or until max loop reached
func update_to_converge(max_loop: int, threashold_i: float, threashold_u):
	for j:int in 10 :
		update_loop()
	for j:int in max_loop :
		update_loop(false)
		if error_i < threashold_i and error_u < threashold_u :
			print_rich("[color=green][bolt]DID CONVERGE AT
			ITERATION %d[/bolt][/color]
			with errors :
			[color=red]error u = %f[/color]
			[color=green]error i = %f[/color]" % [
					(j + 10),
					error_u,
					error_i,
			])
			for elem: GridElement in grid_elements:
				elem.on_converge()
			break
		if j == (max_loop - 1) :
			print_rich("[color=red][bold]DID NOT CONVERGE[/bold][/color]
			with errors :
			[color=red]error u = %f[/color]
			[color=green]error i = %f[/color]" % [
					error_u,
					error_i,
			])
			for elem: GridElement in grid_elements:
				elem.interrupt()


## Loop once in the graph to update i and u values
func update_loop (step_by_step = true):
	error_i = 0.0
	error_u = 0.0
	update_element_potencials()
	update_node_potencials()
	update_element_intencities()
	update_node_intencities()
	#print_rich("[color=red]error u = %f[/color]" % error_u)
	#print_rich("[color=green]error i = %f[/color]" % error_i)
	offset_u_to_ground()
	

## Loop through elements to trigger their update_u methode
func update_element_potencials():
	for element in grid_elements:
		element.update_u(dumping)
		error_u += element.error_u


## Loop through nodes to average their u value
func update_node_potencials():
	for grid_node in grid_nodes:
		var old_u = grid_node.u
		grid_node.u = 0
		for b in grid_node.borns:
			grid_node.u += b.u
		grid_node.u /= grid_node.borns.size()
		for b in grid_node.borns:
			b.u = lerp(b.u, grid_node.u, dumping)
		
		error_u += abs(old_u - grid_node.u)
		
		#print("node ", " potencial : " , grid_node.u)


## Loop through elements to trigger their update_i methode
func update_element_intencities():
	for element in grid_elements:
		element.update_i(dumping)
		error_i += element.error_i


## Loop through nodes to offset their intensity so they sum to zero
func update_node_intencities():
	for grid_node in grid_nodes:
		var i_offset := 0.0
		for b in grid_node.borns:
			i_offset += b.i
		#print("offset i : ", i_offset)
		error_i += abs(i_offset)
		var i_offset_individual = i_offset / grid_node.borns.size()
		for b in grid_node.borns:
			b.i -= i_offset_individual * dumping
			#print ("born ", b.name, "intencity : ", b.i)


## Loop through all graph components to offset the u values according
## to the grounded node
func offset_u_to_ground():
	if grid_nodes.has(grounded_node):
		var u_offset = grounded_node.u
		for nod: GridNode in grid_nodes:
			nod.u -= u_offset
			for born: Borne in nod.borns:
				born.u -= u_offset
