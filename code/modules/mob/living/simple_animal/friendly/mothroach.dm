/mob/living/simple_animal/mothroach
	name = "mothroach"
	real_name = "mothroach"
	desc = "This is the adorable by-product of multiple attempts at genetically mixing mothpeople with cockroaches."
	icon_state = "mothroach"
	icon_living = "mothroach"
	icon_dead = "mothroach_dead"
	icon_resting = "mothroach_rest"
	speak = list("bzzz!","BZZZZ!", "Bz?")
	speak_emote = list("flutters inquisitively","flutters loudly","flutters")
	emote_hear = list("flutters")
	emote_see = list("runs in a circle", "shakes")
	var/moth_sound = 'sound/voice/scream_moth.ogg'
	tts_seed = "Gyro"
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	maxHealth = 25
	health = 25
	butcher_results = list(/obj/item/reagent_containers/food/snacks/monstermeat/mothroach = 2, /obj/item/stack/sheet/animalhide/mothroach = 1)
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "stamps on"
	density = 0
	ventcrawler = 2
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mob_size = MOB_SIZE_TINY
	layer = MOB_LAYER
	minbodytemp = 223		//Below -50 Degrees Celcius
	maxbodytemp = 323	//Above 50 Degrees Celcius
	universal_speak = 0
	speak_chance = 1
	can_hide = 1
	holder_type = /obj/item/holder/mothroach
	can_collar = 1
	gold_core_spawnable = FRIENDLY_SPAWN
	var/chew_probability = 1

/mob/living/simple_animal/mothroach/handle_automated_movement()
	if(prob(chew_probability) && isturf(loc))
		var/turf/simulated/floor/F = get_turf(src)
		if(istype(F) && !F.intact)
			var/obj/item/clothing/C = locate() in F
			if(C && prob(25))
				visible_message("<span class='warning'>[src] chews the [C].</span>")

/mob/living/simple_animal/mothroach/handle_automated_speech()
	..()
	if(prob(speak_chance) && !incapacitated())
		playsound(src, moth_sound, 100, 1)

/mob/living/simple_animal/mothroach/handle_automated_movement()
	. = ..()
	if(src.stat == DEAD)
		return
	if(resting)
		if(prob(1))
			StopResting()
		else if(prob(5))
			custom_emote(2, "snuffles")
	else if(prob(0.5))
		StartResting()

/mob/living/simple_animal/mothroach/attack_hand(mob/living/carbon/human/M as mob)
	if(M.a_intent == INTENT_HELP)
		get_scooped(M)
	..()

/mob/living/simple_animal/mothroach/start_pulling(atom/movable/AM, state, force = pull_force, show_message = FALSE)//Prevents mouse from pulling things
	if(istype(AM, /obj/item/clothing))
		return ..() 
	if(show_message)
		to_chat(src, "<span class='warning'>You are too small to pull anything except clothing.</span>")
	return

/mob/living/simple_animal/mothroach/attackby(obj/item/attacking_item, mob/living/user, params)
	. = ..()
	if(src.stat == DEAD)
		return
	else
		playsound(loc, moth_sound, 50, TRUE)

