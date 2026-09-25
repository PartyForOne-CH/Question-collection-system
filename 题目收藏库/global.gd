extends Node
var project_name = ProjectSettings.get_setting("application/config/name")
var Discipline :String = "选择一门科目"
var Discipline_list :Array = []#存放科目名称

var wordbank_FileName :String
var keys_layer1_list: Array = []
var keys_layer2_list: Array = []
var Read_All :bool = true
var data:Dictionary
var category :String = "全部"
var category_list :Array = []#存放章节名称
var mode:String = "random"
var mode_list :Array = []#存放工作模式名称
var start_index :int =1
var end_index :int = 10000
var question_num :int = 10000
var category_total_num:int = 0
