extends Node


static var ready_conditionals: Dictionary[Variant, Variant] = {}
	
static var process_conditionals: Dictionary[Variant, Variant] = {}
static var physics_process_conditionals: Dictionary[Variant, Variant] = {}

func _ready() -> void:
	connect_signals()
	
func connect_signals() -> void:
	ready.connect(on_ready)
	get_tree().process_frame.connect(on_process_frame)
	get_tree().physics_frame.connect(on_physics_process_tick)

static func on_ready() -> void:
	reset_and_test_ready_conditionals()
	

static func on_process_frame() -> void:
	reset_and_test_process_conditionals()
	
static func on_physics_process_tick() -> void:
	reset_and_test_physics_process_conditionals()
	
static func reset_and_test_ready_conditionals() -> void:
	for conditional in ready_conditionals:
		ready_conditionals[conditional] = conditional.test(ready_conditionals)

static func reset_and_test_process_conditionals() -> void:
	for conditional in process_conditionals:
		process_conditionals[conditional] = conditional.test(process_conditionals)

static func reset_and_test_physics_process_conditionals() -> void:
	for conditional in process_conditionals:
		process_conditionals[conditional] = conditional.test(process_conditionals)

static func add_conditional_to_process_conditionals(conditional: Variant) -> bool:
	print(load("res://addons/interfacechecker/implements_resource.tres").implements)
	if !InterfaceChecker.does_object_implement_script(conditional, preload("res://scripts/conditional/conditional.gd")):
		push_error("Tried to add variant that doesn't implement Conditional.gd to process_conditionals")
		return false
	process_conditionals.get_or_add(conditional, null)
	return true
