extends Node2D

var adjacents: Array[Vector2i] = [
    Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
    Vector2i(-1, 0),                  Vector2i(1, 0),
    Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
]

func _ready() -> void:
    var input_file: = FileAccess.open("res://day4/input", FileAccess.ModeFlags.READ)
    if not input_file:
        print_debug("Couldnt open input file")
        return
    
    var input_lines: PackedStringArray = input_file.get_as_text().split("\n", false)
    var grid: Array[String] = []
    grid.assign(input_lines)
    
    print("PART 1")
    part_1(grid)
    
    await get_tree().create_timer(0.1).timeout
    
    print(" ")
    print("PART 2")
    await part_2(grid)
    
    await get_tree().create_timer(0.1).timeout
    get_tree().quit()

func part_1(grid: Array[String]) -> void:
    var padded_grid: Array[String] = pad_grid(grid)
    
    var accessible: int = 0
    prints("Grid row size:", grid[0].length(), "padded grid row size:", padded_grid[0].length())
    for y in grid.size():
        for x in grid[0].length():
            if grid[y][x] != "@":
                continue
            var pos: Vector2i = Vector2i(x+1, y+1)
            if count_str_around(padded_grid, "@", pos) < 4:
                accessible += 1
    prints("Accessible Rolls:", accessible)

func part_2(grid: Array[String]) -> void:
    var padded_grid: Array[String] = pad_grid(grid)
    
    var accessible: int = 0
    var iterations: int = 0
    var found_this_iteration: bool = false
    while true:
        iterations += 1
        if iterations % 50 == 0:
            await get_tree().process_frame
        if iterations % 200 == 0:
            print("Iteration:", iterations)
            print("\n".join(padded_grid))
        if iterations > 50000:
            print_debug("Max iterations reached")
            print("\n".join(padded_grid))
            return

        found_this_iteration = false    
        var before_accessible: int = accessible
        for y in grid.size():
            for x in grid[0].length():
                if padded_grid[y+1][x+1] != "@":
                    continue
                var pos: Vector2i = Vector2i(x+1, y+1)
                if count_str_around(padded_grid, "@", pos) < 4:
                    found_this_iteration = true
                    accessible += 1
                    padded_grid[y+1][x+1] = "x"
        prints("Found this iteration:", accessible - before_accessible, "Accessible:", accessible)
        if not found_this_iteration:
            print("Ok done")
            break

    prints("Iterations:", iterations, "Total Accessible Rolls:", accessible)
    print("\n".join(padded_grid))

func count_str_around(grid: Array[String], find_str: String, pos: Vector2i) -> int:
    var row_length: int = grid[0].length()
    if pos.x <= 0 or pos.x >= row_length - 1 or pos.y <= 0 or pos.y >= grid.size() - 1:
        print_debug("Position out of bounds: ", pos)
    var count: int = 0
    for offset in adjacents:
        if grid[pos.y + offset.y][pos.x + offset.x] == find_str:
            count += 1
    return count


func pad_grid(grid: Array[String]) -> Array[String]:
    var new_grid: Array[String] = grid.duplicate()
    var row_length: int = grid[0].length()
    var empty_row: String = ".".repeat(row_length)
    new_grid.push_front(empty_row)
    new_grid.push_back(empty_row)
    for i in new_grid.size():
        new_grid[i] = "." + new_grid[i] + "."
    return new_grid