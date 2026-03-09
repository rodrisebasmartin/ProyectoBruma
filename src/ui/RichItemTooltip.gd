extends PanelContainer
class_name RichItemTooltip

## RichItemTooltip: Displays detailed item stats and comparisons.

func setup(inst: ItemInstance, equipped: ItemInstance = null) -> void:
	# Use get_node instead of @onready because setup is called right after instantiate()
	var content = get_node("Margin/VBox")
	
	# Clear existing
	for child in content.get_children():
		child.queue_free()
		
	# 1. Header (Name & Rarity)
	var header = RichTextLabel.new()
	header.bbcode_enabled = true
	header.fit_content = true
	header.autowrap_mode = TextServer.AUTOWRAP_OFF
	var color_hex = inst.get_rarity_color().to_html(false)
	header.text = "[center][b][color=#%s]%s[/color][/b]\n[size=12]%s[/size][/center]" % [
		color_hex, 
		inst.get_display_name(), 
		ItemData.Rarity.keys()[inst.rarity]
	]
	content.add_child(header)
	
	# 2. Stats with Comparison
	var stats_label = RichTextLabel.new()
	stats_label.bbcode_enabled = true
	stats_label.fit_content = true
	
	var my_stats = inst.get_total_stats()
	var diff = inst.compare_stats(equipped)
	
	var stats_text = ""
	var stat_map = {
		"damage": "Base Damage",
		"defense": "Base Defense",
		"bonus_dmg": "Bonus Damage",
		"bonus_def": "Bonus Defense",
		"bonus_str": "Strength",
		"hp": "HP Restore"
	}
	
	for key in stat_map.keys():
		var val = my_stats[key]
		var d = diff[key]
		
		if val != 0 or d != 0:
			var d_text = ""
			if d > 0:
				d_text = " [color=green](+%d)[/color]" % d
			elif d < 0:
				d_text = " [color=red](%d)[/color]" % d
				
			stats_text += "%s: %d%s\n" % [stat_map[key], val, d_text]
			
	stats_label.text = stats_text
	content.add_child(stats_label)
	
	# 3. Description
	var desc = Label.new()
	desc.text = inst.base_item.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.modulate = Color(0.7, 0.7, 0.7)
	content.add_child(desc)
