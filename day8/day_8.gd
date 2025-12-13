@tool
extends Node3D

@export_tool_button("Spawn Points") var spawn_points: Callable = tool_spawn_points

var network_colors: Array[Color] = [
    Color.ORANGE_RED,
    Color.YELLOW_GREEN,
    Color.RED,
    Color.GREEN,
    Color.BLANCHED_ALMOND,
]

var other_networked_color: Color = Color.BLACK

func tool_spawn_points() -> void:
    clear_old_spawn_points()
    pos_list = get_and_parse_input()
    pos_index_map.clear()
    for i in pos_list.size():
        pos_index_map[pos_list[i]] = i
    make_sorted_point_lists()

    await part_2()
    
    var point_mesh: Mesh = BoxMesh.new()
    var material_template: StandardMaterial3D = StandardMaterial3D.new()
    material_template.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
    point_mesh.size = Vector3.ONE * 0.08
    
    var uncolored_network_points: Array[Array] = top_n_networks.duplicate_deep()

    for pos: Vector3i in pos_list:
        var smaller_pos: Vector3 = Vector3(pos) / 20000.0
        var spawn_point: MeshInstance3D = MeshInstance3D.new()
        var mesh_copy: Mesh = point_mesh.duplicate()
        spawn_point.mesh = mesh_copy
        spawn_point.position = smaller_pos
        var mat_copy: StandardMaterial3D = material_template.duplicate()
        var position_color: Color = Color(smaller_pos.x / 5.0, max(smaller_pos.y, smaller_pos.z) / 5.0, 1.0)
        var in_network: bool = false
        if pos in other_networked_points:
            in_network = true
            mesh_copy.size = Vector3.ONE * 0.04
            position_color = other_networked_color
            mat_copy.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
        for network_i in top_n_networks.size():
            if pos in top_n_networks[network_i]:
                if in_network:
                    prints("point", pos, "is in other and top networks?")
                in_network = true
                uncolored_network_points[network_i].erase(pos)
                mesh_copy.size = Vector3.ONE * 0.12
                mat_copy.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
                position_color = network_colors[network_i]
                break
        mat_copy.albedo_color = position_color
        spawn_point.material_override = mat_copy
        add_child(spawn_point)

func clear_old_spawn_points() -> void:
    for child in get_children():
        if child is MeshInstance3D and not child.owner:
            child.queue_free()

func get_and_parse_input() -> Array[Vector3i]:
    var this_dir: String = (get_script() as GDScript).resource_path.get_base_dir()
    var input_file: = FileAccess.open(this_dir + "/input", FileAccess.ModeFlags.READ)
    if not input_file:
        print_debug("Couldnt open input file")
        return []
    
    var input_lines: PackedStringArray = input_file.get_as_text().split("\n", false)
    
    var positions: Array[Vector3i] = []
    for i in input_lines.size():
        var parts: PackedStringArray = input_lines[i].split(",", false)
        positions.append(Vector3i(int(parts[0]), int(parts[1]), int(parts[2])))

    return positions

var pos_list: Array[Vector3i] = []
var pos_index_map: Dictionary = {}
var x_sorted: Array[Vector3i] = []
var x_index_map: Dictionary = {}
var y_sorted: Array[Vector3i] = []
var y_index_map: Dictionary = {}
var z_sorted: Array[Vector3i] = []
var z_index_map: Dictionary = {}
var other_networked_points: Array[Vector3i] = []

var top_n_networks: Array[Array] = []

func _ready() -> void:
    if Engine.is_editor_hint():
        return

    pos_list = get_and_parse_input()
    for i in range(pos_list.size()):
        pos_index_map[pos_list[i]] = i
    make_sorted_point_lists()
    
    
    print("PART 1")
    await part_1()
    
    await get_tree().create_timer(0.1).timeout
    
    print(" ")
    print("PART 2")
    part_2()
    
    await get_tree().create_timer(0.1).timeout
    get_tree().quit()

func part_1() -> void:
    var nearby_points_of_points: Array[Array] = []
    for i in pos_list.size():
        nearby_points_of_points.append(collect_nearby_points(i, 24))
    
    #print(nearby_points_of_points.slice(0, 5))

    var smallest_distances: Array[Dictionary] = await find_n_smallest_connections(nearby_points_of_points, 1000)
    
    var smallest_few_distances: Array[float] = []
    for i in smallest_distances.size():
        if i > 20:
            break
        smallest_few_distances.append(snappedf(sqrt(smallest_distances[i].distance), 0.001))
    prints("smallest few distances:", smallest_few_distances)

    
    #print(small_distances_reduce(smallest_distances.slice(0, 25)))
    var networks: Array[Array] = []
    normal_skip_counter = 0
    for distance_info in smallest_distances:
        add_to_networks(networks, distance_info)
    sort_networks_by_size(networks)
    prints("normal skip counter:", normal_skip_counter)
    #prints("networks:", networks.slice(0, 3))
    print("total networks:", networks.size())
    
    top_n_networks.clear()
    other_networked_points.clear()
    top_n_networks.assign(networks.slice(0, 3))
    for n_i in networks.size():
        if n_i < 3:
            continue
        for point: Vector3i in networks[n_i]:
            if point in other_networked_points:
                continue
            other_networked_points.append(point)
    
    var top_3_sizes: Array[int] = []
    for i in 3:
        top_3_sizes.append(networks[i].size())
    
    prints("total non-trivial networks:", networks.size(), "top 3 sizes:", top_3_sizes, "result:", top_3_sizes.reduce(func(a, b) -> int: return a * b, 1))

