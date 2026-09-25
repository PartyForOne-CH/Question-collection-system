extends Window
@onready var main_window = $"."
@onready var picture_container = $VBoxContainer
@onready var picture:Texture2D = $VBoxContainer/TextureRect.texture


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	size_regulate(main_window,picture_container,picture)
	#main_window.position = Vector2(0,100)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

#根据图片尺寸，调整窗口大小
func size_regulate(window:Window,container:Container,texture:Texture2D) -> void:
	var texture_size_x = texture.get_size().x
	var texture_size_y = texture.get_size().y
	if texture_size_x>= 1000:
		texture_size_x = 1000
	if texture_size_y>=640:
		texture_size_y=640
	container.size = Vector2(texture_size_x,texture_size_y)
	window.size = Vector2((texture_size_x+30),(texture_size_y+30))
	var container_position_x = (window.get_size().x-texture_size_x)/2
	var container_position_y = (window.get_size().y-texture_size_y)/2
	container.position = Vector2(container_position_x,container_position_y)
	#print("窗口位置：",main_window.position)

func _on_close_requested() -> void:
	hide()
	pass # Replace with function body.
