extends Node2D

func _ready() -> void:
    var this_dir: String = (get_script() as GDScript).resource_path.get_base_dir()
    var input_file: = FileAccess.open(this_dir + "/input", FileAccess.ModeFlags.READ)
    if not input_file:
        print_debug("Couldnt open input file")
        return
    
    var input_lines: PackedStringArray = input_file.get_as_text().split("\n", true)
    var separator_line: int = input_lines.find("")
    prints("Separator line:", separator_line)
    
    var ranges: Array[Array] = []
    for i in separator_line:
        var range_parts: PackedStringArray = input_lines[i].split("-")
        ranges.append([int(range_parts[0]), int(range_parts[1])])
    
    var ids: Array[int] = []
    for i in range(separator_line + 1, input_lines.size()):
        ids.append(int(input_lines[i]))
    
    print("PART 1")
    part_1(ranges, ids)
    
    await get_tree().create_timer(0.1).timeout
    
    print(" ")
    print("PART 2")
    part_2(ranges)
    
    await get_tree().create_timer(0.1).timeout
    get_tree().quit()

func part_1(ranges: Array[Array], ids: Array[int]) -> void:
    var fresh_ids: int = 0
    for id in ids:
        for id_range in ranges:
            if id >= id_range[0] and id <= id_range[1]:
                fresh_ids += 1
                break

    prints("Fresh ID count:", fresh_ids)

func part_2(ranges: Array[Array]) -> void:
    var unioned_ranges: Array[Array] = []
    
    var index: int = 0
    for base_range in ranges:
        var cur_range: Array = base_range
        var found_overlap: int = find_overlap(base_range, unioned_ranges)
        while found_overlap > -1:
            cur_range = range_union(cur_range, unioned_ranges[found_overlap])
            unioned_ranges.remove_at(found_overlap)
            found_overlap = find_overlap(cur_range, unioned_ranges)
        unioned_ranges.push_front(cur_range)
        if index < 4:
            prints("Unioned ranges:", unioned_ranges)
        index += 1
    
    var total_ids_covered: int = 0
    for unioned_range in unioned_ranges:
        total_ids_covered += unioned_range[1] + 1 - unioned_range[0]
    prints("Unioned range count:", unioned_ranges.size(), "Total IDs covered:", total_ids_covered)

func find_overlap(base_range: Array, in_ranges: Array[Array]) -> int:
    for i in in_ranges.size():
        if does_range_overlap(base_range, in_ranges[i]):
            return i
    return -1

func does_range_overlap(range_1: Array, range_2: Array) -> bool:
    return range_1[0] <= range_2[1] and range_1[1] >= range_2[0]

func range_union(range_1: Array, range_2: Array) -> Array:
    return [min(range_1[0], range_2[0]), max(range_1[1], range_2[1])]