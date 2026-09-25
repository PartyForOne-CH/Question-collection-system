extends Node2D
var file = FileAccess.open("res://database/wordbank.json", FileAccess.READ)
var array_tem :Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_add_category_item()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func _add_category_item():
	var data_all :Dictionary
	if file:
		var content = file.get_as_text()
		data_all = JSON.parse_string(content)
		array_tem = data_all["历史文化"]
		print(len(array_tem))
		for i in range(len(array_tem)):
			array_tem[i]["id"] = i+1
			if not array_tem[i].has("image"):
				array_tem[i]["image"] = 'none'
			else:
				pass
			print(array_tem[i]["id"])
		var new_file = FileAccess.open("res://new.json", FileAccess.WRITE)
		new_file.store_string(JSON.stringify(array_tem, "\t"))
		new_file.close()
		
		#调整ID
