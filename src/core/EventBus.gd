extends Node

## Global EventBus for decoupling systems (Solo/Co-op)

# Combat Events
@warning_ignore("unused_signal")
signal damage_triggered(position: Vector3, amount: int, color: Color)
@warning_ignore("unused_signal")
signal heal_triggered(position: Vector3, amount: int)
@warning_ignore("unused_signal")
signal level_up_triggered(position: Vector3, new_level: int)

# World Events
@warning_ignore("unused_signal")
signal quest_updated(quest_id: String, progress: int)
@warning_ignore("unused_signal")
signal item_picked_up(item_name: String)

# System Events
@warning_ignore("unused_signal")
signal save_requested(slot_index: int)
@warning_ignore("unused_signal")
signal load_requested(slot_index: int)
