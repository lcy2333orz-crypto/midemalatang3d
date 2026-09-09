extends Node

signal language_changed(language_code: String)

const AppConfigData := preload("res://scripts/core/app_config.gd")

var _translations: Dictionary = {}
var _current_language: String = AppConfigData.DEFAULT_LANGUAGE


func _ready() -> void:
	_load_all_translations()


func t(key: String, parameters: Dictionary = {}) -> String:
	var localized_text: String

	if _has_translation(_current_language, key):
		localized_text = _get_translation(_current_language, key)
	elif _has_translation(AppConfigData.FALLBACK_LANGUAGE, key):
		push_warning(
			"Localization key '%s' is missing for '%s'; using fallback '%s'."
			% [key, _current_language, AppConfigData.FALLBACK_LANGUAGE]
		)
		localized_text = _get_translation(AppConfigData.FALLBACK_LANGUAGE, key)
	else:
		push_warning(
			"Localization key '%s' is missing for both '%s' and fallback '%s'."
			% [key, _current_language, AppConfigData.FALLBACK_LANGUAGE]
		)
		return "[MISSING: %s]" % key

	return _replace_parameters(localized_text, parameters)


func set_language(language_code: String) -> bool:
	if not AppConfigData.SUPPORTED_LANGUAGES.has(language_code):
		push_warning("Unsupported language code: '%s'." % language_code)
		return false

	if language_code == _current_language:
		return true

	_current_language = language_code
	language_changed.emit(_current_language)
	return true


func get_current_language() -> String:
	return _current_language


func get_current_language_name_key() -> String:
	return AppConfigData.LANGUAGE_NAME_KEYS.get(_current_language, "") as String


func switch_to_next_language() -> void:
	var current_index: int = AppConfigData.SUPPORTED_LANGUAGES.find(_current_language)
	var next_index: int = (current_index + 1) % AppConfigData.SUPPORTED_LANGUAGES.size()
	set_language(AppConfigData.SUPPORTED_LANGUAGES[next_index])


func _load_all_translations() -> void:
	_translations.clear()

	for language_code: String in AppConfigData.SUPPORTED_LANGUAGES:
		var path: String = AppConfigData.LOCALIZATION_PATHS.get(language_code, "") as String
		_load_translation_file(language_code, path)


func _load_translation_file(language_code: String, path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		push_warning("Localization file not found for '%s': %s" % [language_code, path])
		return

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Localization file could not be opened for '%s': %s" % [language_code, path])
		return

	var json := JSON.new()
	var parse_result: Error = json.parse(file.get_as_text())
	if parse_result != OK:
		push_warning(
			"Localization JSON error for '%s' at line %d: %s"
			% [language_code, json.get_error_line(), json.get_error_message()]
		)
		return

	if not json.data is Dictionary:
		push_warning("Localization root must be an object for '%s'." % language_code)
		return

	var source_catalog: Dictionary = json.data
	var catalog: Dictionary = {}
	for key_value: Variant in source_catalog.keys():
		var key: String = str(key_value)
		var value: Variant = source_catalog[key_value]
		if not value is String:
			push_warning("Localization value for '%s' in '%s' must be a string." % [key, language_code])
			continue
		catalog[key] = value

	_translations[language_code] = catalog


func _has_translation(language_code: String, key: String) -> bool:
	if not _translations.has(language_code):
		return false

	var catalog: Dictionary = _translations[language_code]
	return catalog.has(key)


func _get_translation(language_code: String, key: String) -> String:
	var catalog: Dictionary = _translations[language_code]
	return catalog[key] as String


func _replace_parameters(localized_text: String, parameters: Dictionary) -> String:
	var result: String = localized_text
	for parameter_name: Variant in parameters.keys():
		result = result.replace("{%s}" % str(parameter_name), str(parameters[parameter_name]))
	return result

