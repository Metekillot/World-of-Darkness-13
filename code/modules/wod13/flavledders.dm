/obj/manholeup
	icon = 'code/modules/wod13/props.dmi'
	icon_state = "ladder"
	name = "ladder"
	plane = GAME_PLANE
	layer = ABOVE_NORMAL_TURF_LAYER
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE

/obj/manholeup/attack_hand(mob/living/user)
	var/turf/destination = get_step_multiz(src, UP)
	if(!isliving(user))
		user.forceMove(destination)
		return ..()
	if(!do_after(user, 50, src))
		to_chat(user, span_notice("You fail to finish climbing up [src]."))
		return
	if(user.pulling)
		user.pulling.forceMove(destination)
	user.forceMove(destination)
	playsound(src, 'code/modules/wod13/sounds/manhole.ogg', 50, TRUE)
	return ..()

/obj/manholedown
	icon = 'code/modules/wod13/props.dmi'
	icon_state = "manhole"
	name = "manhole"
	plane = GAME_PLANE
	layer = ABOVE_NORMAL_TURF_LAYER
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE

/obj/manholedown/Initialize()
	. = ..()
	if(GLOB.winter)
		if(istype(get_area(src), /area/vtm))
			var/area/vtm/V = get_area(src)
			if(V.upper)
				icon_state = "[initial(icon_state)]-snow"

/obj/manholedown/attack_hand(mob/living/user)
	var/move_successful = FALSE
	var/turf/destination = get_step_multiz(src, DOWN)
	if(!isliving(user))
		user.forceMove(destination)
		return ..()
	if(!do_after(user, 50, src))
		to_chat(user, span_notice("You fail to finish climbing down [src]."))
		return ..()
	var/mob/living/carbon/human/npc/grabbed_npc = null
	if(isnpc(user.pulling))
		grabbed_npc = user.pulling
	if(isnull(grabbed_npc) || grabbed_npc.IsUnconscious())
		move_successful = TRUE
		user.pulling.forceMove(destination)
		user.forceMove(destination)
	playsound(src, 'code/modules/wod13/sounds/manhole.ogg', 50, TRUE)
	if(move_successful)
		return ..()
	grabbed_npc.on_kidnap(user)
	var/kidnapper_dice = user.get_total_physique() + user.get_total_athletics()
	var/difficulty_minimum = 7
	var/kidnapping_difficulty
	// The initial part of our calculation will determine the lower of the two
	var/dex_or_athletics = min(grabbed_npc.get_total_dexterity(), grabbed_npc.get_total_athletics())
	// From there, we check what the NPC's base would be for the whole check
	var/npc_base = grabbed_npc.get_total_physique() + dex_or_athletics
	// If the NPC's base is less than the minimum difficulty, we set the minimum difficulty instead
	kidnapping_difficulty = max(npc_base, difficulty_minimum)
	var/is_roll_numerical = FALSE
	var/roll_result = storyteller_roll(
		dice = kidnapper_dice,
		difficulty = kidnapping_difficulty,
		numerical = is_roll_numerical)
	// If the roll is unsuccessful, the NPC aggros and the kidnapper fails to move
	if(roll_result != ROLL_SUCCESS)
		grabbed_npc.Aggro(user, TRUE)
		user.visible_message("<span class='danger'>[grabbed_npc] resists going down with [user].</span>", "<span class='danger'>[grabbed_npc] resists going down, breaking your descent.</span>", null, COMBAT_MESSAGE_RANGE)
		return ..()
	user.pulling.forceMove(destination)
	user.forceMove(destination)
	return ..()


/obj/transfer_point_vamp
	icon = 'code/modules/wod13/props.dmi'
	icon_state = "matrix_go"
	name = "transfer point"
	plane = GAME_PLANE
	layer = ABOVE_NORMAL_TURF_LAYER
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	var/obj/transfer_point_vamp/exit
	var/id = 1

/obj/transfer_point_vamp/Initialize()
	. = ..()
	if(!exit)
		for(var/obj/transfer_point_vamp/T in world)
			if(T.id == id && T != src)
				exit = T
				T.exit = src

/obj/transfer_point_vamp/backrooms
	id = "backrooms"
	alpha = 0

/obj/transfer_point_vamp/backrooms/map
	density = 0

/obj/transfer_point_vamp/umbral
	name = "portal"
	icon = 'code/modules/wod13/48x48.dmi'
	icon_state = "portal"
	plane = ABOVE_LIGHTING_PLANE
	layer = ABOVE_LIGHTING_LAYER
	pixel_w = -8

/obj/transfer_point_vamp/old_clan_tzimisce
	name = "old clan transfer point"
	icon_state = "matrix_go"
	layer = MID_TURF_LAYER

/obj/transfer_point_vamp/umbral/Initialize()
	. = ..()
	set_light(2, 1, "#a4a0fb")

/obj/transfer_point_vamp/umbral/Bumped(atom/movable/AM)
	. = ..()
	playsound(get_turf(AM), 'code/modules/wod13/sounds/portal_enter.ogg', 75, FALSE)

/obj/transfer_point_vamp/Bumped(atom/movable/AM)
	. = ..()
	var/turf/T = get_step(exit, get_dir(AM, src))
//	to_chat(world, "Moving from [x] [y] [z] to [exit.x] [exit.y] [exit.z]")
//	to_chat(world, "Actually [T.x] [T.y] [T.z]")
	AM.forceMove(T)
