extends Node

func _ready():
	SgGlobalReferences.set_reference("ServerManagement", self)

func _verify_steam_lobby_password(data) -> void:
	print(data)

func _request_steam_lobby_password(data) -> void:
	print(data)
