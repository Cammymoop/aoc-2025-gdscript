extends Node2D

func _ready() -> void:
    var input_file: = FileAccess.open("res://day3/input", FileAccess.ModeFlags.READ)
    if not input_file:
        print_debug("Couldnt open input file")
        return
    
    var input_lines: PackedStringArray = input_file.get_as_text().split("\n", false)
    
    print("PART 1")
    part_1(input_lines)
    
    print(" ")
    print("PART 2")
    part_2(input_lines)
    
    await get_tree().create_timer(0.1).timeout
    get_tree().quit()

func part_1(input_lines: PackedStringArray) -> void:
    var joltage_sum: int = Array(input_lines).reduce(func(acc, line): return acc + max_joltage(line), 0)
    prints("num battery banks:", input_lines.size(), "joltage sum:", joltage_sum)
    
func max_joltage(battery_bank: String) -> int:
    var first_digit: int = -1
    var first_digit_index: int = -1
    for d in range(9, 0, -1):
        var found_at: int = battery_bank.find(str(d))
        if found_at != -1 and found_at <= battery_bank.length() - 2:
            first_digit = d
            first_digit_index = found_at
            break
    if first_digit == -1:
        print_debug("No first digit found")
        return -10000
    var second_part: String = battery_bank.substr(first_digit_index + 1)
    for d in range(9, 0, -1):
        if second_part.find(str(d)) != -1:
            return first_digit * 10 + d
    print_debug("No second digit found")
    return -10000

func part_2(input_lines: PackedStringArray) -> void:
    var joltage_sum: int = Array(input_lines).reduce(func(acc, line): return acc + max_joltage_2(line), 0)
    prints("num battery banks:", input_lines.size(), "joltage sum:", joltage_sum)

func max_joltage_2(battery_bank: String) -> int:
    const BATTERIES_TO_ENABLE: int = 12

    var number_string: String = ""
    for current_digit_index in BATTERIES_TO_ENABLE:
        var this_digit: int = -1
        for d in range(9, 0, -1):
            var found_at: int = battery_bank.find(str(d))
            if found_at != -1 and found_at <= battery_bank.length() - (BATTERIES_TO_ENABLE - current_digit_index):
                this_digit = d
                battery_bank = battery_bank.substr(found_at + 1)
                break
        if this_digit == -1:
            print_debug("No %dth digit found" % current_digit_index)
            return -10000
        number_string += str(this_digit)

    return int(number_string)
