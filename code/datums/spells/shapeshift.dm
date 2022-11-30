/obj/effect/proc_holder/spell/shapeshift
	name = "Shapechange"
	desc = "Take on the shape of another for a time to use their natural abilities. Once you've made your choice it cannot be changed."
	clothes_req = 0
	human_req = 0
	charge_max = 200
	cooldown_min = 50
	invocation = "RAC'WA NO!"
	invocation_type = "shout"
	action_icon_state = "shapeshift"

	var/shapeshift_type
	var/list/current_shapes = list()
	var/list/current_casters = list()
	var/list/possible_shapes = list(/mob/living/simple_animal/mouse,
		/mob/living/simple_animal/pet/dog/corgi,
		/mob/living/simple_animal/hostile/construct/armoured)

/obj/effect/proc_holder/spell/shapeshift/create_new_targeting()
	var/datum/spell_targeting/self/S = new()
	return S

/obj/effect/proc_holder/spell/shapeshift/cast(list/targets, mob/user = usr)	if(isliving(user))
		var/mob/living/target = user
		if(target.weakened || target.stunned)
			return FALSE
	if(!isturf(user.loc) && !length(current_casters)) //Can't use inside of things, such as a mecha
		return FALSE
	. = ..()

/obj/effect/proc_holder/spell/targeted/shapeshift/cast(list/targets, mob/user = usr)
	for(var/mob/living/M in targets)
		if(!shapeshift_type)
			var/list/animal_list = list()
			for(var/path in possible_shapes)
				var/mob/living/simple_animal/A = path
				animal_list[initial(A.name)] = path
			shapeshift_type = input(M, "Choose Your Animal Form!", "It's Morphing Time!", null) as anything in animal_list
			if(!shapeshift_type) //If you aren't gonna decide I am!
				shapeshift_type = pick(animal_list)
			shapeshift_type = animal_list[shapeshift_type]
		if(M in current_shapes)
			Restore(M)
		else
			Shapeshift(M)

/obj/effect/proc_holder/spell/shapeshift/proc/Shapeshift(mob/living/caster)
	if(do_after(caster, 2 SECONDS, target = caster))
		for(var/mob/living/M in caster)
			if(M.status_flags & GODMODE)
				to_chat(caster, "<span class='warning'>You're already shapeshifted!</span>")
				return

		var/mob/living/shape = new shapeshift_type(caster.loc)
		caster.loc = shape
		caster.status_flags |= GODMODE

		current_shapes |= shape
		current_casters |= caster
		clothes_req = 0
		human_req = 0

		caster.mind.transfer_to(shape)
	else
		to_chat(caster, "<span class='warning'>You were interrupted!</span>")
		charge_counter = charge_max

/obj/effect/proc_holder/spell/shapeshift/proc/Restore(mob/living/shape)
	var/mob/living/caster
	for(var/mob/living/M in shape)
		if(M in current_casters)
			caster = M
			break
	if(!caster)
		return
	caster.loc = shape.loc
	caster.status_flags &= ~GODMODE

	clothes_req = initial(clothes_req)
	human_req = initial(human_req)
	current_casters.Remove(caster)
	current_shapes.Remove(shape)

	shape.mind.transfer_to(caster)
	qdel(shape) //Gib it maybe ?

/obj/effect/proc_holder/spell/shapeshift/dragon
	name = "Dragon Form"
	desc = "Take on the shape a lesser ash drake."
	invocation = "RAAAAAAAAWR!"

	shapeshift_type = /mob/living/simple_animal/hostile/megafauna/dragon/lesser
	current_shapes = list(/mob/living/simple_animal/hostile/megafauna/dragon/lesser)
	current_casters = list()
	possible_shapes = list(/mob/living/simple_animal/hostile/megafauna/dragon/lesser)

/obj/effect/proc_holder/spell/shapeshift/bats
	name = "Bat Form"
	desc = "Take on the shape of a swarm of bats."
	invocation = "none"
	invocation_type = "none"
	action_icon_state = "vampire_bats"
	gain_desc = "You have gained the ability to shapeshift into bat form. This is a weak form with no abilities, only useful for stealth."

	shapeshift_type = /mob/living/simple_animal/hostile/scarybat/batswarm
	current_shapes = list(/mob/living/simple_animal/hostile/scarybat/batswarm)
	current_casters = list()
	possible_shapes = list(/mob/living/simple_animal/hostile/scarybat/batswarm)

/obj/effect/proc_holder/spell/shapeshift/hellhound
	name = "Lesser Hellhound Form"
	desc = "Take on the shape of a Hellhound."
	invocation = "none"
	invocation_type = "none"
	action_background_icon_state = "bg_demon"
	action_icon_state = "glare"
	gain_desc = "You have gained the ability to shapeshift into lesser hellhound form. This is a combat form with different abilities, tough but not invincible. It can regenerate itself over time by resting."


	shapeshift_type = /mob/living/simple_animal/hostile/hellhound
	current_shapes = list(/mob/living/simple_animal/hostile/hellhound)
	current_casters = list()
	possible_shapes = list(/mob/living/simple_animal/hostile/hellhound)

/obj/effect/proc_holder/spell/shapeshift/hellhound/greater
	name = "Greater Hellhound Form"
	shapeshift_type = /mob/living/simple_animal/hostile/hellhound/greater
	current_shapes = list(/mob/living/simple_animal/hostile/hellhound/greater)
	current_casters = list()
	possible_shapes = list(/mob/living/simple_animal/hostile/hellhound/greater)