func find_n_smallest_connections(nearby_points_of_points: Array[Array], n: int) -> Array[Dictionary]:
    var smallest_distances: Array[Dictionary] = []
    prints("first point:", pos_list[0])
    
    var start_checking_closely: int = 910
    var magic_iteration: int = 916
    
    for i in pos_list.size():
        var reference_pos: Vector3i = pos_list[i]
        if i % 5 == 0 or i > start_checking_closely:
            prints("processing point pairs:", i / 10.0, "%")
            if smallest_distances.size() > 1000:
                var networks: Array[Array] = check_final_networks(smallest_distances, i == magic_iteration)
                var last_connection_info: Array = []
                if i == magic_iteration:
                    last_connection_info = networks.pop_back()
                var network_count: int = networks.size()
                prints("network count so far:", network_count)
                if network_count < 2:
                    var is_complete: bool = true
                    for i_i in pos_list.size():
                        if pos_list[i_i] not in networks[0]:
                            is_complete = false
                            break
                    if is_complete:
                        prints("found complete network, stopping at index:", i)
                        smallest_distances.append({"point_a": last_connection_info[0], "point_b": last_connection_info[1] })
                        return smallest_distances
            await get_tree().process_frame
        for nearby_pos in nearby_points_of_points[i]:
            if nearby_pos == reference_pos:
                prints("OH NO")
                return []
            var dist_squared: float = reference_pos.distance_squared_to(nearby_pos)
            if i == 0:
                prints("dist_squared:", dist_squared, "to:", nearby_pos)
            if smallest_distances.size() < n or dist_squared < smallest_distances[-1].distance:
                var is_duplicate: bool = false
                for sm in smallest_distances:
                    if sm.point_b == reference_pos and sm.point_a == nearby_pos:
                        is_duplicate = true
                        break
                if not is_duplicate:
                    var info: Dictionary = {}
                    info.points = [reference_pos, nearby_pos]
                    info.point_a = reference_pos
                    info.point_b = nearby_pos
                    info.distance = dist_squared
                    smallest_distances.append(info)
                    sort_small_distances(smallest_distances)
                    if smallest_distances.size() > n:
                        smallest_distances.pop_back()
    
    return smallest_distances

var normal_skip_counter: int = 0

func add_to_networks(networks: Array[Array], distance_info: Dictionary) -> bool:
    var added_to_network: bool = false
    for network in networks:
        for a_or_b in 2:
            var p: Vector3i = distance_info.points[a_or_b]
            if p in network:
                added_to_network = true
                var other_p: Vector3i = distance_info.points[1 - a_or_b]
                if other_p in network:
                    normal_skip_counter += 1
                    #prints("skipping (normally)")
                    return false
                network.append(other_p)
                # merge networks if the other point is in another existing network
                for existing_network in networks:
                    if is_same(existing_network, network):
                        continue
                    if other_p in existing_network:
                        for moved_point in existing_network:
                            if moved_point in network:
                                #prints("skipping moving point, it's already in the network??")
                                continue
                            network.append(moved_point)
                        networks.erase(existing_network)
                break
        if added_to_network:
            break

    if not added_to_network:
        networks.append(Array(distance_info.points, TYPE_VECTOR3I, &"", null))
    return true

func sort_networks_by_size(networks: Array[Array]) -> void:
    networks.sort_custom(func(a, b) -> bool: return a.size() > b.size())

func part_2() -> void:
    var nearby_points_of_points: Array[Array] = []
    for i in pos_list.size():
        nearby_points_of_points.append(collect_nearby_points(i, 24))
    
    #print(nearby_points_of_points.slice(0, 5))

    var smallest_distances: Array[Dictionary] = await find_n_smallest_connections(nearby_points_of_points, 7000)
    var last_connection_info: Dictionary = smallest_distances.pop_back()

    
    var networks: Array[Array] = []
    for distance_info in smallest_distances:
        add_to_networks(networks, distance_info)
    print("total networks:", networks.size())
    
    other_networked_points.clear()
    top_n_networks.assign(networks)
    
    prints("last connected points:", last_connection_info.point_a, last_connection_info.point_b)
    
    prints("result:", last_connection_info.point_a.x * last_connection_info.point_b.x)
    

