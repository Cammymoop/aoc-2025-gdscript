extends Node2D

func _ready() -> void:
    var this_dir: String = (get_script() as GDScript).resource_path.get_base_dir()
    var input_file: = FileAccess.open(this_dir + "/input", FileAccess.ModeFlags.READ)
    if not input_file:
        print_debug("Couldnt open input file")
        return
    
    var input_lines: PackedStringArray = input_file.get_as_text().split("\n", false)
    var processed_lines: Array[Array] = []
    for i in input_lines.size():
        var line: String = input_lines[i]
        var parts: PackedStringArray = line.split(" ", false)
        if i == input_lines.size() - 1:
            processed_lines.append(Array(parts))
            continue
        var ints: Array[int] = []
        for part in parts:
            ints.append(int(part))
        processed_lines.append(ints)
    
    print("PART 1")
    part_1(processed_lines)
    
    await get_tree().create_timer(0.1).timeout
    
    var problem_widths: Array[int] = []
    for i in processed_lines[0].size():
        var max_width: int = 0
        for j in processed_lines.size() - 1:
            var num_width: int = str(processed_lines[j][i]).length()
            max_width = maxi(max_width, num_width)
        problem_widths.append(max_width)
        
    var operators: Array[String] = []
    var proc_lines_2: Array[Array] = []
    operators.assign(processed_lines[-1])
    for i in input_lines.size() - 1:
        var string_left: String = input_lines[i]
        var columns: Array[Array] = []
        var last: = false
        for num_width in problem_widths:
            var column_digits: Array[int] = []
            if last:
                print_debug("Last number collected but still looping!")
                break
            else:
                var num_string: String = string_left.substr(0, num_width)
                for j in num_string.length():
                    if num_string[j] == ' ':
                        column_digits.append(-1)
                    else:
                        column_digits.append(int(num_string[j]))
                if string_left.length() <= num_width:
                    print("last number:", string_left)
                    last = true
                elif string_left[num_width] != ' ':
                    print_debug("Expected space after number but it was something else")
                    break
                string_left = string_left.substr(num_width + 1)
            columns.append(column_digits)
        proc_lines_2.append(columns)
    
    print(" ")
    print("PART 2")
    part_2(proc_lines_2, operators)
    
    await get_tree().create_timer(0.1).timeout
    get_tree().quit()

func part_1(processed_lines: Array[Array]) -> void:
    var operators: Array[String] = []
    operators.assign(processed_lines[-1])
    
    var num_values: int = processed_lines[0].size()
    var total_total: int = 0
    for i in num_values:
        var operator: String = operators[i]
        var acc: int = 1 if operator == "*" else 0
        for j in processed_lines.size() - 1:
            if operator == "*":
                acc *= processed_lines[j][i]
            else:
                acc += processed_lines[j][i]
        total_total += acc
    prints("Total total:", total_total)

func part_2(proc_lines_2: Array[Array], operators: Array[String]) -> void:
    var problem_count: int = proc_lines_2[0].size()
    
    var total_total: int = 0
    for problem_index in problem_count:
        var parsed_numbers: Array[int] = read_numbers(proc_lines_2, problem_index)
        if problem_index < 6:
            prints("Parsed numbers:", parsed_numbers)
        var acc: int = 1 if operators[problem_index] == "*" else 0
        for number in parsed_numbers:
            if operators[problem_index] == "*":
                acc *= number
            else:
                acc += number
        total_total += acc
    
    prints("Total total:", total_total)
        


func read_numbers(full_input: Array, problem_index: int) -> Array[int]:
    var numbers: Array[int] = []
    var column_count: int = full_input[0][problem_index].size()
    
    for column_i in column_count:
        var column_number: int = 0
        for row_i in full_input.size():
            if full_input[row_i][problem_index][column_i] == -1:
                continue
            column_number = column_number * 10 + full_input[row_i][problem_index][column_i]
        numbers.append(column_number)
    return numbers