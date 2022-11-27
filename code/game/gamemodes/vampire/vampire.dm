
/datum/game_mode
	var/list/datum/mind/vampires = list()
	var/list/datum/mind/vampire_enthralled = list() //those controlled by a vampire
	var/list/vampire_thralls = list() //vampires controlling somebody

/datum/game_mode/vampire
	name = "vampire"
	config_tag = "vampire"
	restricted_jobs = list("AI", "Cyborg")
	protected_jobs = list("Security Officer", "Warden", "Detective", "Head of Security", "Captain", "Blueshield", "Nanotrasen Representative", "Security Pod Pilot", "Magistrate", "Chaplain", "Brig Physician", "Internal Affairs Agent", "Nanotrasen Navy Officer", "Nanotrasen Navy Field Officer", "Special Operations Officer", "Supreme Commander", "Syndicate Officer")
	protected_species = list("Machine")
	required_players = 0
	required_enemies = 1
	recommended_enemies = 4

	///list of minds of soon to be vampires
	var/list/datum/mind/pre_vampires = list()

/datum/game_mode/vampire/announce()
	to_chat(world, "<B>Текущий игровой режим — Вампиры!</B>")
	to_chat(world, "<B>На станции есть блюспейс вампиры. Берегите свои шеи и кровь!</B>")

/datum/game_mode/vampire/pre_setup()

	if(config.protect_roles_from_antagonist)
		restricted_jobs += protected_jobs

	var/list/datum/mind/possible_vampires = get_players_for_role(ROLE_VAMPIRE)

	var/vampire_amount = 1 + round(num_players() / 10)

	if(possible_vampires.len > 0)
		for(var/i in 1 to vampire_amount)
			var/datum/mind/vampire = pick_n_take(possible_vampires)
			pre_vampires += vampire
			vampire.special_role = SPECIAL_ROLE_VAMPIRE
		..()
		return TRUE
	else
		return FALSE

/datum/game_mode/vampire/post_setup()
	for(var/datum/mind/vampire in pre_vampires)
		vampire.add_antag_datum(/datum/antagonist/vampire)
	..()

/datum/game_mode/proc/auto_declare_completion_vampire()
	if(vampires.len)
		var/text = "<FONT size = 2><B>Вампирами были:</B></FONT>"
		for(var/datum/mind/vampire in vampires)
			var/traitorwin = 1
			var/datum/antagonist/vampire/V = vampire.has_antag_datum(/datum/antagonist/vampire)
			text += "<br>[vampire.key] [genderize_ru(vampire.current.gender, "был", "была", "было", "были")] [vampire.name] ("
			if(vampire.current)
				if(vampire.current.stat == DEAD)
					text += "[genderize_ru(vampire.current.gender, "умер", "умерла", "умерло", "умерли")]"
				else
					text += "[genderize_ru(vampire.current.gender, "выжил", "выжила", "выжило", "выжили")]"
					if(V.subclass)
						text += " как [V.subclass.name]"
			else
				text += "тело было уничтожено"
			text += ")"

			if(vampire.objectives.len)//If the traitor had no objectives, don't need to process this.
				var/count = 1
				for(var/datum/objective/objective in vampire.objectives)
					text += "<br><B>Задание №[count]</B>: [objective.explanation_text] "
					if(objective.check_completion())
						text += "<font color='green'><B>Успех!</B></font>"
						SSblackbox.record_feedback("nested tally", "traitor_objective", 1, list("[objective.type]", "SUCCESS"))
					else
						text += "<font color='red'>Провал.</font>"
						SSblackbox.record_feedback("nested tally", "traitor_objective", 1, list("[objective.type]", "FAIL"))
						traitorwin = 0
					count++

			var/special_role_text
			if(vampire.special_role)
				special_role_text = lowertext(vampire.special_role)
			else
				special_role_text = "antagonist"

			if(traitorwin)
				text += "<br><font color='green'><B>The [special_role_text] was successful!</B></font>"
				SSblackbox.record_feedback("tally", "traitor_success", 1, "SUCCESS")
			else
				text += "<br><font color='red'><B>The [special_role_text] has failed!</B></font>"
				SSblackbox.record_feedback("tally", "traitor_success", 1, "FAIL")
		to_chat(world, text)
	return 1

