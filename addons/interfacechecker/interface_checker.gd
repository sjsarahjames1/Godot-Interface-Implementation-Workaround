@tool
extends EditorPlugin

class_name InterfaceChecker

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	var impl_resource: ImplementsResource = preload("res://addons/interfacechecker/implements_resource.tres")
	impl_resource.implements = implements.duplicate_deep()
	ResourceSaver.save(impl_resource)
	
	

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	
	resource_saved.connect(on_resource_saved)

func on_resource_saved(res: Resource) -> void:
	if res is Script:
		check_implementations()

func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	var impl_resource: ImplementsResource = preload("res://addons/interfacechecker/implements_resource.tres")
	impl_resource.implements = implements.duplicate_deep()
	ResourceSaver.save(impl_resource)
	

const INTERFACES_JSON: JSON = preload("res://addons/interfacechecker/interfaces.json")
const IMPLEMENTERS_JSON: JSON = preload("res://addons/interfacechecker/implementers.json") 

const INTERFACE_KEY_MAX: int = 2
const IMPLEMENTER_KEY_MAX: int = 3

const INTERFACE_DATA_PATH_KEY: String = "path"
const IMPLEMENTER_DATA_PATH_KEY: String = "path"
const IMPLEMENTERS_DATA_IMPLEMENTED_KEY: String = "implements"

static var implements: Dictionary[Script, Array] = {}

func check_implementations() -> void:
	if !Engine.is_editor_hint(): return
	var interfaces_data: Dictionary = INTERFACES_JSON.data
	var implementers_data: Dictionary = IMPLEMENTERS_JSON.data
	
	var obj: Object = Object.new()	
	
	var interfaces_method_lists: Dictionary = {}
	var interfaces_property_lists: Dictionary = {}
	
	for interface_name in interfaces_data.keys():
		var interface_paths: Dictionary = interfaces_data[interface_name]
		var interface: Script = load(interface_paths[INTERFACE_DATA_PATH_KEY])
		
		var interface_base_method_list: Array = obj.get_method_list()
		interfaces_method_lists.get_or_add(interface_name, interface.get_script_method_list().filter(func(method_dict: Dictionary): return !_method_list_has_method(method_dict, interface_base_method_list)))
		var interface_base_prop_list: Array = obj.get_property_list()
		interfaces_property_lists.get_or_add(interface_name, interface.get_script_property_list().filter(func(property_dict: Dictionary): return !_property_list_has_property(property_dict, interface_base_prop_list) && !(property_dict["name"] as String).ends_with(".gd")))

	var implementers_method_lists: Dictionary = {}
	var implementers_property_lists: Dictionary = {}
	
	var implementers_unimplemented_method_lists: Dictionary = {}	
	var implementers_unimplemented_property_lists: Dictionary = {}
	
	for implementer_name in implementers_data.keys():
		var implementer_paths: Dictionary = implementers_data[implementer_name]
		var implementer: Script = load(implementer_paths[IMPLEMENTER_DATA_PATH_KEY])
	
		var implementer_base_method_list: Array = obj.get_method_list()
		implementers_method_lists.get_or_add(implementer_name, implementer.get_script_method_list().filter(func(method_dict: Dictionary): return !_method_list_has_method(method_dict, implementer_base_method_list)))
		var implementer_base_prop_list: Array = obj.get_property_list()
		implementers_property_lists.get_or_add(implementer_name, implementer.get_script_property_list().filter(func(property_dict: Dictionary): return !_property_list_has_property(property_dict, implementer_base_prop_list) && !(property_dict["name"] as String).ends_with(".gd")))
	
		for implemented_interface in implementers_data[implementer_name][IMPLEMENTERS_DATA_IMPLEMENTED_KEY]:
			
			implementers_unimplemented_method_lists.get_or_add({implementer_name: implemented_interface}, (interfaces_method_lists[implemented_interface] as Array).filter(func(method_dict: Dictionary): return !_method_list_has_method(method_dict, implementers_method_lists[implementer_name])))
		for implemented_interface in implementers_data[implementer_name][IMPLEMENTERS_DATA_IMPLEMENTED_KEY]:
			implementers_unimplemented_property_lists.get_or_add({implementer_name : implemented_interface}, (interfaces_property_lists[implemented_interface] as Array).filter(func(property_dict: Dictionary): return !_property_list_has_property(property_dict, implementers_property_lists[implementer_name])))
	
		for implementer_to_interface in implementers_unimplemented_method_lists:
			var unimplemented_funcs: Array = implementers_unimplemented_method_lists[implementer_to_interface]
			if len(unimplemented_funcs) == 0:
				continue
			var error_dict: Dictionary = {"title": implementer_to_interface.keys()[0] + " does not implement " + implementer_to_interface.values()[0] + " methods:"}
		
			for unimplemented_func in unimplemented_funcs:
				var unimplemented_arg_str: String
				
				for arg in unimplemented_func["args"]:
					var arg_index = (unimplemented_func["args"] as Array).find(arg)
					unimplemented_arg_str += "'" +  str(arg_index)+"' ("
					unimplemented_arg_str += "-name: " + arg["name"] + ", -type: " + type_string(arg["type"]) + ")"
					if arg_index == len(unimplemented_func["args"]) -1:
						continue 
					unimplemented_arg_str += ", "
				error_dict.get_or_add(unimplemented_func["name"], "func: " + unimplemented_func["name"] + "( Parameters: " + (unimplemented_arg_str if len(unimplemented_arg_str) > 0 else "None") + ") -> Return: " + ("( -type: " + type_string(unimplemented_func["return"]["type"]) + ") " if type_string(unimplemented_func["return"]["type"]) != "Nil" else "None"))
				if unimplemented_funcs.find(unimplemented_func) == len(unimplemented_funcs)-1:
					continue
				
			for err_part in error_dict:
				push_error(error_dict[err_part])
		
		print("\n")
			
		
		
		for implementer_to_interface in implementers_unimplemented_method_lists:
			var unimplemented_propertys: Array = implementers_unimplemented_property_lists[implementer_to_interface]
			if len(unimplemented_propertys) == 0:
				continue
			var error_dict: Dictionary = {"title": implementer_to_interface.keys()[0] + " does not implement " + implementer_to_interface.values()[0] + " properties: \n"}
		
			for unimplemented_property in unimplemented_propertys:
				
				error_dict.get_or_add(unimplemented_property["name"],"property: " + unimplemented_property["name"]  + (" -type: " + type_string(unimplemented_property["type"]) if type_string(unimplemented_property["type"]) != "" else "None"))
				if unimplemented_propertys.find(unimplemented_property) == len(unimplemented_propertys)-1:
					continue
			for err_part in error_dict:
				push_error(error_dict[err_part])
				
	var implementers: Array = implementers_unimplemented_method_lists.keys().filter(func(implementer: Dictionary):
		for implementer_interface in implementers_unimplemented_method_lists: 
			if len(implementers_unimplemented_method_lists[implementer_interface]) != 0: 	
				return false
		return true)
	implementers.append_array(implementers_unimplemented_property_lists.keys().filter(
	func(implementer: Dictionary): 
		for implementer_interface in implementers_unimplemented_property_lists: 
			if len(implementers_unimplemented_property_lists[implementer_interface]) != 0: 
				return false
		return true
		)
	)
	implementers = implementers.filter(func(implementer: Dictionary): return implementers.count(implementer) >= 2)
	var new_implementers: Array = []
	for implementer in implementers:
		if !new_implementers.has(implementer):
			new_implementers.append(implementer)
	implementers = new_implementers
	for implementer in implementers:
		var implementer_script: Script = load(implementers_data[implementer.keys()[0]]["path"])
		var interface_script: Script = load(interfaces_data[implementer.values()[0]]["path"])
		if len(implements.keys().filter(func(script: Script): return ResourceUID.path_to_uid(implementer_script.resource_path) == implementers_data[implementer.keys()[0]]["uid"])) > 0:
			continue
			
	for implementer_interface in implementers:
		var implementer_script: Script =  load(implementers_data[implementer_interface.keys()[0]]["path"])
		var interface_script: Script = load(interfaces_data[implementer_interface.values()[0]]["path"])
		if !implements.has(implementer_script):
			implements.get_or_add(implementer_script, [])
		if !implements[implementer_script].has(interface_script):
			implements[implementer_script].append(interface_script)
		
	var impl_resource:= load("res://addons/interfacechecker/implements_resource.tres")
	impl_resource.implements = implements
	ResourceSaver.save(impl_resource)
	
