class_name AppConfig
extends RefCounted

const DEFAULT_LANGUAGE: String = "zh_CN"
const FALLBACK_LANGUAGE: String = "en_US"

const SUPPORTED_LANGUAGES: Array[String] = [
	"zh_CN",
	"en_US",
]

const LOCALIZATION_PATHS: Dictionary = {
	"zh_CN": "res://localization/zh_CN.json",
	"en_US": "res://localization/en_US.json",
}

const LANGUAGE_NAME_KEYS: Dictionary = {
	"zh_CN": "language.zh_CN",
	"en_US": "language.en_US",
}

