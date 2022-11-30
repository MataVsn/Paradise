/obj/effect/proc_holder/spell/infinite_guns
	name = "Lesser Summon Guns"
	desc = "Why reload when you have infinite guns? Summons an unending stream of bolt action rifles. Requires both hands free to use."
	invocation_type = "none"

	school = "conjuration"
	charge_max = 600
	clothes_req = 1
	cooldown_min = 10 //Gun wizard
	action_icon_state = "bolt_action"

/obj/effect/proc_holder/spell/infinite_guns/create_new_targeting()
	var/datum/spell_targeting/self/S = new()
	return S

/obj/effect/proc_holder/spell/infinite_guns/cast(list/targets, mob/user = usr)	for(var/mob/living/carbon/C in targets)
		C.drop_item()
		C.swap_hand()
		C.drop_item()
		var/obj/item/gun/projectile/shotgun/boltaction/enchanted/GUN = new
		C.put_in_hands(GUN)
