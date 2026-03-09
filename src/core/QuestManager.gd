extends Node

signal quest_status_changed(quest: Quest)
signal objective_updated(quest: Quest)

var active_quests: Dictionary = {} # quest_id -> Quest
var completed_quests: Array = [] # List of quest_ids

func accept_quest(quest: Quest) -> void:
	if quest.quest_id in active_quests or quest.quest_id in completed_quests:
		return
	
	quest.status = Quest.Status.ACTIVE
	active_quests[quest.quest_id] = quest
	quest_status_changed.emit(quest)
	print("[QuestManager] Accepted: ", quest.title)

func track_kill(enemy_name: String) -> void:
	for quest_id in active_quests:
		var q = active_quests[quest_id]
		if q.target_type == "enemy" and q.target_name.to_lower() in enemy_name.to_lower():
			if q.current_amount < q.required_amount:
				q.current_amount += 1
				objective_updated.emit(q)
				print("[QuestManager] Progress: %d/%d for %s" % [q.current_amount, q.required_amount, q.title])
				
				if q.is_finished():
					q.status = Quest.Status.COMPLETED
					quest_status_changed.emit(q)
					print("[QuestManager] Quest COMPLETED: ", q.title)

func complete_quest(quest_id: String, player: Node3D) -> void:
	if quest_id in active_quests:
		var q = active_quests[quest_id]
		if q.status == Quest.Status.COMPLETED:
			# Give Rewards
			var stats = player.get_node_or_null("StatsComponent")
			if stats:
				stats.add_experience(q.reward_exp)
				stats.add_gold(q.reward_gold)
			
			q.status = Quest.Status.REWARDED
			completed_quests.append(quest_id)
			active_quests.erase(quest_id)
			quest_status_changed.emit(q)
			print("[QuestManager] Quest REWARDED: ", q.title)
