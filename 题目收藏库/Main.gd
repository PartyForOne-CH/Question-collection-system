extends Control
@onready var pop_up_window :Window = $Window
@onready var remain_label = $VBoxContainer/MarginContainer/HBoxContainer/RemainTextLabel
@onready var question_label = $VBoxContainer/MarginContainer/HBoxContainer/QuestionLabel
@onready var explanation_label = $VBoxContainer/MarginContainer/HBoxContainer/ExplanationLabel
@onready var next_button = $VBoxContainer/ButtonContainer/NextButton
@onready var explanation_button = $VBoxContainer/ButtonContainer/ExplanationButton
@onready var reselect_button = $VBoxContainer/ButtonContainer/ReselectButton
@onready var comfirm_button = $VBoxContainer/ButtonContainer/ComfirmButton
@onready var picture_button = $VBoxContainer/ButtonContainer/PictureButton
#选项组
@onready var group = ButtonGroup.new()
@onready var options1 = $VBoxContainer/MarginContainer/HBoxContainer/Node2D/Options1
@onready var options2 = $VBoxContainer/MarginContainer/HBoxContainer/Node2D/Options2
@onready var options3 = $VBoxContainer/MarginContainer/HBoxContainer/Node2D/Options3
@onready var options4 = $VBoxContainer/MarginContainer/HBoxContainer/Node2D/Options4
var options_array :Array
var option_bank: Array = []
var option_flag :bool = true#判断选项是否正确的标志

var data:Dictionary = Global.data
var remain_num_dic :Dictionary = {}
var data_copy:Dictionary
var categorie_1_list :Array = []
var categorie_2_temporary :Array = []#l遍历键1时，临时存放对应的键2
var categorie_1_choosen
var categorie_2_choosen
var answer_check :String
var remain_num :int 
#var keybord_count :int = 0
var comfrimed_flag :bool= false#标志是否已显示正确答案（双击确认直接下一个）
var color = Color.WHITE#存放选项的颜色（双击确认直接下一个）
func _ready():
	_options_group_setting()
	all_setting_reset()
	pop_up_window.visible = false
	next_button.pressed.connect(_on_random_pressed)
	explanation_button.pressed.connect(_on_meaning_pressed)
	comfirm_button.pressed.connect(_option_proofreading)
	reselect_button.pressed.connect(return_to_persetting)
	picture_button.pressed.connect(_show_picture)
#func _debug() -> void:
	#var debugcolor:String
	#var debugcomfrimed:String
	#if color == Color.WHITE:
		#debugcolor = "白色"
	#elif color == Color.GREEN:
		#debugcolor = "绿色"
	#else:
		#debugcolor = "其他颜色"
	#if comfrimed_flag:
		#debugcomfrimed = "已确定"
	#else:
		#debugcomfrimed = "未确定"
	#$MarginContainer/HBoxContainer/DebugLabel.text = debugcolor + debugcomfrimed + "键盘点击次数：" +str(keybord_count)
func _process(_delta: float) -> void:
	#_debug()
	if Input.is_action_just_pressed("NEXT"):
		#print("if Input.is_action_pressed(NEXT) or comfrimed_flag == true:")
		comfrimed_flag = false
		_on_random_pressed()
	elif Input.is_action_just_pressed("COMFIRM"):
		#keybord_count += 1
		#print("回车键点击次数：",keybord_count)
		comfirm_button.emit_signal("pressed")
		#_option_proofreading()
	elif color == Color.GREEN and comfrimed_flag == true:#（双击确认直接下一个）
		_on_random_pressed()
		
func all_setting_reset():
	data_copy = data.duplicate(true)
	categorie_1_list= Global.keys_layer1_list.duplicate(true)
	#生成题目库、各章节数量计数
	for i in range(len(categorie_1_list)):
		data_copy[categorie_1_list[i]] = data_copy[categorie_1_list[i]].slice(Global.start_index-1,Global.end_index)
		remain_num_dic[categorie_1_list[i]] = Global.question_num
		if remain_num_dic[categorie_1_list[i]] > len(data_copy[categorie_1_list[i]]):
			remain_num_dic[categorie_1_list[i]] = len(data_copy[categorie_1_list[i]])
	#print("remain_num_dic:\n",remain_num_dic)
	_remain_num_update()

func _on_random_pressed():
	_option_proofreading()
	if not option_flag:
		return
	else:
		pass
	explanation_label.visible = false
	pop_up_window.close_requested.emit()
	if remain_num == 0:
		#print("if remain_num == 0:")
		question_label.text = "重新加载"
		all_setting_reset()
	_pick_question()


