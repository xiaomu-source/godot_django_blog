extends Node

var api_base := "http://127.0.0.1:8000/api"
var mode := ""
var selected_id: Variant = null
var items := []
var page := 1
var page_size := 10
var total_pages := 1
var total_count := 0
var q := ""
var export_format := ""
var export_article: Dictionary = {}

func _ready():
	var req := $HTTPRequest
	req.request_completed.connect(_on_request_completed)
	$"VBoxContainer/Articles".item_selected.connect(_on_item_selected)
	$"VBoxContainer/Articles".item_activated.connect(_on_item_activated)
	$"VBoxContainer/Buttons/NewBtn".pressed.connect(_on_new_pressed)
	$"VBoxContainer/Buttons/SaveBtn".pressed.connect(_on_save_pressed)
	$"VBoxContainer/Buttons/DeleteBtn".pressed.connect(_on_delete_pressed)
	$"VBoxContainer/Buttons/RefreshBtn".pressed.connect(_on_refresh_pressed)
	$"VBoxContainer/Paging/PrevBtn".pressed.connect(_on_prev_pressed)
	$"VBoxContainer/Paging/NextBtn".pressed.connect(_on_next_pressed)
	var ps := $"VBoxContainer/Paging/PageSize"
	ps.clear()
	ps.add_item("5")
	ps.add_item("10")
	ps.add_item("20")
	ps.add_item("50")
	ps.select(1)
	ps.item_selected.connect(_on_page_size_selected)
	$"VBoxContainer/SearchBox".text_changed.connect(_on_search_changed)
	$"VBoxContainer/Buttons/ExportJSONBtn".pressed.connect(_on_export_json_pressed)
	$"VBoxContainer/Buttons/ExportMDBtn".pressed.connect(_on_export_md_pressed)
	var dlg := $"ExportDialog"
	dlg.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dlg.clear_filters()
	dlg.add_filter("*.json;JSON 文件")
	dlg.add_filter("*.md;Markdown 文件")
	dlg.file_selected.connect(_on_export_file_selected)
	$"DetailPopup/PopupVBox/CloseBtn".pressed.connect(_on_close_popup)
	_refresh()

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var text := body.get_string_from_utf8()
	if response_code >= 200 and response_code < 300:
		if mode == "list":
			var data = JSON.parse_string(text)
			if data is Dictionary:
				var results = data.get("results")
				if results is Array:
					items = results
				var pg = data.get("pagination")
				if pg is Dictionary:
					total_pages = int(pg.get("total_pages"))
					total_count = int(pg.get("total"))
					page = int(pg.get("page"))
				var list := $"VBoxContainer/Articles"
				list.clear()
				for a in items:
					list.add_item(str(a.get("title")))
				_update_page_label()
				$"Label".text = "文章数量: " + str(total_count)
			else:
				$"Label".text = "响应解析失败"
		elif mode == "detail":
			var obj = JSON.parse_string(text)
			if obj is Dictionary:
				$"VBoxContainer/TitleInput".text = str(obj.get("title"))
				$"VBoxContainer/ContentInput".text = str(obj.get("content"))
				$"VBoxContainer/PublishedCheck".button_pressed = bool(obj.get("published"))
				$"Label".text = "已加载: " + str(obj.get("title"))
		elif mode == "detail_popup":
			var obj2 = JSON.parse_string(text)
			if obj2 is Dictionary:
				$"DetailPopup/PopupVBox/DetailTitle".text = str(obj2.get("title"))
				$"DetailPopup/PopupVBox/DetailContent".clear()
				$"DetailPopup/PopupVBox/DetailContent".append_text(str(obj2.get("content")))
				$"DetailPopup".popup_centered()
		elif mode == "export_detail":
			var obj3 = JSON.parse_string(text)
			if obj3 is Dictionary:
				export_article = obj3
				var base := _safe_name(str(obj3.get("slug", obj3.get("title")))) + "_" + str(obj3.get("id"))
				var ext := ".json" if export_format == "json" else ".md"
				var dlg := $"ExportDialog"
				dlg.current_file = base + ext
				dlg.popup_centered()
		elif mode == "create":
			$"Label".text = "已创建"
			_refresh()
		elif mode == "update":
			$"Label".text = "已保存"
			_refresh()
		elif mode == "delete":
			$"Label".text = "已删除"
			selected_id = null
			_clear_form()
			_refresh()
		else:
			$"Label".text = "完成"
	else:
		if result != HTTPRequest.RESULT_SUCCESS:
			$"Label".text = "网络错误: " + str(result)
		else:
			$"Label".text = "失败: " + str(response_code)