/datum/game_mode/proc/auto_declare_completion_enthralled()
	if(vampire_enthralled.len)
		var/text = "<FONT size = 2><B>Рабами вампиров были:</B></FONT>"
		for(var/datum/mind/mind in vampire_enthralled)
			text += "<br>[mind.key] [genderize_ru(mind.current.gender, "был", "была", "было", "были")] [mind.name] ("
			if(mind.current)
				if(mind.current.stat == DEAD)
					text += "[genderize_ru(mind.current.gender, "умер", "умерла", "умерло", "умерли")]"
				else
					text += "[genderize_ru(mind.current.gender, "выжил", "выжила", "выжило", "выжили")]"
				if(mind.current.real_name != mind.name)
					text += " как [mind.current.real_name]"
			else
				text += "тело было уничтожено"
			text += ")"
		to_chat(world, text)
	return 1

/datum/antagonist/vampire/give_objectives()
	add_objective(/datum/objective/blood)
	add_objective(/datum/objective/assassinate)
	add_objective(/datum/objective/steal)

	switch(rand(1,100))
		if(1 to 80)
			add_objective(/datum/objective/survive)
		else
			add_objective(/datum/objective/escape)

/datum/antagonist/vampire
	name = "Vampire"
	antag_hud_name = "Vampire"
	antag_hud_type = ANTAG_HUD_VAMPIRE
	antag_hud_name = "hudvampire"
	special_role = SPECIAL_ROLE_VAMPIRE
	var/bloodtotal = 0
	var/bloodusable = 0
	// what vampire subclass the vampire is.
	var/datum/vampire_subclass/subclass
	/// handles the vampire cloak toggle
	var/iscloaking = FALSE
	/// list of available powers and passives
	var/list/powers = list()
	/// who the vampire is draining of blood
	var/mob/living/carbon/human/draining
	/// Nullrods and holywater make their abilities cost more
	var/nullified = 0
	/// a list of powers that all vampires unlock and at what blood level they unlock them, the rest of their powers are found in the vampire_subclass datum
	// power lists
	var/list/upgrade_tiers = list(/obj/effect/proc_holder/spell/self/vampire/rejuvenate = 0,
									/obj/effect/proc_holder/spell/mob_aoe/glare = 0,
									/datum/vampire_passive/vision = 100,
									/obj/effect/proc_holder/spell/self/vampire/specialize = 150,
									/datum/vampire_passive/regen = 200,
									/obj/effect/proc_holder/spell/targeted/turf_teleport/shadow_step = 250)
	// list of the peoples UIDs that we have drained, and how much blood from each one
	var/list/drained_humans = list()

/datum/antagonist/mindslave/thrall
	name = "Vampire Thrall"
	antag_hud_type = ANTAG_HUD_VAMPIRE
	antag_hud_name = "vampthrall"


/datum/antagonist/vampire/Destroy(force, ...)
	draining = null
	QDEL_NULL(subclass)
	QDEL_LIST(powers)
	return ..()

/datum/antagonist/vampire/proc/adjust_nullification(base, extra)
	// First hit should give full nullification, while subsequent hits increase the value slower
	nullified = clamp(nullified + extra, base, VAMPIRE_NULLIFICATION_CAP)

/datum/antagonist/vampire/proc/force_add_ability(path)
	var/spell = new path(owner)
	if(istype(spell, /obj/effect/proc_holder/spell))
		owner.AddSpell(spell)
	if(istype(spell, /datum/vampire_passive))
		var/datum/vampire_passive/passive = spell
		passive.owner = owner.current
	powers += spell
	owner.current.update_sight() // Life updates conditionally, so we need to update sight here in case the vamp gets new vision based on his powers. Maybe one day refactor to be more OOP and on the vampire's ability datum.

