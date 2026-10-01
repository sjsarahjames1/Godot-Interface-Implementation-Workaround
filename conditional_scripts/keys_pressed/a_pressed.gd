extends Node

func _init() -> void:
	ConditionalsManager.add_conditional_to_process_conditionals(self)

func test(conditionals: Dictionary[Variant, Variant]) -> bool:
	return Input.is_physical_key_pressed(KEY_A)
