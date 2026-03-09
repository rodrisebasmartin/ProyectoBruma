extends Resource
class_name Quest

enum Status { AVAILABLE, ACTIVE, COMPLETED, REWARDED }

@export var quest_id: String
@export var title: String
@export_multiline var description: String

@export_group("Objectives")
@export var target_type: String = "enemy" # "enemy" or "item"
@export var target_name: String = "Wolf"
@export var required_amount: int = 5
var current_amount: int = 0

@export_group("Rewards")
@export var reward_exp: int = 100
@export var reward_gold: int = 50

var status: Status = Status.AVAILABLE

func is_finished() -> bool:
	return current_amount >= required_amount