/datum/antagonist/vampire/proc/get_ability(path)
	for(var/P in powers)
		var/datum/power = P
		if(power.type == path)
			return power
	return null

/datum/antagonist/vampire/proc/add_ability(path)
	if(!get_ability(path))
		force_add_ability(path)

/datum/antagonist/vampire/proc/remove_ability(ability)
	if(ability && (ability in powers))
		powers -= ability
		owner.spell_list.Remove(ability)
		qdel(ability)
		owner.current.update_sight() // Life updates conditionally, so we need to update sight here in case the vamp loses his vision based powers. Maybe one day refactor to be more OOP and on the vampire's ability datum.

/datum/antagonist/vampire/remove_innate_effects(mob/living/old_body)
	var/datum/hud/hud = owner.current.hud_used
	if(hud?.vampire_blood_display)
		hud.remove_vampire_hud()
	owner.current.alpha = 255
	REMOVE_TRAITS_IN(owner.current, "vampire")

#define BLOOD_GAINED_MODIFIER 0.5

/datum/antagonist/vampire/proc/handle_bloodsucking(mob/living/carbon/human/H, suck_rate = 5 SECONDS)
	draining = H
	var/unique_suck_id = H.UID()
	var/blood = 0
	var/blood_limit_exceeded = FALSE
	var/blood_volume_warning = 9999 //Blood volume threshold for warnings

	if(owner.current.is_muzzled())
		to_chat(owner.current, "<span class='warning'>[owner.current.wear_mask] prevents you from biting [H]!</span>")
		draining = null
		return
	add_attack_logs(owner.current, H, "vampirebit & is draining their blood.", ATKLOG_ALMOSTALL)
	owner.current.visible_message("<span class='danger'>[owner] grabs [H]'s neck harshly and sinks in [owner.current.p_their()] fangs!</span>", "<span class='danger'>You sink your fangs into [H] and begin to drain [H.p_their()] blood.</span>", "<span class='notice'>You hear a soft puncture and a wet sucking noise.</span>")
	if(!iscarbon(owner.current))
		H.LAssailant = null
	else
		H.LAssailant = owner
	while(do_mob(owner.current, H, suck_rate))
		if(!(owner in SSticker.mode.vampires))
			to_chat(owner.current, "<span class='userdanger'>Your fangs have disappeared!</span>")
			return
		owner.current.do_attack_animation(H, ATTACK_EFFECT_BITE)
		if(unique_suck_id in drained_humans)
			if(drained_humans[unique_suck_id] >= BLOOD_DRAIN_LIMIT)
				to_chat(owner.current, "<span class='warning'>You have drained most of the life force from [H]'s blood, and you will get no more useable blood from them!</span>")
				H.blood_volume = max(H.blood_volume - 25, 0)
				owner.current.set_nutrition(min(NUTRITION_LEVEL_WELL_FED, owner.current.nutrition + 5))
				continue
		if(H.stat < DEAD)
			if(H.ckey || H.player_ghosted) //Requires ckey regardless if monkey or humanoid, or the body has been ghosted before it died
				blood = min(20, H.blood_volume)
				adjust_blood(H, blood * BLOOD_GAINED_MODIFIER)
				to_chat(owner.current, "<span class='notice'><b>You have accumulated [bloodtotal] unit\s of blood, and have [bloodusable] left to use.</b></span>")
		H.blood_volume = max(H.blood_volume - 25, 0)
		//Blood level warnings (Code 'borrowed' from Fulp)
		if(H.blood_volume)
			if(H.blood_volume <= BLOOD_VOLUME_BAD && blood_volume_warning > BLOOD_VOLUME_BAD)
				to_chat(owner.current, "<span class='danger'>Your victim's blood volume is dangerously low.</span>")
			else if(H.blood_volume <= BLOOD_VOLUME_OKAY && blood_volume_warning > BLOOD_VOLUME_OKAY)
				to_chat(owner.current, "<span class='warning'>Your victim's blood is at an unsafe level.</span>")
			blood_volume_warning = H.blood_volume //Set to blood volume, so that you only get the message once
		else
			to_chat(owner.current, "<span class='warning'>You have bled your victim dry!</span>")
			break
		if(!H.ckey && !H.player_ghosted)//Only runs if there is no ckey and the body has not being ghosted while alive
			to_chat(owner.current, "<span class='notice'><b>Feeding on [H] reduces your thirst, but you get no usable blood from them.</b></span>")
			owner.current.set_nutrition(min(NUTRITION_LEVEL_WELL_FED, owner.current.nutrition + 5))
		else
			owner.current.set_nutrition(min(NUTRITION_LEVEL_WELL_FED, owner.current.nutrition + (blood / 2)))


	draining = null
	to_chat(owner.current, "<span class='notice'>You stop draining [H.name] of blood.</span>")

