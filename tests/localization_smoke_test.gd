extends SceneTree

const AppConfig := preload("res://scripts/core/app_config.gd")

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_test_catalog_key_parity()

	var manager: Node = root.get_node("LocalizationManager")
	_expect_equal(manager.call("get_current_language"), "zh_CN", "default language")
	_expect_equal(manager.call("t", "app.title"), "小猫麻辣烫", "Chinese title")
	_expect_equal(
		manager.call("t", "ui.language.current", {"language": "简体中文"}),
		"当前语言：简体中文",
		"parameter replacement"
	)

	var packed_ui: PackedScene = load("res://scenes/ui/localization_test_ui.tscn") as PackedScene
	var localization_ui: Control = packed_ui.instantiate() as Control
	root.add_child(localization_ui)
	await process_frame

	_expect_equal(
		localization_ui.get_node("%TitleLabel").get("text"),
		"小猫麻辣烫",
		"initial UI title"
	)
	localization_ui.get_node("%SwitchLanguageButton").emit_signal("pressed")
	await process_frame
	_expect_equal(
		localization_ui.get_node("%TitleLabel").get("text"),
		"Kitty Malatang",
		"switched UI title"
	)
	_expect_equal(
		localization_ui.get_node("%CurrentLanguageLabel").get("text"),
		"Current language: English",
		"switched current language"
	)

	manager.call("set_language", "zh_CN")
	var translations: Dictionary = manager.get("_translations")
	var chinese_catalog: Dictionary = translations["zh_CN"]
	var original_title: String = chinese_catalog["app.title"]
	chinese_catalog.erase("app.title")
	_expect_equal(manager.call("t", "app.title"), "Kitty Malatang", "fallback language")
	chinese_catalog["app.title"] = original_title

	_expect_equal(
		manager.call("t", "ui.test.missing"),
		"[MISSING: ui.test.missing]",
		"missing key marker"
	)
	_expect_equal(manager.call("set_language", "invalid_locale"), false, "invalid language rejected")
	_expect_equal(manager.call("get_current_language"), "zh_CN", "language preserved after rejection")

	localization_ui.queue_free()
	if _failures == 0:
		print("LOCALIZATION_SMOKE_TEST: PASS")
	else:
		printerr("LOCALIZATION_SMOKE_TEST: FAIL (%d failure(s))" % _failures)

	quit(1 if _failures > 0 else 0)


func _test_catalog_key_parity() -> void:
	var catalogs: Dictionary = {}
	for language_code: String in AppConfig.SUPPORTED_LANGUAGES:
		var path: String = AppConfig.LOCALIZATION_PATHS.get(language_code, "") as String
		var load_result: Dictionary = _read_catalog(language_code, path)
		if load_result["ok"]:
			catalogs[language_code] = load_result["catalog"]

	var baseline_language: String = AppConfig.DEFAULT_LANGUAGE
	if not catalogs.has(baseline_language):
		_record_failure(
			"localization catalog key parity | baseline language=%s could not be loaded"
			% baseline_language
		)
		return

	var baseline_catalog: Dictionary = catalogs[baseline_language]
	var baseline_keys: Array[String] = _sorted_catalog_keys(baseline_catalog)
	for language_code: String in AppConfig.SUPPORTED_LANGUAGES:
		if not catalogs.has(language_code):
			continue

		var catalog: Dictionary = catalogs[language_code]
		var missing_keys: Array[String] = []
		var extra_keys: Array[String] = []

		for key: String in baseline_keys:
			if not catalog.has(key):
				missing_keys.append(key)
		for key_value: Variant in catalog.keys():
			var key: String = str(key_value)
			if not baseline_catalog.has(key):
				extra_keys.append(key)

		extra_keys.sort()
		if not missing_keys.is_empty() or not extra_keys.is_empty():
			_record_failure(
				"localization catalog key parity | language=%s missing_keys=%s extra_keys=%s"
				% [language_code, str(missing_keys), str(extra_keys)]
			)


func _read_catalog(language_code: String, path: String) -> Dictionary:
	if path.is_empty():
		_record_failure("localization catalog | language=%s has no configured path" % language_code)
		return {"ok": false, "catalog": {}}
	if not FileAccess.file_exists(path):
		_record_failure("localization catalog | language=%s file not found: %s" % [language_code, path])
		return {"ok": false, "catalog": {}}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_record_failure("localization catalog | language=%s file could not be opened: %s" % [language_code, path])
		return {"ok": false, "catalog": {}}

	var json := JSON.new()
	var parse_result: Error = json.parse(file.get_as_text())
	if parse_result != OK:
		_record_failure(
			"localization catalog | language=%s JSON error at line %d: %s"
			% [language_code, json.get_error_line(), json.get_error_message()]
		)
		return {"ok": false, "catalog": {}}
	if not json.data is Dictionary:
		_record_failure("localization catalog | language=%s root is not an object" % language_code)
		return {"ok": false, "catalog": {}}

	return {"ok": true, "catalog": json.data}


func _sorted_catalog_keys(catalog: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	for key_value: Variant in catalog.keys():
		keys.append(str(key_value))
	keys.sort()
	return keys


func _record_failure(message: String) -> void:
	_failures += 1
	printerr("FAIL: %s" % message)


func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		return

	_failures += 1
	printerr("FAIL: %s | expected=%s actual=%s" % [label, str(expected), str(actual)])
