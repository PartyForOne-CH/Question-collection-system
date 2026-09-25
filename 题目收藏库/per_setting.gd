extends Control

#整体思路：1、确定全局变量，映射至UI
#		2、UI变更后同步修改全局变量（信号），实现保存操作的效果
#		3、顶层学科的UI和学科的习题配置UI功能实现分开管理
@onready var configuration_button = $BoxContainer/HBoxContainer2/Control_Configuration/ConfigurationButton
@onready var confirm_button = $BoxContainer/HBoxContainer/ConfirmButton
@onready var reset_button = $BoxContainer/HBoxContainer/ResetButton
@onready var Discipline_edit = $BoxContainer/SettingListContainer/DisciplineContainer/DisciplineButton
@onready var category_edit: OptionButton = $BoxContainer/SettingListContainer/CategorySetting/CategoryType
@onready var file:FileAccess
#@onready var file_path:String
@onready var word_num_edit = $BoxContainer/SettingListContainer/RangeSetting/Num
@onready var start_index_edit = $BoxContainer/SettingListContainer/RangeSetting/StartIndex
@onready var end_index_edit = $BoxContainer/SettingListContainer/RangeSetting/EndIndex
@onready var work_mode_edit = $BoxContainer/SettingListContainer/WorkModeContainer/OptionButton
@onready var configuration_window :Window= $Configuration_Window.window
var data_mode :String#判定数据库来源是程序内部还是本地路径
var data_local_path :String#存放在本地的数据库路径
var category_list :Array = []
var Discipline_list :Array = []#文件夹中的学科数据库目录
var Discipline: String#当前学科
var category: String
var test_pa :int = 0

# Called when the node enters the scene tree for the first time.
func _ready():#添加开始索引检查，避免开始索引超出数组长度
	
	_UI_setting()
	_signal_connect_func()
	category_edit.item_selected.emit(0)#进入页面后自动读取一次文件
	
	
func _process(_delta: float) -> void:
	if start_index_edit.value >= end_index_edit.value:
		confirm_button.disabled = true
	elif word_num_edit.value > end_index_edit.value - start_index_edit.value+1:
		word_num_edit.value = end_index_edit.value - start_index_edit.value+1
	else:
		confirm_button.disabled = false
	pass
	
	
#连接信号
func _signal_connect_func()->void:
	configuration_button.pressed.connect(_configuration_window_popup)
	Discipline_edit.item_selected.connect(_change_Discipline)
	category_edit.item_selected.connect(_change_category_load_data)
	reset_button.pressed.connect(_restore_global_setting)
	reset_button.pressed.connect(_apply_global_setting)
	confirm_button.pressed.connect(_Final_setting)
	confirm_button.pressed.connect(change_scene)
	$Configuration_Window.refresh.connect(_restore_global_setting)
	$Configuration_Window.refresh.connect(_UI_setting)



# 先判定学科/更改学科应该触发重置函数。当前矛盾：更改学科直接使用重置函数将无法保存配置
#对策，将学科作为最高优先级的组件，将学科和类别选择的信号、UI、重置功能代码分离，且学科的信号后接
#分开重置
func _UI_setting()->void:#打开文件->重置UI->加载UI
	_config_apply()
	
	_Discipline_UI_setting()
	_DisciplineSubordinate_UI_setting()

func _Discipline_UI_setting()->void:
	
	_clear_Discipline_item()
	_add_Discipline_item()
func _DisciplineSubordinate_UI_setting()->void:
	_file_open()
	_clear_category_item()
	_add_category_item()
	_apply_global_setting()	
#应用整体配置
func _config_apply()->void:
	if not FileAccess.file_exists("user://configuration.cfg"):
		DirAccess.copy_absolute('res://configuration.cfg',"user://configuration.cfg")
	else:
		pass
	var config_file :ConfigFile= ConfigFile.new()
	config_file.load('user://configuration.cfg')
	data_mode = config_file.get_value('data','data_mode')
	data_local_path  = config_file.get_value('data','data_local_path')