#undef BLOOD_GAINED_MODIFIER

/datum/antagonist/vampire/proc/check_vampire_upgrade(announce = TRUE)
	var/list/old_powers = powers.Copy()

	for(var/ptype in upgrade_tiers)
		var/level = upgrade_tiers[ptype]
		if(bloodtotal >= level)
			add_ability(ptype)

	if(!subclass)
		return

	subclass.add_subclass_ability(src)

	check_full_power_upgrade()

	if(announce)
		announce_new_power(old_powers)

/datum/antagonist/vampire/proc/check_full_power_upgrade()
	if(length(drained_humans) >= FULLPOWER_DRAINED_REQUIREMENT && bloodtotal >= FULLPOWER_BLOODTOTAL_REQUIREMENT)
		subclass.add_full_power_abilities(src)

/datum/antagonist/vampire/proc/announce_new_power(list/old_powers)
	for(var/p in powers)
		if(!(p in old_powers))
			if(istype(p, /obj/effect/proc_holder/spell))
				var/obj/effect/proc_holder/spell/power = p
				to_chat(owner.current, "<span class='boldnotice'>[power.gain_desc]</span>")
			else if(istype(p, /datum/vampire_passive))
				var/datum/vampire_passive/power = p
				to_chat(owner.current, "<span class='boldnotice'>[power.gain_desc]</span>")

/datum/antagonist/vampire/on_removal()
	if(owner in SSticker.mode.vampires)
		SSticker.mode.vampires -= owner
		owner.current.create_log(CONVERSION_LOG, "De-vampired")
	..()

/datum/antagonist/vampire/on_gain()
	if(!(owner in SSticker.mode.vampires))
		SSticker.mode.vampires += owner
	..()

/datum/antagonist/vampire/proc/check_sun()
	var/ax = owner.current.x
	var/ay = owner.current.y

	for(var/i = 1 to 20)
		ax += SSsun.dx
		ay += SSsun.dy

		var/turf/T = locate(round(ax, 0.5), round(ay, 0.5), owner.current.z)

		if(!T)
			return

		if(T.x == 1 || T.x == world.maxx || T.y == 1 || T.y == world.maxy)
			break

		if(T.density)
			return
	if(bloodusable >= 10)	//burn through your blood to tank the light for a little while
		to_chat(owner.current, "<span class='warning'>The starlight saps your strength!</span>")
		bloodusable -= 10
		vamp_burn(10)
	else		//You're in trouble, get out of the sun NOW
		to_chat(owner.current, "<span class='userdanger'>Your body is turning to ash, get out of the light now!</span>")
		owner.current.adjustCloneLoss(10)	//I'm melting!
		vamp_burn(85)
		if(owner.current.cloneloss >= 100)
			owner.current.dust()

