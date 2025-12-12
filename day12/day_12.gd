extends Node2D

var present_sizes: Array[int] = [
    5, 7, 7, 7, 7, 6
]

func _ready() -> void:
    part_1()

func part_1() -> void:
    var input_file: = FileAccess.open("res://day12/input", FileAccess.ModeFlags.READ)
    if not input_file:
        print_debug("Couldnt open input file")
        return

    var input_file_text: String = input_file.get_as_text()
    var tree_lines: PackedStringArray = input_file_text.split("\n").slice(30)

    prints("total tree lines:", tree_lines.size())

    var unknown: int = 0
    var disqualified: int = 0
    var easy_pass: int = 0

    for i in tree_lines.size():
        if not tree_lines[i].strip_edges():
            print("skipping line: ", i)
            continue
        var tree_info: = tree_line_info(tree_lines[i])
        if disqualify_tree(tree_info):
            disqualified += 1
        elif easy_pass_check(tree_info):
            easy_pass += 1
        else:
            unknown += 1
    prints("Unkown Status:", unknown, "Disqualified:", disqualified, "Easy Pass:", easy_pass)


func tree_line_info(tree_line_str: String) -> Dictionary:
    var info: Dictionary = {}
    var parts: PackedStringArray = tree_line_str.split(":")
    var size_parts: PackedStringArray = parts[0].split("x")
    var present_numbers: PackedStringArray = parts[1].split(" ", false)
    info["size"] = Vector2(int(size_parts[0]), int(size_parts[1]))
    info["present_numbers"] = Array([], TYPE_INT, &"", null)
    for pnum in present_numbers:
        info["present_numbers"].append(int(pnum))
    return info

func easy_pass_check(tree_info) -> bool:
    var present_grid: Vector2 = (tree_info.size / 3.0).floor()
    var total_presents: int = 0
    for pcount in tree_info.present_numbers:
        total_presents += pcount
    return total_presents <= present_grid.x * present_grid.y

func disqualify_tree(tree_info) -> bool:
    var total_space: int = tree_info.size.x * tree_info.size.y
    var presents_require: int = 0
    for i in tree_info.present_numbers.size():
        var pcount: int = tree_info.present_numbers[i]
        presents_require += pcount * present_sizes[i]
    return presents_require > total_space