func _method_list_has_method(method_dict_to_find: Dictionary, method_list_to_search: Array) -> bool:
	var found_name_match: bool = false
	var found_method: Dictionary
	for method in method_list_to_search:
		if method["name"] == method_dict_to_find["name"]:
			found_name_match = true
			found_method = method
			break
	if !found_name_match: return false

	for method_prop in found_method:
		if !method_dict_to_find.has(method_prop):
			return false
		
		if method_dict_to_find[method_prop] != found_method[method_prop] && method_prop != "return" && (method_prop != "flags" && found_method["flags"] != 128):
			return false
		elif method_prop == "return":
			for return_prop in found_method["return"]:
				if !method_dict_to_find["return"].has(return_prop):
					return false
				if method_dict_to_find["return"][return_prop] != found_method["return"][return_prop]:
					return false
	
	return true
			
func _property_list_has_property(property_dict_to_find: Dictionary, property_list_to_search: Array) -> bool:
	var found_name_match: bool = false
	var found_property: Dictionary
	for property in property_list_to_search:
		if property["name"] == property_dict_to_find["name"]:
			found_name_match = true
			found_property = property
			break
	if !found_name_match: return false

	for property_prop in found_property:
		if !property_dict_to_find.has(property_prop):
			return false
		if property_dict_to_find[property_prop] != found_property[property_prop]:
			return false
	
	return true

static func does_object_implement_script(obj: Object, script: Script) -> bool:
	var impl_resource:=load("res://addons/interfacechecker/implements_resource.tres")
	if !(impl_resource as ImplementsResource).implements.has(obj.get_script()): return false
	elif !impl_resource.implements[obj.get_script()].has(script): return false
	return true