/datum/antagonist/vampire/proc/handle_vampire()
	if(owner.current.hud_used)
		var/datum/hud/hud = owner.current.hud_used
		if(!hud.vampire_blood_display)
			hud.vampire_blood_display = new /obj/screen()
			hud.vampire_blood_display.name = "Доступная кровь"
			hud.vampire_blood_display.icon_state = "blood_display"
			hud.vampire_blood_display.screen_loc = "WEST:6,CENTER-1:15"
			hud.static_inventory += hud.vampire_blood_display
			hud.show_hud(hud.hud_version)
		hud.vampire_blood_display.maptext = "<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='#ce0202'>[bloodusable]</font></div>"
	handle_vampire_cloak()
	if(istype(get_turf(owner.current), /turf/space))
		check_sun()
	if(istype(get_area(owner.current), /area/chapel) && !get_ability(/datum/vampire_passive/full))
		vamp_burn(7)
	nullified = max(0, nullified - 2)

/datum/antagonist/vampire/proc/handle_vampire_cloak()
	if(!ishuman(owner.current))
		owner.current.alpha = 255
		return
	var/turf/simulated/T = get_turf(owner.current)
	var/light_available = T.get_lumcount() * 10

	if(!istype(T))
		return

	if(!iscloaking || owner.current.on_fire)
		owner.current.alpha = 255
		owner.current.status_flags &= ~GOTTAGONOTSOFAST
		return

	if(light_available <= 2)
		owner.current.alpha = 38 // round(255 * 0.15)
		owner.current.status_flags |= GOTTAGONOTSOFAST
		return

	owner.current.status_flags &= ~GOTTAGONOTSOFAST
	owner.current.alpha = 204 // 255 * 0.80

/datum/antagonist/vampire/proc/adjust_blood(mob/living/carbon/C, blood_amount = 0)
	if(C)
		var/unique_suck_id = C.UID()
		if(!(unique_suck_id in drained_humans))
			drained_humans[unique_suck_id] = 0
		if(drained_humans[unique_suck_id] >= BLOOD_DRAIN_LIMIT)
			return
		drained_humans[unique_suck_id] += blood_amount
	bloodtotal += blood_amount
	bloodusable += blood_amount
	check_vampire_upgrade(TRUE)
	for(var/obj/effect/proc_holder/spell/S in powers)
		if(S.action)
			S.action.UpdateButtonIcon()

/datum/antagonist/vampire/proc/vamp_burn(burn_chance)
	if(prob(burn_chance) && owner.current.health >= 50)
		switch(owner.current.health)
			if(75 to 100)
				to_chat(owner.current, "<span class='warning'>Your skin flakes away...</span>")
			if(50 to 75)
				to_chat(owner.current, "<span class='warning'>Your skin sizzles!</span>")
		owner.current.adjustFireLoss(3)
	else if(owner.current.health < 50)
		if(!owner.current.on_fire)
			to_chat(owner.current, "<span class='danger'>Your skin catches fire!</span>")
			owner.current.emote("scream")
		else
			to_chat(owner.current, "<span class='danger'>You continue to burn!</span>")
		owner.current.adjust_fire_stacks(5)
		owner.current.IgniteMob()
	return

/datum/antagonist/vampire/vv_edit_var(var_name, var_value)
	. = ..()
	check_vampire_upgrade(TRUE)

/datum/antagonist/vampire/greet()
	var/dat
	SEND_SOUND(owner.current, sound('sound/ambience/antag/vampalert.ogg'))
	dat = "<span class='danger'>You are a Vampire!</span><br>"
	dat += {"To bite someone, target the head and use harm intent with an empty hand. Drink blood to gain new powers.
		You are weak to holy things, starlight and fire. Don't go into space and avoid the Chaplain, the chapel and especially Holy Water."}
	to_chat(owner.current, dat)

/datum/antagonist/vampire/apply_innate_effects(mob/living/new_body)
	. = ..()
	var/datum/mindslaves/slaved = new()
	slaved.masters += owner
	owner.som = slaved //we MIGHT want to mindslave someone

	check_vampire_upgrade(FALSE)

/datum/hud/proc/remove_vampire_hud()
	static_inventory -= vampire_blood_display
	QDEL_NULL(vampire_blood_display)
	show_hud()
