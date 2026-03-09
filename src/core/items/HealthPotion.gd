extends ItemData
class_name HealthPotion

func use(target: Node) -> bool:
	if target.has_method("heal"):
		target.heal(health_restore)
		print("Player healed for ", health_restore)
		return true
	return false