func check_final_networks(distance_infos: Array[Dictionary], get_last_connection_info: bool) -> Array[Array]:
    var networks: Array[Array] = []
    var last_connection_info: Dictionary = {}
    for distance_info in distance_infos:
        var connection_added: bool = add_to_networks(networks, distance_info)
        if connection_added:
            last_connection_info = distance_info
    
    if get_last_connection_info:
        prints("last connection info distance:", snappedf(sqrt(last_connection_info.distance), 0.001))
        networks.append([last_connection_info.point_a, last_connection_info.point_b])
    return networks

# the last element is the only one needing to be re-ordered
func sort_small_distances(distances: Array[Dictionary]) -> void:
    var dist_of_last: float = distances[-1].distance
    for i in distances.size() - 1:
        if distances[i].distance > dist_of_last:
            var dist_info: Dictionary = distances.pop_back()
            distances.insert(i, dist_info)
            return

func sort_small_distances_slow(distances: Array[Dictionary]) -> void:
    distances.sort_custom(func(a, b) -> bool: return a.distance < b.distance)

func small_distances_reduce(distances: Array[Dictionary]) -> Array[float]:
    var reduced_distances: Array[float] = []
    for distance in distances:
        reduced_distances.append(distance.distance)
    return reduced_distances

func collect_nearby_points(pos_index: int, at_least: int) -> Array[Vector3i]:
    var nearby_points: Array[Vector3i] = []
    var the_point: Vector3i = pos_list[pos_index]
    
    var box_radius: int = 400
    var radius_increment: int = 800
    var max_iterations: int = 1000
    var iterations: int = 0
    while nearby_points.size() < at_least:
        box_radius += radius_increment
        nearby_points.assign(get_nearby_box_radius(the_point, box_radius))
        iterations += 1
        if iterations > max_iterations:
            print_debug("Max iterations reached")
            break

    return nearby_points

func get_nearby_box_radius(the_point: Vector3i, box_radius: int) -> Array[Vector3i]:
    var nearby_points: Array[Vector3i] = []
    var x_points: Array[Vector3i] = get_nearby_points_by_axis(0, x_sorted, x_index_map[the_point], box_radius)
    for x_p in x_points:
        nearby_points.append(x_p)
    var y_points: Array[Vector3i] = get_nearby_points_by_axis(1, y_sorted, y_index_map[the_point], box_radius)
    for y_p in y_points:
        if y_p not in nearby_points:
            nearby_points.append(y_p)
    var z_points: Array[Vector3i] = get_nearby_points_by_axis(2, z_sorted, z_index_map[the_point], box_radius)
    for z_p in z_points:
        if z_p not in nearby_points:
            nearby_points.append(z_p)
    return nearby_points

func get_nearby_points_by_axis(axis_idx: int, axis_points: Array[Vector3i], index_of_reference: int, radius: int) -> Array[Vector3i]:
    var nearby_points: Array[Vector3i] = []
    var pos_diff: int = 0
    var index_walker: int = index_of_reference
    var point_position: Vector3i = axis_points[index_of_reference]
    var axis_pos: int = point_position[axis_idx]
    while pos_diff < radius:
        index_walker += 1
        if index_walker >= axis_points.size():
            break
        var close_point_pos: Vector3i = axis_points[index_walker]
        pos_diff = absi(close_point_pos[axis_idx] - axis_pos)
        var is_close: bool = true
        for i in 3:
            if absi(close_point_pos[i] - point_position[i]) > radius:
                is_close = false
                break
        if is_close:
            nearby_points.append(axis_points[index_walker])

    index_walker = index_of_reference
    while pos_diff < radius:
        index_walker -= 1
        if index_walker < 0:
            break
        var close_point_pos: Vector3i = axis_points[index_walker]
        pos_diff = absi(close_point_pos[axis_idx] - axis_pos)
        var is_close: bool = true
        for i in 3:
            if absi(close_point_pos[i] - point_position[i]) > radius:
                is_close = false
                break
        if is_close:
            nearby_points.append(axis_points[index_walker])
    return nearby_points

func make_sorted_point_lists() -> void:
    x_sorted.assign(pos_list)
    x_sorted.sort_custom(func(a, b) -> bool: return a.x < b.x)
    x_index_map.clear()
    for i in range(x_sorted.size()):
        x_index_map[x_sorted[i]] = i
    y_sorted.assign(pos_list)
    y_sorted.sort_custom(func(a, b) -> bool: return a.y < b.y)
    y_index_map.clear()
    for i in range(y_sorted.size()):
        y_index_map[y_sorted[i]] = i
    z_sorted.assign(pos_list)
    z_sorted.sort_custom(func(a, b) -> bool: return a.z < b.z)
    z_index_map.clear()
    for i in range(z_sorted.size()):
        z_index_map[z_sorted[i]] = i