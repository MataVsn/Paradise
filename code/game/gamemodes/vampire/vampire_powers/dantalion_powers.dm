/proc/isvampirethrall(mob/living/M)
	return istype(M) && M.mind && SSticker.mode && (M.mind in SSticker.mode.vampire_enthralled)

/obj/effect/proc_holder/spell/targeted/enthrall
	name = "Enthrall (150)"
	desc = "You use a large portion of your power to sway those loyal to none to be loyal to you only."
	gain_desc = "You have gained the ability to thrall people to your will."
	action_icon_state = "vampire_enthrall"
	required_blood = 150
	deduct_blood_on_cast = FALSE
	vampire_ability = TRUE
	humans_only = TRUE
	panel = "Vampire"
	school = "vampire"
	action_background_icon_state = "bg_vampire"

/obj/effect/proc_holder/spell/targeted/enthrall/cast(list/targets, mob/user = usr)
	var/datum/vampire/vampire = user.mind.vampire
	for(var/mob/living/target in targets)
		user.visible_message("<span class='warning'>[user] bites [target]'s neck!</span>", "<span class='warning'>You bite [target]'s neck and begin the flow of power.</span>")
		to_chat(target, "<span class='warning'>You feel the tendrils of evil invade your mind.</span>")
		if(do_mob(user, target, 50))
			if(can_enthrall(user, target))
				handle_enthrall(user, target)
				var/blood_cost_modifier = 1 + vampire.nullified/100
				var/blood_cost = round(required_blood * blood_cost_modifier)
				vampire.bloodusable -= blood_cost //we take the blood after enthralling, not before
			else
				revert_cast(user)
				to_chat(user, "<span class='warning'>You or your target either moved or you dont have enough usable blood.</span>")

/obj/effect/proc_holder/spell/targeted/enthrall/proc/can_enthrall(mob/living/user, mob/living/carbon/C)
	var/enthrall_safe = 0
	for(var/obj/item/implant/mindshield/L in C)
		if(L && L.implanted)
			enthrall_safe = 1
			break
	for(var/obj/item/implant/traitor/T in C)
		if(T && T.implanted)
			enthrall_safe = 1
			break
	if(!C)
		log_runtime(EXCEPTION("something bad happened on enthralling a mob, attacker is [user] [user.key] \ref[user]"), user)
		return FALSE
	if(!C.mind)
		to_chat(user, "<span class='warning'>[C.name]'s mind is not there for you to enthrall.</span>")
		return FALSE
	if(enthrall_safe || (C.mind in SSticker.mode.vampires) || (C.mind.vampire) || (C.mind in SSticker.mode.vampire_enthralled))
		C.visible_message("<span class='warning'>[C] seems to resist the takeover!</span>", "<span class='notice'>You feel a familiar sensation in your skull that quickly dissipates.</span>")
		return FALSE
	if(!C.affects_vampire(user))
		if(C.mind.isholy)
			C.visible_message("<span class='warning'>[C] seems to resist the takeover!</span>", "<span class='notice'>Your faith in [SSticker.Bible_deity_name] has kept your mind clear of all evil.</span>")
		else
			C.visible_message("<span class='warning'>[C] seems to resist the takeover!</span>", "<span class='notice'>You resist the attack on your mind.</span>")
		return FALSE
	if(!ishuman(C))
		to_chat(user, "<span class='warning'>You can only enthrall sentient humanoids!</span>")
		return FALSE
	return TRUE

/obj/effect/proc_holder/spell/targeted/enthrall/proc/handle_enthrall(mob/living/user, mob/living/carbon/human/H)
	if(!istype(H))
		return 0
	var/ref = "\ref[user.mind]"
	if(!(ref in SSticker.mode.vampire_thralls))
		SSticker.mode.vampire_thralls[ref] = list(H.mind)
	else
		SSticker.mode.vampire_thralls[ref] += H.mind
	SSticker.mode.update_vampire_icons_added(H.mind)
	SSticker.mode.update_vampire_icons_added(user.mind)
	var/datum/mindslaves/slaved = user.mind.som
	if(!slaved)
		slaved = new()
		slaved.masters = user.mind
	H.mind.som = slaved
	slaved.serv += H
	slaved.add_serv_hud(user.mind, "vampire")//handles master servent icons
	slaved.add_serv_hud(H.mind, "vampthrall")

	SSticker.mode.vampire_enthralled.Add(H.mind)
	SSticker.mode.vampire_enthralled[H.mind] = user.mind
	H.mind.special_role = SPECIAL_ROLE_VAMPIRE_THRALL

	var/datum/objective/protect/serve_objective = new
	serve_objective.owner = user.mind
	serve_objective.target = H.mind
	serve_objective.explanation_text = "You have been Enthralled by [user.real_name]. Follow [user.p_their()] every command."
	H.mind.objectives += serve_objective

	to_chat(H, "<span class='biggerdanger'>You have been Enthralled by [user.real_name]. Follow [user.p_their()] every command.</span>")
	to_chat(user, "<span class='warning'>You have successfully Enthralled [H]. <i>If [H.p_they()] refuse[H.p_s()] to do as you say just adminhelp.</i></span>")
	H.Stun(2)
	add_attack_logs(user, H, "Vampire-thralled")

/obj/effect/proc_holder/spell/thrall_commune
	name = "Commune"
	desc = ":^ Thrall gang lmao"

/datum/spell_targeting/select_vampire_thralls/choose_targets(mob/user, obj/effect/proc_holder/spell/spell, params, atom/clicked_atom)
	var/list/mob/living/targets = list()
	if(user.mind.vampire)
		for(var/datum/mind/M as anything in user.mind.som.serv)
			if(!M.current) // convert to valid_target
				continue
			targets += M.current
	else
		for(var/datum/mind/M as anything in user.mind.som.masters)
			if(!M.current) // convert to valid_target
				continue
			targets += M.current
			for(var/datum/mind/MI as anything in user.mind.som.serv)
				if(!MI.current) // convert to valid_target
					continue
				if(MI.current == user) // convert to valid_target
					continue
				targets += MI.current
	return targets

/obj/effect/proc_holder/spell/thrall_commune/create_new_targeting()
	var/datum/spell_targeting/select_vampire_thralls/T = new
	T.range = 500
	return T

/obj/effect/proc_holder/spell/thrall_commune/cast(list/targets, mob/user)
	var/input = stripped_input(user, "Please choose a message to tell to the other thralls.", "Thrall Commune", "")
	if(!input)
		return
	var/message = "[user.real_name]:[input]"

	for(var/mob/M in targets)
		to_chat(M, "<span class='shadowling>[message]</span>")