func _headers():
	var h := PackedStringArray()
	h.append("Content-Type: application/json")
	return h

func _refresh():
	mode = "list"
	$"Label".text = "加载中..."
	var url := api_base + "/articles/?page=" + str(page) + "&page_size=" + str(page_size)
	if q != "":
		var qq := q.replace(" ", "+")
		url += "&q=" + qq
	$HTTPRequest.request(url)

func _on_refresh_pressed():
	_refresh()

func _on_new_pressed():
	selected_id = null
	_clear_form()
	$"Label".text = "新建模式"

func _on_save_pressed():
	var title: String = $"VBoxContainer/TitleInput".text
	var content: String = $"VBoxContainer/ContentInput".text
	var published: bool = $"VBoxContainer/PublishedCheck".button_pressed
	var payload = {"title": title, "content": content, "published": published}
	var data: String = JSON.stringify(payload)
	if selected_id == null:
		mode = "create"
		$HTTPRequest.request(api_base + "/articles/", _headers(), HTTPClient.METHOD_POST, data)
	else:
		mode = "update"
		$HTTPRequest.request(api_base + "/articles/" + str(selected_id) + "/", _headers(), HTTPClient.METHOD_PUT, data)

func _on_delete_pressed():
	if selected_id == null:
		$"Label".text = "未选择文章"
		return
	mode = "delete"
	$HTTPRequest.request(api_base + "/articles/" + str(selected_id) + "/", _headers(), HTTPClient.METHOD_DELETE)

func _on_item_selected(index: int):
	if index >= 0 and index < items.size():
		var it = items[index]
		selected_id = int(it.get("id"))
		mode = "detail"
		$HTTPRequest.request(api_base + "/articles/" + str(selected_id) + "/")

func _on_item_activated(index: int):
	if index >= 0 and index < items.size():
		var it2 = items[index]
		selected_id = int(it2.get("id"))
		mode = "detail_popup"
		$HTTPRequest.request(api_base + "/articles/" + str(selected_id) + "/")

func _clear_form():
	$"VBoxContainer/TitleInput".text = ""
	$"VBoxContainer/ContentInput".text = ""
	$"VBoxContainer/PublishedCheck".button_pressed = false

func _on_prev_pressed():
	if page > 1:
		page -= 1
		_refresh()

func _on_next_pressed():
	if page < total_pages:
		page += 1
		_refresh()

func _update_page_label():
	$"VBoxContainer/Paging/PageLabel".text = "第 " + str(page) + "/" + str(total_pages) + " 页，总 " + str(total_count) + " 条，每页 " + str(page_size)

func _on_search_changed(s: String):
	q = s
	page = 1
	_refresh()

func _on_close_popup():
	$"DetailPopup".hide()

func _on_page_size_selected(index: int):
	var ps := $"VBoxContainer/Paging/PageSize"
	var text: String = ps.get_item_text(index)
	page_size = int(text)
	page = 1
	_refresh()

func _get_selected_article() -> Dictionary:
	if selected_id == null:
		return {}
	for a in items:
		if int(a.get("id")) == int(selected_id):
			return a
	return {}

func _safe_name(s: String) -> String:
	var t := s.strip_edges()
	t = t.replace(" ", "_")
	if t == "":
		t = "article"
	return t

func _on_export_json_pressed():
	if selected_id == null:
		$"Label".text = "未选择文章"
		return
	export_format = "json"
	mode = "export_detail"
	$HTTPRequest.request(api_base + "/articles/" + str(selected_id) + "/")

func _on_export_md_pressed():
	if selected_id == null:
		$"Label".text = "未选择文章"
		return
	export_format = "md"
	mode = "export_detail"
	$HTTPRequest.request(api_base + "/articles/" + str(selected_id) + "/")

func _on_export_file_selected(path: String):
	var a: Dictionary = export_article
	if a.is_empty():
		$"Label".text = "未加载文章内容"
		return
	var lower := path.to_lower()
	var fmt := export_format
	if lower.ends_with(".json"):
		fmt = "json"
	elif lower.ends_with(".md"):
		fmt = "md"
	if fmt == "json":
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(a))
			f.close()
			$"Label".text = "已导出 JSON: " + path
		else:
			$"Label".text = "导出失败"
	else:
		var title: String = str(a.get("title"))
		var content: String = str(a.get("content"))
		var md: String = "# " + title + "\n\n" + content + "\n"
		var f2 := FileAccess.open(path, FileAccess.WRITE)
		if f2:
			f2.store_string(md)
			f2.close()
			$"Label".text = "已导出 Markdown: " + path
		else:
			$"Label".text = "导出失败"
