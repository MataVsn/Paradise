/obj/effect/proc_holder/spell/self/cloak
	name = "Cloak of Darkness"
	desc = "Toggles whether you are currently cloaking yourself in darkness. When in darkness and toggled on, you move at increased speeds."
	gain_desc = "You have gained the Cloak of Darkness ability, which when toggled makes you nearly invisible and highly agile in the shroud of darkness."
	action_icon_state = "vampire_cloak"
	charge_max = 2 SECONDS
	vampire_ability = TRUE
	panel = "Vampire"
	school = "vampire"
	action_background_icon_state = "bg_vampire"

/obj/effect/proc_holder/spell/self/cloak/New()
	..()
	update_name()

/obj/effect/proc_holder/spell/self/cloak/proc/update_name()
	var/mob/living/user = loc
	if(!ishuman(user) || !user.mind || !user.mind.vampire)
		return
	name = "[initial(name)] ([user.mind.vampire.iscloaking ? "Deactivate" : "Activate"])"

/obj/effect/proc_holder/spell/self/cloak/cast(list/targets, mob/user = usr)
	var/datum/vampire/V = user.mind.vampire
	V.iscloaking = !V.iscloaking
	update_name()
	to_chat(user, "<span class='notice'>You will now be [V.iscloaking ? "hidden" : "seen"] in darkness.</span>")

/obj/effect/proc_holder/spell/targeted/click/shadow_snare
	name = "Shadow Snare (20)"
	desc = "You summon a trap on the ground. When crossed it will blind the target, extinguish any lights they may have, and ensnare them."
	gain_desc = "You have gained the ability to summon a trap that will blind, ensnare, and turn off the lights of anyone who crosses it."
	charge_max = 20 SECONDS
	required_blood = 20
	vampire_ability = TRUE
	allowed_type = /turf/simulated
	click_radius = 1
	centcom_cancast = FALSE
	action_icon_state = "dark_passage"
	panel = "Vampire"
	school = "vampire"
	action_background_icon_state = "bg_vampire"
	action_icon_state = "shadow_snare"

/obj/effect/proc_holder/spell/targeted/click/shadow_snare/cast(list/targets, mob/user)
	var/turf/target = targets[1]
	new /obj/item/restraints/legcuffs/beartrap/shadow_snare(target)

/obj/item/restraints/legcuffs/beartrap/shadow_snare
	name = "shadow snare"
	desc = "An almost transparent trap that melts into the shadows."
	alpha = 60
	armed = TRUE
	anchored = TRUE
	breakouttime = 3 SECONDS
	flags = DROPDEL

/obj/item/restraints/legcuffs/beartrap/shadow_snare/Crossed(AM, oldloc)
	if(iscarbon(AM))
		var/mob/living/carbon/C = AM
		if(C.affects_vampire()) // no parameter here so holy always protects
			C.extinguish_light()
			C.EyeBlind(10)
			STOP_PROCESSING(SSobj, src) // won't wither away once you are trapped
			..()

/obj/item/restraints/legcuffs/beartrap/shadow_snare/attack_hand(mob/user)
	Crossed(user)

/obj/item/restraints/legcuffs/beartrap/shadow_snare/process()
	var/turf/T = get_turf(src)
	var/lightingcount = T.get_lumcount(0.5) * 20
	if(lightingcount > 1)
		obj_integrity -= 50

	if(obj_integrity <= 0)
		visible_message("<span class='notice'>The [src] withers away.</span>")
		qdel(src)

/obj/item/restraints/legcuffs/beartrap/shadow_snare/New()
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/restraints/legcuffs/beartrap/shadow_snare/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()
/obj/effect/proc_holder/spell/targeted/click/dark_passage
	name = "Dark Passage (30)"
	desc = "You teleport to a targeted turf."
	gain_desc = "You have gained the ability to blink a short distance towards a targeted turf."
	charge_max = 15 SECONDS
	required_blood = 30
	vampire_ability = TRUE
	allowed_type = /turf/simulated
	click_radius = -1
	panel = "Vampire"
	school = "vampire"
	action_background_icon_state = "bg_vampire"

/obj/effect/proc_holder/spell/targeted/click/dark_passage/cast(list/targets, mob/user)
	var/turf/target = get_turf(targets[1])

	new /obj/effect/temp_visual/vamp_mist_out(get_turf(user))
	new /obj/effect/temp_visual/vamp_mist_in(target)

	user.forceMove(target)

/obj/effect/temp_visual/vamp_mist_out
	duration = 2 SECONDS
	icon = 'icons/mob/mob.dmi'
	icon_state = "mist"

/obj/effect/temp_visual/vamp_mist_in
	duration = 2 SECONDS
	icon = 'icons/mob/mob.dmi'
	icon_state = "mist_reappear"

/obj/effect/proc_holder/spell/aoe_turf/vamp_extinguish
	name = "Extinguish"
	desc = "You extinguish any light source in an area around you."
	gain_desc = "You have gained the ability to extinguish nearby light sources."
	charge_max = 20 SECONDS
	vampire_ability = TRUE
	panel = "Vampire"
	school = "vampire"
	action_background_icon_state = "bg_vampire"
	action_icon_state = "vampire_extinguish"

/obj/effect/proc_holder/spell/aoe_turf/vamp_extinguish/cast(list/targets, mob/user = usr)
	for(var/turf/T in targets)
		T.extinguish_light()
		for(var/atom/A in T.contents)
			A.extinguish_light()

/obj/effect/proc_holder/spell/self/eternal_darkness
	name = "Eternal Darkness"
	desc = "When toggled, you shroud the area around you in darkness and slowly lower the body temperature of people nearby."
	gain_desc = "You have gained the ability to shroud the area around you in darkness, only the strongest of lights can pierce your unholy powers."
	charge_max = 10 SECONDS
	vampire_ability = TRUE
	panel = "Vampire"
	school = "vampire"
	action_background_icon_state = "bg_vampire"
	action_icon_state = "eternal_darkness"
	var/shroud_power = -4

/obj/effect/proc_holder/spell/self/eternal_darkness/cast(list/targets, mob/user)
	var/mob/target = targets[1]
	if(!target.mind.vampire.get_ability(/datum/vampire_passive/eternal_darkness))
		target.mind.vampire.force_add_ability(/datum/vampire_passive/eternal_darkness)
		target.set_light(6, shroud_power, "#AAD84B")
	else
		for(var/datum/vampire_passive/eternal_darkness/E in target.mind.vampire.powers)
			target.mind.vampire.remove_ability(E)

/datum/vampire_passive/eternal_darkness
	gain_desc = "You surround yourself in a unnatural darkness, freezing those around you."

/datum/vampire_passive/eternal_darkness/New()
	..()
	START_PROCESSING(SSobj, src)

/datum/vampire_passive/eternal_darkness/Destroy(force, ...)
	owner.remove_light()
	STOP_PROCESSING(SSobj, src)
	..()

/datum/vampire_passive/eternal_darkness/process()
	for(var/mob/living/L in view(6, owner))
		if(L.affects_vampire(owner))
			L.adjust_bodytemperature(-20 * TEMPERATURE_DAMAGE_COEFFICIENT)

	owner.mind.vampire.bloodusable = max(owner.mind.vampire.bloodusable - 5, 0)

	if(!owner.mind.vampire.bloodusable)
		owner.mind.vampire.remove_ability(src)

/datum/vampire_passive/xray
	gain_desc = "You can now see through walls, incase you hadn't noticed."
