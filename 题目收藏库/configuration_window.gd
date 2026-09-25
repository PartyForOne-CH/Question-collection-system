extends Control
signal refresh()
@onready var window :Window= $Window
@onready var localInnerTrigger :CheckButton = $Window/VBoxContainer/Local_Inner_Trigger_Container/Local_Inner_Trigger
@onready var PathEdit :TextEdit = $Window/VBoxContainer/LocalDataSettingContainer/PathEdit
@onready var DataPathCopy_button :Button = $Window/VBoxContainer/LocalDataSettingContainer/DataPathCopyButton
@onready var comfirm_button :Button = $Window/VBoxContainer/ComfirmContainer/ComfirmButton
@onready var apply_button :Button = $Window/VBoxContainer/ComfirmContainer/ApplyButton
@onready var wordbank_path :String= "res://database//"
@onready var image_path :String= "res://image//"
@onready var config :Dictionary ={}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not FileAccess.file_exists("user://configuration.cfg"):
		DirAccess.copy_absolute('res://configuration.cfg',"user://configuration.cfg")
	else:
		pass
	_signal_connect_func()
	_load_config()
	#var style = StyleBoxFlat.new()
	#style.bg_color = Color.WEB_GRAY
	#style.border_color = Color.WHITE
	#style.border_width_left = 2                   # 边框宽度
	#style.border_width_right = 2
	#style.border_width_top = 2
	#style.border_width_bottom = 2
	#print("Window.borderless 可见: ", $Window.borderless)
	#print("Window theme: ", $Window.theme)
	#print("embedded: ", $Window.is_embedded())
	#$Window.transparent = true
	#print("transparent: ", $Window.transparent_bg)
	#$Window.add_theme_stylebox_override("embedded_border", style)
	
	#$Window/DataPathCopyButton.add_theme_stylebox_override("normal", style)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

#信号连接集合
func _signal_connect_func()->void:
	window.close_requested.connect(_on_close_requested)
	comfirm_button.pressed.connect(_update_config_file)
	comfirm_button.pressed.connect(_on_close_requested)
	apply_button.pressed.connect(_update_config_file)
	localInnerTrigger.toggled.connect(_Local_Inner_Trigger_update.bind(localInnerTrigger))
	DataPathCopy_button.pressed.connect(_Wordbank_CopyTo_PathEdit)
#加载配置到confi字典
func _load_config() -> void:
	var config_file :ConfigFile= ConfigFile.new()
	config_file.load('user://configuration.cfg')
	var src = FileAccess.open('user://configuration.cfg',FileAccess.READ)
	print("配置文件内容：",src.get_as_text())
	#print("加载节块：",config_file.get_sections())
	#else:
		#print("加载失败")
	for section in config_file.get_sections():
		config[section] = {}
		for key in config_file.get_section_keys(section):
			config[section][key] = config_file.get_value(section,key)
			#print(key)
	print("config字典：",config)
	UI_update_config()
#从config字典加载配置到UI
func UI_update_config() -> void:
	if config['data']["data_mode"] == "local":
		localInnerTrigger.button_pressed = 1
	elif config['data']["data_mode"] == "inner":
		localInnerTrigger.button_pressed =0
	else:
		print('config["data_mode"] is error')
	PathEdit.text = config['data']["data_local_path"]

#config字典开关状态更新
func _Local_Inner_Trigger_update(_pressed: bool,button:CheckButton):
	if button.button_pressed == true:
		config['data']['data_mode'] = 'local'
	elif button.button_pressed == false:
		config['data']['data_mode'] = 'inner'
		
#更新数据推送至本地的地址
func _PathEdit_update()->void:
	if config["data"]["data_local_path"]:
		config["data"]["data_local_path"] = PathEdit.text
	else:
		print('No valid config["data"]["data_local_path"]!!')
#处理配置文件的打包问题
#防误触处理
#添加配置文件和字典匹配检查函数
#确保路径已存在
func _dir_check(dir_list:Array)->void:
	for dir in dir_list:
		if DirAccess.dir_exists_absolute(dir):
			print("dir'%s' already exists."%dir)
		else:
			DirAccess.make_dir_recursive_absolute(dir)
			print("make dir'%s'."%dir)
			
func _Wordbank_CopyTo_PathEdit()->void:
	var config_file :ConfigFile= ConfigFile.new()
	config_file.load('user://configuration.cfg')
	var current_time :String
	var target_path :String
	var target_path_database :String#tap
	var target_path_image :String
	var project_name = Global.project_name
	var wordbank_FileName :String = Global.wordbank_FileName
	var path_list :Array#检查路径存在
	#print(Global.project_name) 
	if config["data"]["data_local_path"]:
		_PathEdit_update()
		config_file.set_value("data","data_local_path",config["data"]["data_local_path"])
		target_path = PathEdit.text+'\\'+project_name
		target_path_database = target_path+'\\'+"database"
		target_path_image = target_path+ "\\"+"image"
		path_list =[target_path,target_path_database,target_path_image]
		#print("项目名称：",project_name)
		_dir_check(path_list)
		if FileAccess.file_exists(target_path_database+'\\'+wordbank_FileName):#bei备份旧数据
			current_time = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")+'_'
			DirAccess.copy_absolute(target_path_database+'\\'+wordbank_FileName,target_path+'\\'+current_time+wordbank_FileName)
		copy_folder_recursive(image_path,target_path_image)
		copy_folder_recursive(wordbank_path,target_path_database)
		#DirAccess.copy_absolute(wordbank_path,target_path_database+'\\'+wordbank_FileName)
	else:
		print('No valid config["data"]["data_local_path"]!!')
#复制目录
func copy_folder_recursive(src_dir: String, dst_dir: String) -> Error:
	# 确保目标目录存在
	if not DirAccess.dir_exists_absolute(dst_dir):
		var err = DirAccess.make_dir_recursive_absolute(dst_dir)
		if err != OK:
			return err
	# 复制当前目录下的所有文件
	var files = DirAccess.get_files_at(src_dir)
	for file_name in files:
		var src_file = src_dir.path_join(file_name)
		var dst_file = dst_dir.path_join(file_name)
		var err = DirAccess.copy_absolute(src_file, dst_file)
		if err != OK:
			return err
	# 递归处理子目录
	var sub_dirs = DirAccess.get_directories_at(src_dir)
	for sub_dir in sub_dirs:
		var src_sub = src_dir.path_join(sub_dir)
		var dst_sub = dst_dir.path_join(sub_dir)
		var err = copy_folder_recursive(src_sub, dst_sub)
		if err != OK:
			return err
	return OK
#确认修改配置文件表
func _update_config_file():
	_PathEdit_update()
	var config_file :ConfigFile= ConfigFile.new()
	config_file.load('user://configuration.cfg')
	for section in config.keys():
		for key in config[section]:
			config_file.set_value(section,key,config[section][key])
	config_file.save('user://configuration.cfg')
func _on_close_requested() -> void:
	var config_file :ConfigFile= ConfigFile.new()
	config_file.load('user://configuration.cfg')
	#print('data_mode:',config_file.get_value("data","data_mode"))
	window.hide()
	refresh.emit()
	pass # Replace with function body.
