extends Node2D

func _ready() -> void:
    var this_dir: String = (get_script() as GDScript).resource_path.get_base_dir()
    var input_file: = FileAccess.open(this_dir + "/input", FileAccess.ModeFlags.READ)
    if not input_file:
        print_debug("Couldnt open input file")
        return
    
    var input_lines: PackedStringArray = input_file.get_as_text().split("\n", false)
    
    var full_width: int = input_lines[0].length()
    var starting_index: int = input_lines[0].find("S")
    
    var processed_lines: Array[String] = []
    for i in input_lines.size():
        if i == 0 or i % 2 == 1:
            continue
        processed_lines.append(input_lines[i])
    
    print("PART 1")
    part_1(full_width, starting_index, processed_lines)
    
    await get_tree().create_timer(0.1).timeout
    
    print(" ")
    print("PART 2")
    part_2(full_width, starting_index, processed_lines)
    
    await get_tree().create_timer(0.1).timeout
    get_tree().quit()

func part_1(full_width: int, starting_index: int, input_lines: Array[String]) -> void:
    var current_beam_indices: Array[int] = [starting_index]
    var times_split: int = 0
    for line in input_lines:
        var new_beam_indices: Array[int] = current_beam_indices.duplicate()
        for char_i in current_beam_indices:
            if line[char_i] == "^":
                times_split += 1
                new_beam_indices.erase(char_i)
                for offs in [-1, 1]:
                    var new_index: int = char_i + offs
                    if new_index in new_beam_indices or new_index >= full_width or new_index < 0:
                        continue
                    new_beam_indices.append(new_index)
        current_beam_indices = new_beam_indices
    
    prints("Times split:", times_split, "Number of beam paths:", current_beam_indices.size())

func part_2(full_width: int, starting_index: int, input_lines: Array[String]) -> void:
    var current_beam_indices: Array[int] = [starting_index]
    var active_timelines: Array[int] = [1]
    for line in input_lines:
        var new_beam_indices: Array[int] = []
        var new_active_timelines: Array[int] = []
        for active_i in range(current_beam_indices.size() - 1, -1, -1):
            var char_i: int = current_beam_indices[active_i]
            var timelines_here: int = active_timelines[active_i]
            if line[char_i] != "^":
                var index_exists_at: int = new_beam_indices.find(char_i)
                if index_exists_at == -1:
                    new_beam_indices.append(char_i)
                    new_active_timelines.append(timelines_here)
                else:
                    new_active_timelines[index_exists_at] += timelines_here
                continue

            for offs in [-1, 1]:
                var new_char_index: int = char_i + offs
                if new_char_index < 0 or new_char_index >= full_width:
                    print_debug("New char index out of bounds")
                    continue
                var index_exists_at: int = new_beam_indices.find(new_char_index)
                if index_exists_at == -1:
                    new_beam_indices.append(new_char_index)
                    new_active_timelines.append(timelines_here)
                else:
                    new_active_timelines[index_exists_at] += timelines_here
        current_beam_indices = new_beam_indices
        active_timelines = new_active_timelines
    
    var total_timelines: int = active_timelines.reduce(func(acc, timeline): return acc + timeline, 0)
    prints("Total Timelines:", total_timelines, "Number of beam paths:", current_beam_indices.size())