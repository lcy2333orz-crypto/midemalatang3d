extends Control

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var current_language_label: Label = %CurrentLanguageLabel
@onready var switch_language_button: Button = %SwitchLanguageButton


func _ready() -> void:
	LocalizationManager.language_changed.connect(_on_language_changed)
	switch_language_button.pressed.connect(_on_switch_language_button_pressed)
	_refresh_localized_text()


func _on_switch_language_button_pressed() -> void:
	LocalizationManager.switch_to_next_language()


func _on_language_changed(_language_code: String) -> void:
	_refresh_localized_text()


func _refresh_localized_text() -> void:
	var localized_title: String = LocalizationManager.t("app.title")
	var language_name: String = LocalizationManager.t(
		LocalizationManager.get_current_language_name_key()
	)

	title_label.text = localized_title
	status_label.text = LocalizationManager.t("ui.bootstrap.status")
	current_language_label.text = LocalizationManager.t(
		"ui.language.current",
		{"language": language_name}
	)
	switch_language_button.text = LocalizationManager.t("ui.language.switch")
	DisplayServer.window_set_title(localized_title)