func _pick_question():	#随机挑选公式
	#判定顺序还是随机
	if Global.mode == 'random':
		var random_index_1 = randi() % len(categorie_1_list)
		categorie_1_choosen = categorie_1_list[random_index_1]#存放随机到的键1
		#没有key了，现在是数组
		categorie_2_temporary = data_copy[categorie_1_choosen]
		var random_index_2 = randi() % len(categorie_2_temporary)#可通过添加范围知道随机范围
		categorie_2_choosen = categorie_2_temporary[random_index_2]#随机单个题目
	elif Global.mode == 'sequence':
		var sequence_index_1 :int = 0
		categorie_1_choosen = categorie_1_list[sequence_index_1]
		#没有key了，现在是数组
		categorie_2_temporary = data_copy[categorie_1_choosen]
		var sequence_index_2 :int = 0
		categorie_2_choosen = categorie_2_temporary[sequence_index_2]
	question_label.text = categorie_2_choosen["question"]
	var original :String = categorie_2_choosen["theme"]+'： \n'+categorie_2_choosen["original"]
	explanation_label.text = original
	answer_check = categorie_2_choosen["answer"]
	_on_option_text(categorie_2_choosen)#传入正确答案
	#加载图片
	if categorie_2_choosen.has("image"):
		_example_image_load(pop_up_window,categorie_2_choosen["image"])
	else:
		picture_button.disabled = true
	#遍历后删除
	data_copy[categorie_1_choosen].erase(categorie_2_choosen)
	remain_num_dic[categorie_1_choosen] -= 1
	#print("remain_num_dic:\n",remain_num_dic)
	_remain_num_update()
	#print("remain_num_dic[categorie_1_choosen]:",remain_num_dic[categorie_1_choosen])
	#键1无内容后删除
	if remain_num_dic[categorie_1_choosen] == 0:
		#print("已擦除键:",categorie_1_choosen)
		data_copy.erase(categorie_1_choosen)
		categorie_1_list.erase(categorie_1_choosen)
	else:
		pass

	
func _example_image_load(window:Window,path):
	if not FileAccess.file_exists("user://configuration.cfg"):#检查本地配置文件
		DirAccess.copy_absolute('res://configuration.cfg',"user://configuration.cfg")
	else:
		pass
	var texture_rect :TextureRect= window.get_node("VBoxContainer/TextureRect")
	var config_file :ConfigFile= ConfigFile.new()
	config_file.load('user://configuration.cfg')
	var data_mode :String= config_file.get_value('data','data_mode')
	var data_local_path :String = config_file.get_value('data','data_local_path')
	if data_mode == 'inner':
		if path == 'none':
			picture_button.disabled = true
			texture_rect.texture = ResourceLoader.load("res://image/404.jpg")
		else:
			picture_button.disabled = false
			texture_rect.texture = ResourceLoader.load(path)
	elif data_mode == 'local':#tap
		if path == 'none':
			picture_button.disabled = true
			texture_rect.texture = ResourceLoader.load("res://image/404.jpg")
		else:
			var path_last_word :String= path.get_file()+".png"
			#print("path_last_word :",path_last_word)
			path = data_local_path+'//'+Global.project_name+"//"+"image//"+path_last_word
			picture_button.disabled = false
			texture_rect.texture = ResourceLoader.load(path)
		print(path)
	else:
		print("config_file['data']['data_mode'] is not valid!!!")	
	window.picture= texture_rect.texture#更新弹窗内部变量
	window.size_regulate(window.main_window,window.picture_container,window.picture)

func _options_group_setting():#选项分组
	options1.button_group = group
	options2.button_group = group
	options3.button_group = group
	options4.button_group = group
	options_array =group.get_buttons()
		
func _on_option_text(aim_dic):	#选项信息填充
	_on_option_reset()
	#var option_random_index = randi() % group.get_buttons().size()
	#options_array[option_random_index].text = aim_dic["answer"]
	var options :Array= aim_dic["options"]
	for i in range(len(options_array)):#补充错误选项
		var option_random_index = randi() % len(options)
		if len(options) ==0:
			pass
		else:
			options_array[i].text = options[option_random_index]
			options.remove_at(option_random_index)
func _on_option_reset():	#重置选项文字
	option_flag = false
	comfrimed_flag = false#（双击确认直接下一个）
	color = Color.WHITE#（双击确认直接下一个）
	for i in range(len(options_array)):
		options_array[i].text = ''
		options_array[i].button_pressed = false
		options_array[i].remove_theme_color_override("font_color")
		options_array[i].remove_theme_color_override("font_pressed_color")
	
func _on_meaning_pressed():
	if not explanation_label.visible:
		explanation_label.visible = true
	else:
		explanation_label.visible = false

func _option_proofreading():#重置选项样式
	var selected_option = group.get_pressed_button()
	if not selected_option:
		return
	if color == Color.GREEN and comfrimed_flag == false:#（双击确认直接下一个）
		#print("comfrimed_flag:",comfrimed_flag)
		comfrimed_flag = true
	else:
		pass
	selected_option.focus_mode = Control.FOCUS_NONE
	color = Color.GREEN if selected_option.text == answer_check else Color.RED
	option_flag = true if selected_option.text == answer_check else false
	selected_option.add_theme_color_override("font_pressed_color", color)
	selected_option.add_theme_color_override("font_color", color)
	if selected_option.text == answer_check:
		_on_meaning_pressed()

func _remain_num_update():#改
	remain_label.text = "剩余数量："+str(remain_num)
	remain_num = 0
	for i in range(len(categorie_1_list)):
			#remain_num += (data_copy[categorie_1_list[i]]).size()
			remain_num += remain_num_dic[categorie_1_list[i]]

func _show_picture():#弹出图示窗口
	pop_up_window.popup_centered()
	#pop_up_window.position += Vector2i(0,100)#应急，待优化
	#print("窗口位置：",pop_up_window.position)
	
func return_to_persetting()->void:
	get_tree().change_scene_to_file("res://per_setting.tscn")
