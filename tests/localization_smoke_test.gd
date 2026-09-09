extends SceneTree

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame

	var manager: Node = root.get_node("LocalizationManager")
	_expect_equal(manager.call("get_current_language"), "zh_CN", "default language")
	_expect_equal(manager.call("t", "app.title"), "小猫麻辣烫", "Chinese title")
	_expect_equal(
		manager.call("t", "ui.language.current", {"language": "简体中文"}),
		"当前语言：简体中文",
		"parameter replacement"
	)

	var packed_main: PackedScene = load("res://scenes/core/main.tscn") as PackedScene
	var main: Control = packed_main.instantiate() as Control
	root.add_child(main)
	await process_frame

	_expect_equal(main.get_node("%TitleLabel").get("text"), "小猫麻辣烫", "initial UI title")
	main.get_node("%SwitchLanguageButton").emit_signal("pressed")
	await process_frame
	_expect_equal(main.get_node("%TitleLabel").get("text"), "Kitty Malatang", "switched UI title")
	_expect_equal(
		main.get_node("%CurrentLanguageLabel").get("text"),
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

	main.queue_free()
	if _failures == 0:
		print("LOCALIZATION_SMOKE_TEST: PASS")
	else:
		printerr("LOCALIZATION_SMOKE_TEST: FAIL (%d failure(s))" % _failures)

	quit(1 if _failures > 0 else 0)


func _expect_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		return

	_failures += 1
	printerr("FAIL: %s | expected=%s actual=%s" % [label, str(expected), str(actual)])