#根据配置，打开内部或本地数据文件
func _file_open()->void:#复制配置文件到用户路径，打开词库数据文件
	if not data_mode or not data_local_path:
		print("'data_mode' or 'data_local_path' is invaild!!")
		return
	if file == null:
		pass
	else:
		file = null
	#1、检查数据模式。2、检查数据库是否存在
	if data_mode == 'inner':
		if FileAccess.file_exists("res://database/"+Global.wordbank_FileName):	
			file = FileAccess.open("res://database/"+Global.wordbank_FileName, FileAccess.READ)
		else:
			print("inner:file not exists!")
	elif data_mode == 'local':
		if FileAccess.file_exists(data_local_path+'//'+Global.project_name+"//"+"database"+'//'+Global.wordbank_FileName):	
			file = FileAccess.open(data_local_path+'//'+Global.project_name+"//"+"database"+'//'+Global.wordbank_FileName, FileAccess.READ)
		else:
			print("local:file not exists!")
	else:
		print("config_file['data']['data_mode'] is not valid!!!")
	#if file:
		#print("file_path",file.get_path())	

func _clear_category_item():
	for i in range(len(category_list),-1,-1):
		if category_edit.get_item_text(i) == "全部":
			pass
		else:
			category_edit.remove_item(i)
		
func _add_category_item():
	#print("调试:",Global.keys_layer1_list)
	var data_all :Dictionary
	if file == null:
		pass
	else:
		var content = file.get_as_text()
		print("_add_category_item()path:",file.get_path_absolute())
		#print("_add_category_item()content:",content)
		data_all = JSON.parse_string(content)
		category_list = data_all.keys()
		for i in range(len(category_list)):
			category_edit.add_item(category_list[i])
	#category_edit.item_selected.connect(_change_category_load_data)
	_save_option_list()
#将下拉框选项保存为列表
func _save_option_list():
	Global.category_list = []
	Global.mode_list = []
	Global.Discipline_list = []
	for i in range(category_edit.get_item_count()):
		Global.category_list.append(category_edit.get_item_text(i))
	for i in range(work_mode_edit.get_item_count()):
		Global.mode_list.append(work_mode_edit.get_item_text(i))
	for i in range(Discipline_edit.get_item_count()):
		Global.Discipline_list.append(Discipline_edit.get_item_text(i))
		
func _clear_Discipline_item():
	for i in range(len(Discipline_list),-1,-1):
		if Discipline_edit.get_item_text(i) == "选择一门科目":
			pass
		else:
			Discipline_edit.remove_item(i)
func _add_Discipline_item():#tap
	var per_Discipline_list :Array = []
	var discripline_replace:String
	Discipline_list.clear()
	if data_mode == 'inner':
		per_Discipline_list = DirAccess.get_files_at("res://database")
	elif data_mode == 'local':
		per_Discipline_list = DirAccess.get_files_at(data_local_path+'//'+Global.project_name+'//'+'database')
	for discripline in per_Discipline_list:
		discripline_replace = discripline.replacen(".json","")
		Discipline_list.append(discripline_replace)
	print("data_mode:",data_mode)
	print("data_local_path:",DirAccess.get_files_at(data_local_path+'//'+Global.project_name))
	print("Discipline_list:",Discipline_list)
	for i in range(len(Discipline_list)):
		Discipline_edit.add_item(Discipline_list[i])
	_save_option_list()
func load_data_lib():
	# 读取 JSON 文件
	#var file = FileAccess.open("res://database/wordbank.json", FileAccess.READ)
	var data_all :Dictionary
	if file:
		var content = 'file.get_as_text()'
		content = file.get_as_text()
		#print(content)
		data_all = JSON.parse_string(content)
		Global.data = data_all
		#print(Global.data)
		if category:
			if category != '全部':#获取单个键1，键1→键2
				Global.Read_All = false
				Global.keys_layer1_list = []
				Global.keys_layer1_list.append(category)
				print("调试:",Global.keys_layer1_list)
			else:#建立1层键列表，键1→键2
				Global.Read_All = true
				Global.keys_layer1_list = []
				Global.keys_layer1_list = data_all.keys()#1层键列表
				print("调试:",Global.keys_layer1_list)
		else:
			print("check 'category'!")
		
	else:
		print("无法加载词库文件")

