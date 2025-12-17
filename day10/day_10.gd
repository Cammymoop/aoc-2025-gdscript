extends Node2D

const MAX_LIGHTS: int = 12 

func get_and_parse_input() -> Dictionary:
    var this_dir: String = (get_script() as GDScript).resource_path.get_base_dir()
    var input_file: = FileAccess.open(this_dir + "/input", FileAccess.ModeFlags.READ)
    if not input_file:
        print_debug("Couldnt open input file")
        return {}
    
    var input_lines: PackedStringArray = input_file.get_as_text().split("\n", false)
    
    var lights_required: Array[Array] = []
    for line in input_lines:
        var first_part: String = line.split(" ")[0].trim_prefix("[").trim_suffix("]")
        var total_lights: = len(first_part)
        var line_required: Array[int] = []
        for i in total_lights:
            if first_part[i] == "#":
                line_required.append(i)
        lights_required.append(line_required)
    
    var toggle_sets: Array[Array] = []
    for line in input_lines:
        var button_parts: PackedStringArray = line.split(" ").slice(1, -1)
        var line_toggle_sets: Array[Array] = []
        for button_part in button_parts:
            var button_nums: PackedStringArray = button_part.trim_prefix("(").trim_suffix(")").split(",")
            var button_nums_ints: Array[int] = []
            for button_num in button_nums:
                button_nums_ints.append(int(button_num))
            line_toggle_sets.append(button_nums_ints)
        toggle_sets.append(line_toggle_sets)
    
    var joltage_requirements: Array[Array] = []
    for line in input_lines:
        var joltage_part: String = line.split(" ")[-1].trim_prefix("{").trim_suffix("}")
        var joltage_nums: PackedStringArray = joltage_part.split(",")
        var joltage_nums_ints: Array[int] = []
        for joltage_num in joltage_nums:
            joltage_nums_ints.append(int(joltage_num))
        joltage_requirements.append(joltage_nums_ints)
        
    return {
        "total_lines": input_lines.size(),
        "lights_required": lights_required,
        "toggle_sets": toggle_sets,
        "joltage_requirements": joltage_requirements,
    }

func _ready() -> void:
    if Engine.is_editor_hint():
        return

    var input_data: Dictionary = get_and_parse_input()
    
    prints('total lines:', input_data["total_lines"])
    
    print("PART 1")
    part_1(input_data)
    
    await get_tree().create_timer(0.1).timeout
    
    print(" ")
    print("PART 2")
    part_2(input_data)
    
    await get_tree().create_timer(0.1).timeout
    get_tree().quit()

func part_1(input_data: Dictionary) -> void:
    var total_buttons_needed: int = range(input_data["total_lines"]).reduce(
        func(acc, i) -> int: return acc + part_1_single(input_data["lights_required"][i], input_data["toggle_sets"][i], i), 0
    )

    #for i in 6:
        #print("------------ size %s ------------" % i)
        #for choice_set in ChoiceIterator.new(['A', 'b', 'C', 'd', 'E'], i):
            #print(' '.join(choice_set))
    
    prints("Total buttons needed:", total_buttons_needed)

func part_1_single(lights_required: Array[int], toggle_sets: Array[Array], line_index: int) -> int:
    if line_index % 10 == 0:
        prints('line %s' % line_index)
    if lights_required.size() == 0:
        return 0
    var total_buttons: int = toggle_sets.size()
    
    var light_target: Array[bool] = []
    for i in MAX_LIGHTS:
        light_target.append(i in lights_required)

    for buttons_used in range(1, total_buttons + 1):
        for button_set in ChoiceIterator.new(range(total_buttons), buttons_used):
            var lights: Array[bool] = []
            lights.resize(MAX_LIGHTS)
            for button_i in button_set:
                for light_i in toggle_sets[button_i]:
                    lights[light_i] = not lights[light_i]
            #prints('light target:', lights_str(light_target), 'this pattern:', lights_str(lights))
            if lights == light_target:
                #prints('Found solution with %s buttons' % buttons_used)
                #prints('Button set:', button_set, ' :: ', toggle_sets)
                return buttons_used

    #for buttons_used in range(1, total_buttons + 1):
        #for set in ChoiceIterator.new(['a', 'b', 'c', 'd'], ):
    
    return -1

func lights_str(lights: Array[bool]) -> String:
    return ''.join(lights.map(func(light: bool) -> String: return "O" if light else "."))


func part_2(input_data: Dictionary) -> void:
    pass

class ChoiceIterator:
    var is_leaf: bool
    var choices_left: int
    var choices: Array
    var sub_iter: ChoiceIterator
    var verbose: bool

    func _init(choices_arr: Array, with_choices: int, set_verbose: bool = false)->void:
        verbose = set_verbose
        choices_left = with_choices
        is_leaf = choices_left < 2
        choices = choices_arr.duplicate()

    func should_continue(iter_arg: Array):
        return iter_arg[0] < choices.size()
    
    func verbose_msg(msg: String):
        if verbose:
            print(msg)

    func _iter_init(args: Array):
        if choices_left == 0:
            return 0
        verbose_msg("iter init (%s) arg: %s :: choices %s" % [choices_left, args, choices])
        args[0] = [0, [0]]
        if not is_leaf:
            new_sub_iter(0, args[0])
        return n_choose_k(choices.size(), choices_left)

    func _iter_next(args: Array):
        verbose_msg("iter next (%s) arg: %s" % [choices_left, args])
        if is_leaf:
            args[0][0] += 1
            return args[0][0] < choices.size()
        else:
            if sub_iter == null or not sub_iter._iter_next(args[0][1]):
                args[0][0] += 1
                new_sub_iter(args[0][0], args[0])
            return args[0][0] + choices_left <= choices.size()

    func _iter_get(iter_arg: Variant) -> Array:
        if choices_left == 0:
            return []
        verbose_msg("iter get (%s) arg: %s" % [choices_left, iter_arg])
        if is_leaf:
            return [choices[iter_arg[0]]]
        else:
            return [choices[iter_arg[0]]] + sub_iter._iter_get(iter_arg[1][0])
    
    func new_sub_iter(index: int, iter_args: Array) -> void:
        iter_args[1] = [0]
        sub_iter = ChoiceIterator.new(choices.slice(index + 1), choices_left - 1, verbose)
        sub_iter._iter_init(iter_args[1])

    static func n_choose_k(n: int, k: int) -> int:
        @warning_ignore("integer_division")
        return fact_recurse(n) / (fact_recurse(k) * fact_recurse(n - k))

    static func fact_recurse(n: int) -> int:
        return n * fact_recurse(n - 1) if n > 1 else 1