func change_scene()->void:
	if file:
		file.close()
	get_tree().change_scene_to_file("res://Main.tscn")

func _Final_setting()->void:
	#category = category_edit.text
	Global.category = category
	if $BoxContainer/SettingListContainer/WorkModeContainer/OptionButton.text=="顺序":
		Global.mode = "sequence"
	elif $BoxContainer/SettingListContainer/WorkModeContainer/OptionButton.text=="随机":
		Global.mode = "random"
	Global.start_index = start_index_edit.value
	Global.end_index = end_index_edit.value
	Global.question_num = word_num_edit.value
func _restore_global_setting():
	#Global.project_name = ProjectSettings.get_setting("application/config/name")
	Global.keys_layer1_list = []
	Global.keys_layer2_list = []
	Global.category = category_edit.get_item_text(0)
	Global.Read_All = true
	Global.mode = "random"
	Global.start_index = 1
	Global.end_index = 10000
	Global.question_num = 10000
	Global.category_total_num = 0
func _apply_global_setting()->void:
	for i in len(Global.category_list):
		if Global.category == Global.category_list[i]:
			_SelectItem_With_ItemSelectedSignal(category_edit,i)
			#print("Global.category:",Global.category)
			#print("category_edit:",Global.category_list[i])
			break
	for i in len(Global.Discipline_list):
		if Global.Discipline == Global.Discipline_list[i]:
			Discipline_edit.select(i)
			#_SelectItem_With_ItemSelectedSignal(Discipline_edit,i)
			print("Global.Discipline:",Global.Discipline)
			print("Discipline_edit:",Global.Discipline_list[i])
			break
	for i in len(Global.mode_list):
		if Global.mode == "sequence" and Global.mode_list[i] == "顺序":
			_SelectItem_With_ItemSelectedSignal(work_mode_edit,i)
			break
		elif Global.mode == "random" and Global.mode_list[i] == "随机":
			_SelectItem_With_ItemSelectedSignal(work_mode_edit,i)
			break
		else:
			pass
	#print(Global.keys_layer1_list)
	#print(Global.category)
	#print(Global.mode_list)
	start_index_edit.value = Global.start_index
	end_index_edit.value = Global.end_index
	word_num_edit.value = Global.question_num

#解决代码调用select不发射item_selected信号的问题
func _SelectItem_With_ItemSelectedSignal(option_button:OptionButton,index:int)->void:
	option_button.select(index)
	option_button.item_selected.emit(index)
	print("发射",index)
	
#切换学科→全局变量初始化→更新全局变量
#全局变量：学科、目标数据库名称
func _change_Discipline(_index: int) -> void:#切换学科→全局变量初始化→更新当前学科变量，全局变量
	Global.Discipline = Discipline_edit.text
	Global.wordbank_FileName =  Global.Discipline+".json"
	#print("当前文件名：",Global.wordbank_FileName)
	_restore_global_setting()
	_DisciplineSubordinate_UI_setting()
	pass
func _change_category_load_data(_index: int) -> void:
	#print("loaded")
	category = category_edit.text
	load_data_lib()
	#print("Global.keys_layer1_list:",Global.keys_layer1_list)
	Global.category_total_num = _Dictionary_SecondLayerElement_TotalNum(Global.data,Global.keys_layer1_list)
	var question_num :RichTextLabel= $BoxContainer/SettingListContainer/CategorySetting/QuestionNum
	question_num.text = "total：" + str(Global.category_total_num)
#针对每个键都是数组的字典，统计所有数组元素的总数
func _Dictionary_SecondLayerElement_TotalNum(dic:Dictionary,keys:Array)->int:
	var num :int = 0
	#print("keys:",keys)
	for i in range(len(keys)):
		num += len(dic[keys[i]])
	return num

#弹出设置界面
func _configuration_window_popup()->void:
	configuration_window.popup()

	
#测试用
func _emit_test():
	if test_pa <=6:
		_SelectItem_With_ItemSelectedSignal(category_edit,test_pa)
		test_pa += 1
	else:
		test_pa = 0
		_SelectItem_With_ItemSelectedSignal(category_edit,test_pa)
	#print("test_pa:",test_pa)
	category_edit.item_selected.emit(0)
