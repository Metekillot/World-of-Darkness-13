
/**
 * This is the splat (supernatural type, game line in the World of Darkness) container
 * for all vampire-related code. I think this is stupid and I don't want any of this to
 * be the way it is, but if we're going to work with the code that's been written then
 * my advice is to centralise all stuff directly relating to vampires to here if it isn't
 * already in another organisational structure.
 *
 * The same applies to other splats, like /datum/splat/supernatural/garou or /datum/splat/supernatural/ghoul.
 * Halfsplats like ghouls are going to share some code with their fullsplats (vampires).
 * I dunno what to do about this except a reorganisation to make this stuff actually good.
 * The plan right now is to create a /datum/splat parent type and then have everything branch
 * from there, but that's for the future.
 */

/datum/splat/supernatural/kindred
	name = "Vampire"
	splat_traits = list(
		TRAIT_VIRUSIMMUNE,	//PSEUDO_M_K kindred can spread disease, amend this
		TRAIT_NOBLEED,		//PSEUDO_M_K we need to account for losing vitae to massive damage
		TRAIT_NOHUNGER,
		TRAIT_NOBREATH,
		TRAIT_TOXIMMUNE,
		TRAIT_NOCRITDAMAGE,
	)
	brutemod = 0.5	//PSEUDO_M_K account for dam resist
	burnmod = 2	//PSEUDO_M_K this needs to be much higher considering fire does aggravated

	power_stat_name = "Vitae"
	power_stat_max = 5 //PSEUDO_MX this was moved here from mob/living
	power_stat_current = 5
	integrity_name = "Humanity"
	integrity_level = 7

	var/generation = 13
	COOLDOWN_DECLARE(torpor_timer)

	var/bloodpower_time_plus = 0					//PSEUDO_M_SR
	var/thaum_damage_plus = 0						//
	var/discipline_time_plus = 0					//
	var/dust_anim = "dust-h"						//
	var/datum/vampireclane/clane					//
	var/list/datum/discipline/disciplines = list()	//
	var/last_bloodheal_use = 0						//
	var/last_bloodpower_use = 0						//
	var/last_drinkblood_use = 0						//
	var/last_bloodheal_click = 0					//
	var/last_bloodpower_click = 0					//
	var/last_drinkblood_click = 0					//
	var/masquerade = 5								//
	var/last_masquerade_violation = 0				//

/datum/action/vampireinfo
	name = "About Me"
	desc = "Check assigned role, clan, generation, humanity, masquerade, known disciplines, known contacts etc."
	button_icon_state = "masquerade"
	check_flags = NONE
	var/mob/living/carbon/human/host

/datum/action/vampireinfo/Trigger()
	if(host)
		var/dat = {"
			<style type="text/css">

			body {
				background-color: #090909; color: white;
			}

			</style>
			"}
		dat += "<center><h2>Memories</h2><BR></center>"
		dat += "[icon2html(getFlatIcon(host), host)]I am "
		if(host.real_name)
			dat += "[host.real_name],"
		if(!host.real_name)
			dat += "Unknown,"
		if(host.clane)
			dat += " the [host.clane.name]"
		if(!host.clane)
			dat += " the caitiff"

		if(host.mind)

			if(host.mind.assigned_role)
				if(host.mind.special_role)
					dat += ", carrying the [host.mind.assigned_role] (<font color=red>[host.mind.special_role]</font>) role."
				else
					dat += ", carrying the [host.mind.assigned_role] role."
			if(!host.mind.assigned_role)
				dat += "."
			dat += "<BR>"
			if(host.mind.enslaved_to)
				dat += "My Regnant is [host.mind.enslaved_to], I should obey their wants.<BR>"
		if(host.vampire_faction == "Camarilla" || host.vampire_faction == "Anarchs" || host.vampire_faction == "Sabbat")
			dat += "I belong to [host.vampire_faction] faction, I shouldn't disobey their rules.<BR>"
		if(host.generation)
			dat += "I'm from [host.generation] generation.<BR>"
		if(host.mind.special_role)
			for(var/datum/antagonist/A in host.mind.antag_datums)
				if(A.objectives)
					dat += "[printobjectives(A.objectives)]<BR>"
		var/masquerade_level = " followed the Masquerade Tradition perfectly."
		switch(host.masquerade)
			if(4)
				masquerade_level = " broke the Masquerade rule once."
			if(3)
				masquerade_level = " made a couple of Masquerade breaches."
			if(2)
				masquerade_level = " provoked a moderate Masquerade breach."
			if(1)
				masquerade_level = " almost ruined the Masquerade."
			if(0)
				masquerade_level = "'m danger to the Masquerade and my own kind."
		dat += "Camarilla thinks I[masquerade_level]<BR>"
		var/humanity = "I'm out of my mind."
		var/enlight = FALSE
		if(host.clane)
			if(host.clane.enlightenment)
				enlight = TRUE

		if(!enlight)
			switch(host.humanity)
				if(8 to 10)
					humanity = "I'm saintly."
				if(7)
					humanity = "I feel as human as when I lived."
				if(5 to 6)
					humanity = "I'm feeling distant from my humanity."
				if(4)
					humanity = "I don't feel any compassion for the Kine anymore."
				if(2 to 3)
					humanity = "I feel hunger for <b>BLOOD</b>. My humanity is slipping away."
				if(1)
					humanity = "Blood. Feed. Hunger. It gnaws. Must <b>FEED!</b>"

		else
			switch(host.humanity)
				if(8 to 10)
					humanity = "I'm <b>ENLIGHTENED</b>, my <b>BEAST</b> and I are in complete harmony."
				if(7)
					humanity = "I've made great strides in co-existing with my beast."
				if(5 to 6)
					humanity = "I'm starting to learn how to share this unlife with my beast."
				if(4)
					humanity = "I'm still new to my path, but I'm learning."
				if(2 to 3)
					humanity = "I'm a complete novice to my path."
				if(1)
					humanity = "I'm losing control over my beast!"

		dat += "[humanity]<BR>"

		if(host.clane.name == "Brujah")
			if(GLOB.brujahname != "")
				if(host.real_name != GLOB.brujahname)
					dat += " My primogen is:  [GLOB.brujahname].<BR>"
		if(host.clane.name == "Malkavian")
			if(GLOB.malkavianname != "")
				if(host.real_name != GLOB.malkavianname)
					dat += " My primogen is:  [GLOB.malkavianname].<BR>"
		if(host.clane.name == "Nosferatu")
			if(GLOB.nosferatuname != "")
				if(host.real_name != GLOB.nosferatuname)
					dat += " My primogen is:  [GLOB.nosferatuname].<BR>"
		if(host.clane.name == "Toreador")
			if(GLOB.toreadorname != "")
				if(host.real_name != GLOB.toreadorname)
					dat += " My primogen is:  [GLOB.toreadorname].<BR>"
		if(host.clane.name == "Ventrue")
			if(GLOB.ventruename != "")
				if(host.real_name != GLOB.ventruename)
					dat += " My primogen is:  [GLOB.ventruename].<BR>"

		dat += "<b>Physique</b>: [host.physique] + [host.additional_physique]<BR>"
		dat += "<b>Dexterity</b>: [host.dexterity] + [host.additional_dexterity]<BR>"
		dat += "<b>Social</b>: [host.social] + [host.additional_social]<BR>"
		dat += "<b>Mentality</b>: [host.mentality] + [host.additional_mentality]<BR>"
		dat += "<b>Cruelty</b>: [host.blood] + [host.additional_blood]<BR>"
		dat += "<b>Lockpicking</b>: [host.lockpicking] + [host.additional_lockpicking]<BR>"
		dat += "<b>Athletics</b>: [host.athletics] + [host.additional_athletics]<BR>"
		if(host.hud_used)
			dat += "<b>Known disciplines:</b><BR>"
			for(var/datum/action/discipline/D in host.actions)
				if(D)
					if(D.discipline)
						dat += "[D.discipline.name] [D.discipline.level] - [D.discipline.desc]<BR>"
		if(host.Myself)
			if(host.Myself.Friend)
				if(host.Myself.Friend.owner)
					dat += "<b>My friend's name is [host.Myself.Friend.owner.true_real_name].</b><BR>"
					if(host.Myself.Friend.phone_number)
						dat += "Their number is [host.Myself.Friend.phone_number].<BR>"
					if(host.Myself.Friend.friend_text)
						dat += "[host.Myself.Friend.friend_text]<BR>"
			if(host.Myself.Enemy)
				if(host.Myself.Enemy.owner)
					dat += "<b>My nemesis is [host.Myself.Enemy.owner.true_real_name]!</b><BR>"
					if(host.Myself.Enemy.enemy_text)
						dat += "[host.Myself.Enemy.enemy_text]<BR>"
			if(host.Myself.Lover)
				if(host.Myself.Lover.owner)
					dat += "<b>I'm in love with [host.Myself.Lover.owner.true_real_name].</b><BR>"
					if(host.Myself.Lover.phone_number)
						dat += "Their number is [host.Myself.Lover.phone_number].<BR>"
					if(host.Myself.Lover.lover_text)
						dat += "[host.Myself.Lover.lover_text]<BR>"
		var/obj/keypad/armory/K = find_keypad(/obj/keypad/armory)
		if(K && (host.mind.assigned_role == "Prince" || host.mind.assigned_role == "Sheriff"))
			dat += "<b>The pincode for the armory keypad is: [K.pincode]</b><BR>"
		var/obj/structure/vaultdoor/pincode/bank/bankdoor = find_door_pin(/obj/structure/vaultdoor/pincode/bank)
		if(bankdoor && (host.mind.assigned_role == "Capo"))
			dat += "<b>The pincode for the bank vault is: [bankdoor.pincode]</b><BR>"
		if(bankdoor && (host.mind.assigned_role == "La Squadra"))
			if(prob(50))
				dat += "<b>The pincode for the bank vault is: [bankdoor.pincode]</b><BR>"
			else
				dat += "<b>Unfortunately you don't know the vault code.</b><BR>"

		if(length(host.knowscontacts) > 0)
			dat += "<b>I know some other of my kind in this city. Need to check my phone, there definetely should be:</b><BR>"
			for(var/i in host.knowscontacts)
				dat += "-[i] contact<BR>"
		for(var/datum/vtm_bank_account/account in GLOB.bank_account_list)
			if(host.bank_id == account.bank_id)
				dat += "<b>My bank account code is: [account.code]</b><BR>"
		host << browse(dat, "window=vampire;size=400x450;border=1;can_resize=1;can_minimize=0")
		onclose(host, "vampire", src)

/datum/splat/supernatural/kindred/on_splat_gain(mob/living/carbon/human/C)
	. = ..()
	C.update_body(0)
	C.last_experience = world.time + 5 MINUTES
	var/datum/action/vampireinfo/infor = new()
	infor.host = C
	infor.Grant(C)
	var/datum/action/give_vitae/vitae = new()
	vitae.Grant(C)
	var/datum/action/blood_heal/bloodheal = new()
	bloodheal.Grant(C)
	var/datum/action/blood_power/bloodpower = new()
	bloodpower.Grant(C)
	add_verb(C, /mob/living/carbon/human/verb/teach_discipline)

	//vampires go to -200 damage before dying
	for (var/obj/item/bodypart/bodypart in C.bodyparts)
		bodypart.max_damage *= 1.5

	//vampires die instantly upon having their heart removed
	RegisterSignal(C, COMSIG_CARBON_LOSE_ORGAN, PROC_REF(lose_organ))

	//vampires don't die while in crit, they just slip into torpor after 2 minutes of being critted
	RegisterSignal(C, SIGNAL_ADDTRAIT(TRAIT_CRITICAL_CONDITION), PROC_REF(slip_into_torpor))

/datum/splat/supernatural/kindred/on_splat_loss(mob/living/carbon/human/C, datum/splat/new_splat, pref_load)
	. = ..()
	for(var/datum/action/vampireinfo/VI in C.actions)
		if(VI)
			VI.Remove(C)
	for(var/datum/action/A in C.actions)
		if(A)
			if(A.vampiric)
				A.Remove(C)

/datum/action/blood_power
	name = "Blood Power"
	desc = "Use vitae to gain supernatural abilities."
	button_icon_state = "bloodpower"
	button_icon = 'code/modules/wod13/UI/actions.dmi'
	background_icon_state = "discipline"
	icon_icon = 'code/modules/wod13/UI/actions.dmi'
	check_flags = AB_CHECK_HANDS_BLOCKED|AB_CHECK_IMMOBILE|AB_CHECK_LYING|AB_CHECK_CONSCIOUS
	vampiric = TRUE

/datum/action/blood_power/ApplyIcon(atom/movable/screen/movable/action_button/current_button, force = FALSE)
	if(owner)
		if(owner.client)
			if(owner.client.prefs)
				if(owner.client.prefs.old_discipline)
					button_icon = 'code/modules/wod13/disciplines.dmi'
					icon_icon = 'code/modules/wod13/disciplines.dmi'
				else
					button_icon = 'code/modules/wod13/UI/actions.dmi'
					icon_icon = 'code/modules/wod13/UI/actions.dmi'
	. = ..()

/datum/action/blood_power/Trigger()
	if(istype(owner, /mob/living/carbon/human))
		if (HAS_TRAIT(owner, TRAIT_TORPOR))
			return
		var/mob/living/carbon/human/BD = usr
		if(world.time < BD.last_bloodpower_use+110)
			return
		var/plus = 0
		if(HAS_TRAIT(BD, TRAIT_HUNGRY))
			plus = 1
		if(BD.bloodpool >= 2+plus)
			playsound(usr, 'code/modules/wod13/sounds/bloodhealing.ogg', 50, FALSE)
			button.color = "#970000"
			animate(button, color = "#ffffff", time = 20, loop = 1)
			BD.last_bloodpower_use = world.time
			BD.bloodpool = max(0, BD.bloodpool-(2+plus))
			to_chat(BD, "<span class='notice'>You use blood to become more powerful.</span>")
			BD.physiology.armor.melee = BD.physiology.armor.melee+15
			BD.physiology.armor.bullet = BD.physiology.armor.bullet+15
			BD.dexterity = BD.dexterity+2
			BD.athletics = BD.athletics+2
			BD.update_blood_hud()
			addtimer(100+BD.discipline_time_plus+BD.bloodpower_time_plus)
				end_bloodpower()
		else
			SEND_SOUND(BD, sound('code/modules/wod13/sounds/need_blood.ogg', 0, 0, 75))
			to_chat(BD, "<span class='warning'>You don't have enough <b>BLOOD</b> to become more powerful.</span>")

/datum/action/blood_power/proc/end_bloodpower()
	if(owner && ishuman(owner))
		var/mob/living/carbon/human/BD = owner
		to_chat(BD, "<span class='warning'>You feel like your <b>BLOOD</b>-powers slowly decrease.</span>")
		if(BD.dna.species)
			BD.dna.species.punchdamagehigh = BD.dna.species.punchdamagehigh-5
			BD.physiology.armor.melee = BD.physiology.armor.melee-15
			BD.physiology.armor.bullet = BD.physiology.armor.bullet-15
			if(HAS_TRAIT(BD, TRAIT_IGNORESLOWDOWN))
				REMOVE_TRAIT(BD, TRAIT_IGNORESLOWDOWN, SPECIES_TRAIT)
		BD.dexterity = BD.dexterity-2
		BD.athletics = BD.athletics-2
		BD.lockpicking = BD.lockpicking-2

/datum/action/give_vitae
	name = "Give Vitae"
	desc = "Give your vitae to someone, make the Blood Bond."
	button_icon_state = "vitae"
	check_flags = AB_CHECK_HANDS_BLOCKED|AB_CHECK_IMMOBILE|AB_CHECK_LYING|AB_CHECK_CONSCIOUS
	vampiric = TRUE
	var/giving = FALSE

/datum/action/give_vitae/Trigger()
	if(istype(owner, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = owner
		if(H.bloodpool < 2)
			to_chat(owner, "<span class='warning'>You don't have enough <b>BLOOD</b> to do that!</span>")
			return
		if(istype(H.pulling, /mob/living/simple_animal))
			var/mob/living/L = H.pulling
			L.bloodpool = min(L.maxbloodpool, L.bloodpool+2)
			H.bloodpool = max(0, H.bloodpool-2)
			L.adjustBruteLoss(-25)
			L.adjustFireLoss(-25)
		if(istype(H.pulling, /mob/living/carbon/human))
			var/mob/living/carbon/human/BLOODBONDED = H.pulling
			if(!BLOODBONDED.client && !istype(H.pulling, /mob/living/carbon/human/npc))
				to_chat(owner, "<span class='warning'>You need [BLOODBONDED]'s attention to do that!</span>")
				return
			if(BLOODBONDED.stat == DEAD)
				if(!BLOODBONDED.key)
					to_chat(owner, "<span class='warning'>You need [BLOODBONDED]'s mind to Embrace!</span>")
					return
				message_admins("[ADMIN_LOOKUPFLW(H)] is Embracing [ADMIN_LOOKUPFLW(BLOODBONDED)]!")
			if(giving)
				return
			giving = TRUE
			owner.visible_message("<span class='warning'>[owner] tries to feed [BLOODBONDED] with their own blood!</span>", "<span class='notice'>You started to feed [BLOODBONDED] with your own blood.</span>")
			if(do_mob(owner, BLOODBONDED, 10 SECONDS))
				H.bloodpool = max(0, H.bloodpool-2)
				giving = FALSE

				var/new_master = FALSE
				BLOODBONDED.faction |= H.faction
				if(!istype(BLOODBONDED, /mob/living/carbon/human/npc))
					if(H.vampire_faction == "Camarilla" || H.vampire_faction == "Anarchs" || H.vampire_faction == "Sabbat")
						if(BLOODBONDED.vampire_faction != H.vampire_faction)
							BLOODBONDED.vampire_faction = H.vampire_faction
							if(H.vampire_faction == "Sabbat")
								if(BLOODBONDED.mind)
									BLOODBONDED.mind.add_antag_datum(/datum/antagonist/sabbatist)
									GLOB.sabbatites += BLOODBONDED
							SSfactionwar.adjust_members()
							to_chat(BLOODBONDED, "<span class='notice'>You are now member of <b>[H.vampire_faction]</b></span>")
				BLOODBONDED.drunked_of |= "[H.dna.real_name]"

				if(BLOODBONDED.stat == DEAD && !is_kindred(BLOODBONDED))
					if (!BLOODBONDED.can_be_embraced)
						to_chat(H, "<span class='notice'>[BLOODBONDED.name] doesn't respond to your Vitae.</span>")
						return

					if((BLOODBONDED.timeofdeath + 5 MINUTES) > world.time)
						if (BLOODBONDED.auspice?.level) //here be Abominations
							if (BLOODBONDED.auspice.force_abomination)
								to_chat(H, "<span class='danger'>Something terrible is happening.</span>")
								to_chat(BLOODBONDED, "<span class='userdanger'>Gaia has forsaken you.</span>")
								message_admins("[ADMIN_LOOKUPFLW(H)] has turned [ADMIN_LOOKUPFLW(BLOODBONDED)] into an Abomination through an admin setting the force_abomination var.")
								log_game("[key_name(H)] has turned [key_name(BLOODBONDED)] into an Abomination through an admin setting the force_abomination var.")
							else
								switch(storyteller_roll(BLOODBONDED.auspice.level))
									if (ROLL_BOTCH)
										to_chat(H, "<span class='danger'>Something terrible is happening.</span>")
										to_chat(BLOODBONDED, "<span class='userdanger'>Gaia has forsaken you.</span>")
										message_admins("[ADMIN_LOOKUPFLW(H)] has turned [ADMIN_LOOKUPFLW(BLOODBONDED)] into an Abomination.")
										log_game("[key_name(H)] has turned [key_name(BLOODBONDED)] into an Abomination.")
									if (ROLL_FAILURE)
										BLOODBONDED.visible_message("<span class='warning'>[BLOODBONDED.name] convulses in sheer agony!</span>")
										BLOODBONDED.Shake(15, 15, 5 SECONDS)
										playsound(BLOODBONDED.loc, 'code/modules/wod13/sounds/vicissitude.ogg', 100, TRUE)
										BLOODBONDED.can_be_embraced = FALSE
										return
									if (ROLL_SUCCESS)
										to_chat(H, "<span class='notice'>[BLOODBONDED.name] does not respond to your Vitae...</span>")
										BLOODBONDED.can_be_embraced = FALSE
										return

						log_game("[key_name(H)] has Embraced [key_name(BLOODBONDED)].")
						message_admins("[ADMIN_LOOKUPFLW(H)] has Embraced [ADMIN_LOOKUPFLW(BLOODBONDED)].")
						giving = FALSE
						var/save_data_v = FALSE
						if(BLOODBONDED.revive(full_heal = TRUE, admin_revive = TRUE))
							BLOODBONDED.grab_ghost(force = TRUE)
							to_chat(BLOODBONDED, "<span class='userdanger'>You rise with a start, you're alive! Or not... You feel your soul going somewhere, as you realize you are embraced by a vampire...</span>")
							var/response_v = input(BLOODBONDED, "Do you wish to keep being a vampire on your save slot?(Yes will be a permanent choice and you can't go back!)") in list("Yes", "No")
							if(response_v == "Yes")
								save_data_v = TRUE
							else
								save_data_v = FALSE
						BLOODBONDED.roundstart_vampire = FALSE
						BLOODBONDED.set_species(/datum/splat/supernatural/kindred)
						BLOODBONDED.clane = null
						if(H.generation < 13)
							BLOODBONDED.generation = 13
							BLOODBONDED.skin_tone = get_vamp_skin_color(BLOODBONDED.skin_tone)
							BLOODBONDED.update_body()
							if (H.clane.whitelisted)
								if (!SSwhitelists.is_whitelisted(BLOODBONDED.ckey, H.clane.name))
									if(H.clane.name == "True Brujah")
										BLOODBONDED.clane = new /datum/vampireclane/brujah()
										to_chat(BLOODBONDED,"<span class='warning'> You don't got that whitelist! Changing to the non WL Brujah</span>")
									else if(H.clane.name == "Tzimisce")
										BLOODBONDED.clane = new /datum/vampireclane/old_clan_tzimisce()
										to_chat(BLOODBONDED,"<span class='warning'> You don't got that whitelist! Changing to the non WL Old Tzmisce</span>")
									else
										to_chat(BLOODBONDED,"<span class='warning'> You don't got that whitelist! Changing to a random non WL clan.</span>")
										var/list/non_whitelisted_clans = list(/datum/vampireclane/brujah,/datum/vampireclane/malkavian,/datum/vampireclane/nosferatu,/datum/vampireclane/gangrel,/datum/vampireclane/giovanni,/datum/vampireclane/ministry,/datum/vampireclane/salubri,/datum/vampireclane/toreador,/datum/vampireclane/tremere,/datum/vampireclane/ventrue)
										var/random_clan = pick(non_whitelisted_clans)
										BLOODBONDED.clane = new random_clan
								else
									BLOODBONDED.clane = new H.clane.type()
							else
								BLOODBONDED.clane = new H.clane.type()

							BLOODBONDED.clane.on_gain(BLOODBONDED)
							BLOODBONDED.clane.post_gain(BLOODBONDED)
							if(BLOODBONDED.clane.alt_sprite)
								BLOODBONDED.skin_tone = "albino"
								BLOODBONDED.update_body()

							//Gives the Childe the Sire's first three Disciplines

							var/list/disciplines_to_give = list()
							for (var/i in 1 to min(3, H.client.prefs.discipline_types.len))
								disciplines_to_give += H.client.prefs.discipline_types[i]
							BLOODBONDED.create_disciplines(FALSE, disciplines_to_give)

							BLOODBONDED.maxbloodpool = 10+((13-min(13, BLOODBONDED.generation))*3)
							BLOODBONDED.clane.enlightenment = H.clane.enlightenment
						else
							BLOODBONDED.maxbloodpool = 10+((13-min(13, BLOODBONDED.generation))*3)
							BLOODBONDED.generation = 14
							BLOODBONDED.clane = new /datum/vampireclane/caitiff()

						//Verify if they accepted to save being a vampire
						if (is_kindred(BLOODBONDED) && save_data_v)
							var/datum/preferences/BLOODBONDED_prefs_v = BLOODBONDED.client.prefs

							BLOODBONDED_prefs_v.pref_species.id = "kindred"
							BLOODBONDED_prefs_v.pref_species.name = "Vampire"
							if(H.generation < 13)

								BLOODBONDED_prefs_v.clane = BLOODBONDED.clane
								BLOODBONDED_prefs_v.generation = 13
								BLOODBONDED_prefs_v.skin_tone = get_vamp_skin_color(BLOODBONDED.skin_tone)
								BLOODBONDED_prefs_v.clane.enlightenment = H.clane.enlightenment


								//Rarely the new mid round vampires get the 3 brujah skil(it is default)
								//This will remove if it happens
								// Or if they are a ghoul with abunch of disciplines
								if(BLOODBONDED_prefs_v.discipline_types.len > 0)
									for (var/i in 1 to BLOODBONDED_prefs_v.discipline_types.len)
										var/removing_discipline = BLOODBONDED_prefs_v.discipline_types[1]
										if (removing_discipline)
											var/index = BLOODBONDED_prefs_v.discipline_types.Find(removing_discipline)
											BLOODBONDED_prefs_v.discipline_types.Cut(index, index + 1)
											BLOODBONDED_prefs_v.discipline_levels.Cut(index, index + 1)

								if(BLOODBONDED_prefs_v.discipline_types.len == 0)
									for (var/i in 1 to 3)
										BLOODBONDED_prefs_v.discipline_types += BLOODBONDED_prefs_v.clane.clane_disciplines[i]
										BLOODBONDED_prefs_v.discipline_levels += 1
								BLOODBONDED_prefs_v.save_character()

							else
								BLOODBONDED_prefs_v.generation = 13 // Game always set to 13 anyways, 14 is not possible.
								BLOODBONDED_prefs_v.clane = new /datum/vampireclane/caitiff()
								BLOODBONDED_prefs_v.save_character()

					else

						to_chat(owner, "<span class='notice'>[BLOODBONDED] is totally <b>DEAD</b>!</span>")
						giving = FALSE
						return
				else
					if(BLOODBONDED.has_status_effect(STATUS_EFFECT_INLOVE))
						BLOODBONDED.remove_status_effect(STATUS_EFFECT_INLOVE)
					BLOODBONDED.apply_status_effect(STATUS_EFFECT_INLOVE, owner)
					to_chat(owner, "<span class='notice'>You successfuly fed [BLOODBONDED] with vitae.</span>")
					to_chat(BLOODBONDED, "<span class='userlove'>You feel good when you drink this <b>BLOOD</b>...</span>")

					message_admins("[ADMIN_LOOKUPFLW(H)] has bloodbonded [ADMIN_LOOKUPFLW(BLOODBONDED)].")
					log_game("[key_name(H)] has bloodbonded [key_name(BLOODBONDED)].")

					if(H.reagents)
						if(length(H.reagents.reagent_list))
							H.reagents.trans_to(BLOODBONDED, min(10, H.reagents.total_volume), transfered_by = H, methods = VAMPIRE)
					BLOODBONDED.adjustBruteLoss(-25, TRUE)
					if(length(BLOODBONDED.all_wounds))
						var/datum/wound/W = pick(BLOODBONDED.all_wounds)
						W.remove_wound()
					BLOODBONDED.adjustFireLoss(-25, TRUE)
					BLOODBONDED.bloodpool = min(BLOODBONDED.maxbloodpool, BLOODBONDED.bloodpool+2)
					giving = FALSE

					if (is_kindred(BLOODBONDED))
						var/datum/splat/supernatural/kindred/splat = BLOODBONDED.dna.species
						if (HAS_TRAIT(BLOODBONDED, TRAIT_TORPOR) && COOLDOWN_FINISHED(species, torpor_timer))
							BLOODBONDED.untorpor()

					if(!is_ghoul(H.pulling) && istype(H.pulling, /mob/living/carbon/human/npc))
						var/mob/living/carbon/human/npc/NPC = H.pulling
						if(NPC.ghoulificate(owner))
							new_master = TRUE
//							if(NPC.hud_used)
//								var/datum/hud/human/HU = NPC.hud_used
//								HU.create_ghoulic()
							NPC.roundstart_vampire = FALSE
					if(BLOODBONDED.mind)
						if(BLOODBONDED.mind.enslaved_to != owner)
							BLOODBONDED.mind.enslave_mind_to_creator(owner)
							to_chat(BLOODBONDED, "<span class='userdanger'><b>AS PRECIOUS VITAE ENTER YOUR MOUTH, YOU NOW ARE IN THE BLOODBOND OF [H]. SERVE YOUR REGNANT CORRECTLY, OR YOUR ACTIONS WILL NOT BE TOLERATED.</b></span>")
							new_master = TRUE
					if(is_ghoul(BLOODBONDED))
						var/datum/splat/supernatural/ghoul/G = BLOODBONDED.dna.species
						G.master = owner
						G.last_vitae = world.time
						if(new_master)
							G.changed_master = TRUE
					else if(!is_kindred(BLOODBONDED) && !isnpc(BLOODBONDED))
						var/save_data_g = FALSE
						BLOODBONDED.set_species(/datum/splat/supernatural/ghoul)
						BLOODBONDED.clane = null
						var/response_g = input(BLOODBONDED, "Do you wish to keep being a ghoul on your save slot?(Yes will be a permanent choice and you can't go back)") in list("Yes", "No")
//						if(BLOODBONDED.hud_used)
//							var/datum/hud/human/HU = BLOODBONDED.hud_used
//							HU.create_ghoulic()
						BLOODBONDED.roundstart_vampire = FALSE
						var/datum/splat/supernatural/ghoul/G = BLOODBONDED.dna.species
						G.master = owner
						G.last_vitae = world.time
						if(new_master)
							G.changed_master = TRUE
						if(response_g == "Yes")
							save_data_g = TRUE
						else
							save_data_g = FALSE
						if(save_data_g)
							var/datum/preferences/BLOODBONDED_prefs_g = BLOODBONDED.client.prefs
							if(BLOODBONDED_prefs_g.discipline_types.len == 3)
								for (var/i in 1 to 3)
									var/removing_discipline = BLOODBONDED_prefs_g.discipline_types[1]
									if (removing_discipline)
										var/index = BLOODBONDED_prefs_g.discipline_types.Find(removing_discipline)
										BLOODBONDED_prefs_g.discipline_types.Cut(index, index + 1)
										BLOODBONDED_prefs_g.discipline_levels.Cut(index, index + 1)
							BLOODBONDED_prefs_g.pref_species.name = "Ghoul"
							BLOODBONDED_prefs_g.pref_species.id = "ghoul"
							BLOODBONDED_prefs_g.save_character()
			else
				giving = FALSE

/**
 * Initialises Disciplines for new vampire mobs, applying effects and creating action buttons.
 *
 * If discipline_pref is true, it grabs all of the source's Disciplines from their preferences
 * and applies those using the give_discipline() proc. If false, it instead grabs a given list
 * of Discipline typepaths and initialises those for the character. Only works for ghouls and
 * vampires, and it also applies the Clan's post_gain() effects
 *
 * Arguments:
 * * discipline_pref - Whether Disciplines will be taken from preferences. True by default.
 * * disciplines - list of Discipline typepaths to grant if discipline_pref is false.
 */
/mob/living/carbon/human/proc/create_disciplines(discipline_pref = TRUE, list/disciplines)	//EMBRACE BASIC
	if(client)
		client.prefs.slotlocked = TRUE
		client.prefs.save_preferences()
		client.prefs.save_character()

	if((dna.species.id == "kindred") || (dna.species.id == "ghoul")) //only splats that have Disciplines qualify
		var/list/datum/discipline/adding_disciplines = list()

		if (discipline_pref) //initialise character's own disciplines
			for (var/i in 1 to client.prefs.discipline_types.len)
				var/type_to_create = client.prefs.discipline_types[i]
				var/datum/discipline/discipline = new type_to_create

				//prevent Disciplines from being used if not whitelisted for them
				if (discipline.clane_restricted)
					if (!can_access_discipline(src, type_to_create))
						qdel(discipline)
						continue

				discipline.level = client.prefs.discipline_levels[i]
				adding_disciplines += discipline
		else if (disciplines.len) //initialise given disciplines
			for (var/i in 1 to disciplines.len)
				var/type_to_create = disciplines[i]
				var/datum/discipline/discipline = new type_to_create
				adding_disciplines += discipline

		for (var/datum/discipline/discipline in adding_disciplines)
			give_discipline(discipline)

		if(clane)
			clane.post_gain(src)

/**
 * Creates an action button and applies post_gain effects of the given Discipline.
 *
 * Arguments:
 * * discipline - Discipline datum that is being given to this mob.
 */
/mob/living/carbon/human/proc/give_discipline(datum/discipline/discipline)
	if (discipline.level > 0)
		var/datum/action/discipline/action = new
		action.discipline = discipline
		action.Grant(src)
	discipline.post_gain(src)
	var/datum/splat/supernatural/kindred/splat = dna.species
	species.disciplines += discipline

/**
 * Accesses a certain Discipline that a Kindred has. Returns false if they don't.
 *
 * Arguments:
 * * searched_discipline - Name or typepath of the Discipline being searched for.
 */
/datum/splat/supernatural/kindred/proc/get_discipline(searched_discipline)
	for(var/datum/discipline/discipline in disciplines)
		if (ispath(searched_discipline, /datum/discipline))
			if (istype(discipline, searched_discipline))
				return discipline
		else if (istext(searched_discipline))
			if (discipline.name == searched_discipline)
				return discipline

	return FALSE

/datum/splat/supernatural/kindred/check_roundstart_eligible()
	return TRUE

/datum/splat/supernatural/kindred/handle_body(mob/living/carbon/human/H)
	if (!H.clane)
		return ..()

	//deflate people if they're super rotten
	if ((H.clane.alt_sprite == "rotten4") && (H.base_body_mod == "f"))
		H.base_body_mod = ""

	if(H.clane.alt_sprite)
		H.dna.species.limbs_id = "[H.base_body_mod][H.clane.alt_sprite]"

	if (H.clane.no_hair)
		H.hairstyle = "Bald"

	if (H.clane.no_facial)
		H.facial_hairstyle = "Shaved"

	..()


/**
 * Signal handler for lose_organ to near-instantly kill Kindred whose hearts have been removed.
 *
 * Arguments:
 * * source - The Kindred whose organ has been removed.
 * * organ - The organ which has been removed.
 */
/datum/splat/supernatural/kindred/proc/lose_organ(var/mob/living/carbon/human/source, var/obj/item/organ/organ)
	SIGNAL_HANDLER

	if (istype(organ, /obj/item/organ/heart))
		spawn()
			if (!source.getorganslot(ORGAN_SLOT_HEART))
				source.death()

/datum/splat/supernatural/kindred/proc/slip_into_torpor(var/mob/living/carbon/human/source)
	SIGNAL_HANDLER

	to_chat(source, "<span class='warning'>You can feel yourself slipping into Torpor. You can use succumb to immediately sleep...</span>")
	spawn(2 MINUTES)
		if (source.stat >= SOFT_CRIT)
			source.torpor("damage")

/**
 * Verb to teach your Disciplines to vampires who have drank your blood by spending 10 experience points.
 *
 * Disciplines can be taught to any willing vampires who have drank your blood in the last round and do
 * not already have that Discipline. True Brujah learning Celerity or Old Clan Tzimisce learning Vicissitude
 * get kicked out of their bloodline and made into normal Brujah and Tzimisce respectively. Disciplines
 * are taught at the 0th level, unlocking them but not actually giving the Discipline to the student.
 * Teaching Disciplines takes 10 experience points, then the student can buy the 1st rank for another 10.
 * The teacher must have the Discipline at the 5th level to teach it to others.
 *
 * Arguments:
 * * student - human who this Discipline is being taught to.
 */
/mob/living/carbon/human/verb/teach_discipline(mob/living/carbon/human/student in (range(1, src) - src))
	set name = "Teach Discipline"
	set category = "IC"
	set desc ="Teach a Discipline to a Kindred who has recently drank your blood. Costs 10 experience points."

	var/mob/living/carbon/human/teacher = src
	var/datum/preferences/teacher_prefs = teacher.client.prefs
	var/datum/splat/supernatural/kindred/teacher_species = teacher.dna.species

	if (!student.client)
		to_chat(teacher, "<span class='warning'>Your student needs to be a player!</span>")
		return
	var/datum/preferences/student_prefs = student.client.prefs

	if (!is_kindred(student))
		to_chat(teacher, "<span class='warning'>Your student needs to be a vampire!</span>")
		return
	if (student.stat >= SOFT_CRIT)
		to_chat(teacher, "<span class='warning'>Your student needs to be conscious!</span>")
		return
	if (teacher_prefs.true_experience < 10)
		to_chat(teacher, "<span class='warning'>You don't have enough experience to teach them this Discipline!</span>")
		return
	//checks that the teacher has blood bonded the student, this is something that needs to be reworked when blood bonds are made better
	if (student.mind.enslaved_to != teacher)
		to_chat(teacher, "<span class='warning'>You need to have fed your student your blood to teach them Disciplines!</span>")
		return

	var/possible_disciplines = teacher_prefs.discipline_types - student_prefs.discipline_types
	var/teaching_discipline = input(teacher, "What Discipline do you want to teach [student.name]?", "Discipline Selection") as null|anything in possible_disciplines

	if (teaching_discipline)
		var/datum/discipline/teacher_discipline = teacher_species.get_discipline(teaching_discipline)
		var/datum/discipline/giving_discipline = new teaching_discipline

		//if a Discipline is clan-restricted, it must be checked if the student has access to at least one Clan with that Discipline
		if (giving_discipline.clane_restricted)
			if (!can_access_discipline(student, teaching_discipline))
				to_chat(teacher, "<span class='warning'>Your student is not whitelisted for any Clans with this Discipline, so they cannot learn it.</span>")
				qdel(giving_discipline)
				return

		//ensure the teacher's mastered it, also prevents them from teaching with free starting experience
		if (teacher_discipline.level < 5)
			to_chat(teacher, "<span class='warning'>You do not know this Discipline well enough to teach it. You need to master it to the 5th rank.</span>")
			qdel(giving_discipline)
			return

		var/restricted = giving_discipline.clane_restricted
		if (restricted)
			if (alert(teacher, "Are you sure you want to teach [student] [giving_discipline], one of your Clan's most tightly guarded secrets? This will cost 10 experience points.", "Confirmation", "Yes", "No") != "Yes")
				qdel(giving_discipline)
				return
		else
			if (alert(teacher, "Are you sure you want to teach [student] [giving_discipline]? This will cost 10 experience points.", "Confirmation", "Yes", "No") != "Yes")
				qdel(giving_discipline)
				return

		var/alienation = FALSE
		if (student.clane.restricted_disciplines.Find(teaching_discipline))
			if (alert(student, "Learning [giving_discipline] will alienate you from the rest of the [student.clane], making you just like the false Clan. Do you wish to continue?", "Confirmation", "Yes", "No") != "Yes")
				visible_message("<span class='warning'>[student] refuses [teacher]'s mentoring!</span>")
				qdel(giving_discipline)
				return
			else
				alienation = TRUE
				to_chat(teacher, "<span class='notice'>[student] accepts your mentoring!</span>")

		if (get_dist(student.loc, teacher.loc) > 1)
			to_chat(teacher, "<span class='warning'>Your student needs to be next to you!</span>")
			qdel(giving_discipline)
			return

		visible_message("<span class='notice'>[teacher] begins mentoring [student] in [giving_discipline].</span>")
		if (do_after(teacher, 30 SECONDS, student))
			teacher_prefs.true_experience -= 10

			student_prefs.discipline_types += teaching_discipline
			student_prefs.discipline_levels += 0

			if (alienation)
				var/datum/vampireclane/main_clan
				switch(student.clane.type)
					if (/datum/vampireclane/true_brujah)
						main_clan = new /datum/vampireclane/brujah
					if (/datum/vampireclane/old_clan_tzimisce)
						main_clan = new /datum/vampireclane/tzimisce

				student_prefs.clane = main_clan
				student.clane = main_clan

			student_prefs.save_character()
			teacher_prefs.save_character()

			to_chat(teacher, "<span class='notice'>You finish teaching [student] the basics of [giving_discipline]. [student.p_they(TRUE)] seem[student.p_s()] to have absorbed your mentoring.[restricted ? " May your Clanmates take mercy on your soul for spreading their secrets." : ""]</span>")
			to_chat(student, "<span class='nicegreen'>[teacher] has taught you the basics of [giving_discipline]. You may now spend experience points to learn its first level in the character menu.</span>")

			message_admins("[ADMIN_LOOKUPFLW(teacher)] taught [ADMIN_LOOKUPFLW(student)] the Discipline [giving_discipline.name].")
			log_game("[key_name(teacher)] taught [key_name(student)] the Discipline [giving_discipline.name].")

		qdel(giving_discipline)

/**
 * Checks a vampire for whitelist access to a Discipline.
 *
 * Checks the given vampire to see if they have access to a certain Discipline through
 * one of their selectable Clans. This is only necessary for "unique" or Clan-restricted
 * Disciplines, as those have a chance to only be available to a certain Clan that
 * the vampire may or may not be whitelisted for.
 *
 * Arguments:
 * * vampire_checking - The vampire mob being checked for their access.
 * * discipline_checking - The Discipline type that access to is being checked.
 */
/proc/can_access_discipline(mob/living/carbon/human/vampire_checking, discipline_checking)
	if (!is_kindred(vampire_checking))
		return FALSE
	if (!vampire_checking.client)
		return FALSE

	//make sure it's actually restricted and this check is necessary
	var/datum/discipline/discipline_object_checking = new discipline_checking
	if (!discipline_object_checking.clane_restricted)
		qdel(discipline_object_checking)
		return TRUE
	qdel(discipline_object_checking)

	//first, check their Clan Disciplines to see if that gives them access
	if (vampire_checking.clane.clane_disciplines.Find(discipline_checking))
		return TRUE

	//next, go through all Clans to check if they have access to any with the Discipline
	for (var/clan_type in subtypesof(/datum/vampireclane))
		var/datum/vampireclane/clan_checking = new clan_type

		//skip this if they can't access it due to whitelists
		if (clan_checking.whitelisted)
			if (!SSwhitelists.is_whitelisted(checked_ckey = vampire_checking.ckey, checked_whitelist = clan_checking.name))
				qdel(clan_checking)
				continue

		if (clan_checking.clane_disciplines.Find(discipline_checking))
			qdel(clan_checking)
			return TRUE

		qdel(clan_checking)

	//nothing found
	return FALSE

//Here's things for future madness

//add_client_colour(/datum/client_colour/glass_colour/red)
//remove_client_colour(/datum/client_colour/glass_colour/red)
/client/Click(object,location,control,params)
	if(isatom(object))
		if(ishuman(mob))
			var/mob/living/carbon/human/H = mob
			if(H.in_frenzy)
				return
	..()

/mob/living/carbon/proc/rollfrenzy()
	if(client)
		var/mob/living/carbon/human/H
		if(ishuman(src))
			H = src

		if(is_garou(src) || iswerewolf(src))
			to_chat(src, "I'm full of <span class='danger'><b>ANGER</b></span>, and I'm about to flare up in <span class='danger'><b>RAGE</b></span>. Rolling...")
		else if(is_kindred(src))
			to_chat(src, "I need <span class='danger'><b>BLOOD</b></span>. The <span class='danger'><b>BEAST</b></span> is calling. Rolling...")
		else
			to_chat(src, "I'm too <span class='danger'><b>AFRAID</b></span> to continue doing this. Rolling...")
		SEND_SOUND(src, sound('code/modules/wod13/sounds/bloodneed.ogg', 0, 0, 50))
		var/check = vampireroll(max(1, round(humanity/2)), min(frenzy_chance_boost, frenzy_hardness), src)
		switch(check)
			if(DICE_FAILURE)
				enter_frenzymod()
				if(is_kindred(src))
					addtimer(CALLBACK(src, PROC_REF(exit_frenzymod)), 100*H.clane.frenzymod)
				else
					addtimer(CALLBACK(src, PROC_REF(exit_frenzymod)), 100)
				frenzy_hardness = 1
			if(DICE_CRIT_FAILURE)
				enter_frenzymod()
				if(is_kindred(src))
					addtimer(CALLBACK(src, PROC_REF(exit_frenzymod)), 200*H.clane.frenzymod)
				else
					addtimer(CALLBACK(src, PROC_REF(exit_frenzymod)), 200)
				frenzy_hardness = 1
			if(DICE_CRIT_WIN)
				frenzy_hardness = max(1, frenzy_hardness-1)
			else
				frenzy_hardness = min(10, frenzy_hardness+1)

/mob/living/carbon/proc/enter_frenzymod()
	SEND_SOUND(src, sound('code/modules/wod13/sounds/frenzy.ogg', 0, 0, 50))
	in_frenzy = TRUE
	add_client_colour(/datum/client_colour/glass_colour/red)
	GLOB.frenzy_list += src

/mob/living/carbon/proc/exit_frenzymod()
	in_frenzy = FALSE
	remove_client_colour(/datum/client_colour/glass_colour/red)
	GLOB.frenzy_list -= src

/mob/living/carbon/proc/CheckFrenzyMove()
	if(stat >= SOFT_CRIT)
		return TRUE
	if(IsSleeping())
		return TRUE
	if(IsUnconscious())
		return TRUE
	if(IsParalyzed())
		return TRUE
	if(IsKnockdown())
		return TRUE
	if(IsStun())
		return TRUE
	if(HAS_TRAIT(src, TRAIT_RESTRAINED))
		return TRUE

/mob/living/carbon/proc/frenzystep()
	if(!isturf(loc) || CheckFrenzyMove())
		return
	if(m_intent == MOVE_INTENT_WALK)
		toggle_move_intent(src)
	set_glide_size(DELAY_TO_GLIDE_SIZE(total_multiplicative_slowdown()))

	var/atom/fear
	for(var/obj/effect/fire/F in GLOB.fires_list)
		if(F)
			if(get_dist(src, F) < 7 && F.z == src.z)
				if(get_dist(src, F) < 6)
					fear = F
				if(get_dist(src, F) < 5)
					fear = F
				if(get_dist(src, F) < 4)
					fear = F
				if(get_dist(src, F) < 3)
					fear = F
				if(get_dist(src, F) < 2)
					fear = F
				if(get_dist(src, F) < 1)
					fear = F

//	if(!fear && !frenzy_target)
//		return

	if(is_kindred(src))
		if(fear)
			step_away(src,fear,99)
			if(prob(25))
				emote("scream")
		else
			var/mob/living/carbon/human/H = src
			if(get_dist(frenzy_target, src) <= 1)
				if(isliving(frenzy_target))
					var/mob/living/L = frenzy_target
					if(L.bloodpool && L.stat != DEAD && last_drinkblood_use+95 <= world.time)
						L.grabbedby(src)
						if(ishuman(L))
							L.emote("scream")
							var/mob/living/carbon/human/BT = L
							BT.add_bite_animation()
						if(CheckEyewitness(L, src, 7, FALSE))
							H.AdjustMasquerade(-1)
						playsound(src, 'code/modules/wod13/sounds/drinkblood1.ogg', 50, TRUE)
						L.visible_message("<span class='warning'><b>[src] bites [L]'s neck!</b></span>", "<span class='warning'><b>[src] bites your neck!</b></span>")
						face_atom(L)
						H.drinksomeblood(L)
			else
				step_to(src,frenzy_target,0)
				face_atom(frenzy_target)
	else
		if(get_dist(frenzy_target, src) <= 1)
			if(isliving(frenzy_target))
				var/mob/living/L = frenzy_target
				if(L.stat != DEAD)
					a_intent = INTENT_HARM
					if(last_rage_hit+5 < world.time)
						last_rage_hit = world.time
						UnarmedAttack(L)
		else
			step_to(src,frenzy_target,0)
			face_atom(frenzy_target)

/mob/living/carbon/proc/get_frenzy_targets()
	var/list/targets = list()
	if(is_kindred(src))
		for(var/mob/living/L in oviewers(7, src))
			if(!is_kindred(L) && L.bloodpool && L.stat != DEAD)
				targets += L
				if(L == frenzy_target)
					return L
	else
		for(var/mob/living/L in oviewers(7, src))
			if(L.stat != DEAD)
				targets += L
				if(L == frenzy_target)
					return L
	if(length(targets) > 0)
		return pick(targets)
	else
		return null

/mob/living/carbon/proc/handle_automated_frenzy()
	for(var/mob/living/carbon/human/npc/NPC in viewers(5, src))
		NPC.Aggro(src)
	if(isturf(loc))
		frenzy_target = get_frenzy_targets()
		if(frenzy_target)
			var/datum/cb = CALLBACK(src, PROC_REF(frenzystep))
			var/reqsteps = SSfrenzypool.wait/total_multiplicative_slowdown()
			for(var/i in 1 to reqsteps)
				addtimer(cb, (i - 1)*total_multiplicative_slowdown())
		else
			if(!CheckFrenzyMove())
				if(isturf(loc))
					var/turf/T = get_step(loc, pick(NORTH, SOUTH, WEST, EAST))
					face_atom(T)
					Move(T)

/datum/splat/supernatural/kindred/spec_life(mob/living/carbon/human/H)
	. = ..()
	if(H.clane?.name == "Baali")
		if(istype(get_area(H), /area/vtm/masquerade/interior/church))
			if(prob(25))
				to_chat(H, "<span class='warning'>You don't belong here!</span>")
				H.adjustFireLoss(20)
				H.adjust_fire_stacks(6)
				H.IgniteMob()
	//FIRE FEAR
	if(!H.antifrenzy && !HAS_TRAIT(H, TRAIT_KNOCKEDOUT))
		var/fearstack = 0
		for(var/obj/effect/fire/F in GLOB.fires_list)
			if(F)
				if(get_dist(F, H) < 8 && F.z == H.z)
					fearstack += F.stage
		for(var/mob/living/carbon/human/U in viewers(7, H))
			if(U.on_fire)
				fearstack += 1

		fearstack = min(fearstack, 10)

		if(fearstack)
			if(prob(fearstack*5))
				H.do_jitter_animation(10)
				if(fearstack > 20)
					if(prob(fearstack))
						if(!H.in_frenzy)
							H.rollfrenzy()
			if(!H.has_status_effect(STATUS_EFFECT_FEAR))
				H.apply_status_effect(STATUS_EFFECT_FEAR)
		else
			H.remove_status_effect(STATUS_EFFECT_FEAR)

	//masquerade violations due to unnatural appearances
	if(H.is_face_visible() && H.clane?.violating_appearance)
		switch(H.clane.alt_sprite)
			if ("kiasyd")
				//masquerade breach if eyes are uncovered, short range
				if (!H.is_eyes_covered())
					if (H.CheckEyewitness(H, H, 3, FALSE))
						H.AdjustMasquerade(-1)
			if ("rotten3")
				//slightly less range than if fully decomposed
				if (H.CheckEyewitness(H, H, 5, FALSE))
					H.AdjustMasquerade(-1)
			else
				//gargoyles, nosferatu, skeletons, that kind of thing
				if (H.CheckEyewitness(H, H, 7, FALSE))
					H.AdjustMasquerade(-1)

	if(HAS_TRAIT(H, TRAIT_UNMASQUERADE))
		if(H.CheckEyewitness(H, H, 7, FALSE))
			H.AdjustMasquerade(-1)
	if(HAS_TRAIT(H, TRAIT_NONMASQUERADE))
		if(H.CheckEyewitness(H, H, 7, FALSE))
			H.AdjustMasquerade(-1)
	if(istype(get_area(H), /area/vtm))
		var/area/vtm/V = get_area(H)
		if(V.zone_type == "masquerade" && V.upper)
			if(H.pulling)
				if(ishuman(H.pulling))
					var/mob/living/carbon/human/pull = H.pulling
					if(pull.stat == DEAD)
						var/obj/item/card/id/id_card = H.get_idcard(FALSE)
						if(!istype(id_card, /obj/item/card/id/clinic))
							if(H.CheckEyewitness(H, H, 7, FALSE))
								if(H.last_loot_check+50 <= world.time)
									H.last_loot_check = world.time
									H.last_nonraid = world.time
									H.killed_count = H.killed_count+1
									if(!H.warrant && !H.ignores_warrant)
										if(H.killed_count >= 5)
											H.warrant = TRUE
											SEND_SOUND(H, sound('code/modules/wod13/sounds/suspect.ogg', 0, 0, 75))
											to_chat(H, "<span class='userdanger'><b>POLICE ASSAULT IN PROGRESS</b></span>")
										else
											SEND_SOUND(H, sound('code/modules/wod13/sounds/sus.ogg', 0, 0, 75))
											to_chat(H, "<span class='userdanger'><b>SUSPICIOUS ACTION (corpse)</b></span>")
			for(var/obj/item/I in H.contents)
				if(I)
					if(I.masquerade_violating)
						if(I.loc == H)
							var/obj/item/card/id/id_card = H.get_idcard(FALSE)
							if(!istype(id_card, /obj/item/card/id/clinic))
								if(H.CheckEyewitness(H, H, 7, FALSE))
									if(H.last_loot_check+50 <= world.time)
										H.last_loot_check = world.time
										H.last_nonraid = world.time
										H.killed_count = H.killed_count+1
										if(!H.warrant && !H.ignores_warrant)
											if(H.killed_count >= 5)
												H.warrant = TRUE
												SEND_SOUND(H, sound('code/modules/wod13/sounds/suspect.ogg', 0, 0, 75))
												to_chat(H, "<span class='userdanger'><b>POLICE ASSAULT IN PROGRESS</b></span>")
											else
												SEND_SOUND(H, sound('code/modules/wod13/sounds/sus.ogg', 0, 0, 75))
												to_chat(H, "<span class='userdanger'><b>SUSPICIOUS ACTION (equipment)</b></span>")
	if(H.hearing_ghosts)
		H.bloodpool = max(0, H.bloodpool-1)
		to_chat(H, "<span class='warning'>Necromancy Vision reduces your blood points too sustain itself.</span>")

	if(H.clane?.name == "Tzimisce" || H.clane?.name == "Old Clan Tzimisce")
		var/datum/vampireclane/tzimisce/TZ = H.clane
		if(TZ.heirl)
			if(!(TZ.heirl in H.GetAllContents()))
				if(prob(5))
					to_chat(H, "<span class='warning'>You are missing your home soil...</span>")
					H.bloodpool = max(0, H.bloodpool-1)
	if(H.clane?.name == "Kiasyd")
		var/datum/vampireclane/kiasyd/kiasyd = H.clane
		for(var/obj/item/I in H.contents)
			if(I?.is_iron)
				if (COOLDOWN_FINISHED(kiasyd, cold_iron_frenzy))
					COOLDOWN_START(kiasyd, cold_iron_frenzy, 10 SECONDS)
					H.rollfrenzy()
					to_chat(H, "<span class='warning'>[I] is <b>COLD IRON</b>!")

/*
	if(!H in GLOB.masquerade_breakers_list)
		if(H.masquerade < 4)
			GLOB.masquerade_breakers_list += H
	else if(H in GLOB.masquerade_breakers_list)
		if(H.masquerade > 3)
			GLOB.masquerade_breakers_list -= H
*/

	if(H.key && (H.stat <= HARD_CRIT))
		var/datum/preferences/P = GLOB.preferences_datums[ckey(H.key)]
		if(P)
			if(P.humanity != H.humanity)
				P.humanity = H.humanity
				P.save_preferences()
				P.save_character()
			if(P.masquerade != H.masquerade)
				P.masquerade = H.masquerade
				P.save_preferences()
				P.save_character()
//			if(H.last_experience+600 <= world.time)
//				var/addd = 5
//				if(!H.JOB && H.mind)
//					H.JOB = SSjob.GetJob(H.mind.assigned_role)
//					if(H.JOB)
//						addd = H.JOB.experience_addition
//				P.exper = min(calculate_mob_max_exper(H), P.exper+addd+H.experience_plus)
//				if(P.exper == calculate_mob_max_exper(H))
//					to_chat(H, "You've reached a new level! You can add new points in Character Setup (Lobby screen).")
//				P.save_preferences()
//				P.save_character()
//				H.last_experience = world.time
//			if(H.roundstart_vampire)
//				if(P.generation != H.generation)
//					P.generation = H.generation
//					P.save_preferences()
//					P.save_character()
			if(!H.antifrenzy)
				if(P.humanity < 1)
					H.enter_frenzymod()
					to_chat(H, "<span class='userdanger'>You have lost control of the Beast within you, and it has taken your body. Be more [H.client.prefs.enlightenment ? "Enlightened" : "humane"] next time.</span>")
					H.ghostize(FALSE)
					P.reason_of_death = "Lost control to the Beast ([time2text(world.timeofday, "YYYY-MM-DD hh:mm:ss")])."

	if(H.clane && !H.antifrenzy && !HAS_TRAIT(H, TRAIT_KNOCKEDOUT))
		if(H.clane.name == "Banu Haqim")
			if(H.mind)
				if(H.mind.enslaved_to)
					if(get_dist(H, H.mind.enslaved_to) > 10)
						if((H.last_frenzy_check + 40 SECONDS) <= world.time)
							to_chat(H, "<span class='warning'><b>As you are far from [H.mind.enslaved_to], you feel the desire to drink more vitae!<b></span>")
							H.last_frenzy_check = world.time
							H.rollfrenzy()
					else if(H.bloodpool > 1 || H.in_frenzy)
						H.last_frenzy_check = world.time
		else
			if(H.bloodpool > 1 || H.in_frenzy)
				H.last_frenzy_check = world.time

//	var/list/blood_fr = list()
//	for(var/obj/effect/decal/cleanable/blood/B in range(7, src))
//		if(B.bloodiness)
//			blood_fr += B
	if(!H.antifrenzy && !HAS_TRAIT(H, TRAIT_KNOCKEDOUT))
		if(H.bloodpool <= 1 && !H.in_frenzy)
			if((H.last_frenzy_check + 40 SECONDS) <= world.time)
				H.last_frenzy_check = world.time
				H.rollfrenzy()
				if(H.clane)
					if(H.clane.enlightenment)
						if(!H.CheckFrenzyMove())
							H.AdjustHumanity(1, 10)
//	if(length(blood_fr) >= 10 && !H.in_frenzy)
//		if(H.last_frenzy_check+400 <= world.time)
//			H.last_frenzy_check = world.time
//			H.rollfrenzy()

/mob/living/proc/torpor(source)
	if (HAS_TRAIT(src, TRAIT_TORPOR))
		return
	if (fakedeath(source))
		to_chat(src, "<span class='danger'>You have fallen into Torpor. Use the button in the top right to learn more, or attempt to wake up.</span>")
		ADD_TRAIT(src, TRAIT_TORPOR, source)
		if (is_kindred(src))
			var/mob/living/carbon/human/vampire = src
			var/datum/splat/supernatural/kindred/vampire_species = vampire.dna.species
			var/torpor_length = 0 SECONDS
			switch(humanity)
				if(10)
					torpor_length = 1 MINUTES
				if(9)
					torpor_length = 3 MINUTES
				if(8)
					torpor_length = 4 MINUTES
				if(7)
					torpor_length = 5 MINUTES
				if(6)
					torpor_length = 10 MINUTES
				if(5)
					torpor_length = 15 MINUTES
				if(4)
					torpor_length = 30 MINUTES
				if(3)
					torpor_length = 1 HOURS
				if(2)
					torpor_length = 2 HOURS
				if(1)
					torpor_length = 3 HOURS
				else
					torpor_length = 5 HOURS
			COOLDOWN_START(vampire_splat, torpor_timer, torpor_length)

/atom/movable/screen/alert/untorpor
	name = "Awaken"
	desc = "Free yourself of your Torpor."
	icon_state = "awaken"

/atom/movable/screen/alert/untorpor/Click() //PSEUDO_M this needs to call a do_action not do all the actions
	if(isobserver(usr))
		return
	var/mob/living/living_owner = owner
	if (!is_kindred(living_owner))
		return

	var/mob/living/carbon/human/vampire = living_owner
	var/datum/splat/supernatural/kindred/kindred_species = vampire.splat_flags & SPLAT_KINDRED
	if (COOLDOWN_FINISHED(kindred_species, torpor_timer) && (vampire.bloodpool > 0))	//PSEUDO_M_K
		vampire.untorpor()
		spawn()
			vampire.clear_alert("succumb")
	else
		to_chat(usr, "<span class='purple'><i>You are in Torpor, the sleep of death that vampires go into when injured, starved, or exhausted.</i></span>")
		if (vampire.bloodpool > 0)
			to_chat(usr, "<span class='purple'><i>You will be able to awaken in <b>[DisplayTimeText(COOLDOWN_TIMELEFT(kindred_species, torpor_timer))]</b>.</i></span>")
			to_chat(usr, "<span class='purple'><i>The time to re-awaken depends on your [(vampire.humanity > 5) ? "high" : "low"] [vampire.client.prefs.enlightenment ? "Enlightenment" : "Humanity"] rating of [vampire.humanity].</i></span>")
		else
			to_chat(usr, "<span class='danger'><i>You will not be able to re-awaken, because you have no blood available to do so.</i></span>")

//PSEUDO_M add some shit for malkavian craziness but they don't need to poll the entire
//clan every time anyone says anything, for god's sake

/datum/splat/supernatural/kindred/signal_for_clans_with_special_petrify_bs()
	if(is_kindred(src))
		if(clane_type)
			if(clane_type == "Serpentis")
				ADD_TRAIT(src, TRAIT_NOBLEED, MAGIC_TRAIT)
				var/obj/structure/statue/petrified/S = new(loc, src, statue_timer)
				S.name = "[name]'s mummy"
				S.icon_state = "mummy"
				S.desc = "CURSE OF RA 𓀀 𓀁 𓀂 𓀃 𓀄 𓀅 𓀆 𓀇 𓀈 𓀉 𓀊 𓀋 𓀌 𓀍 𓀎 𓀏 𓀐 𓀑 𓀒 𓀓 𓀔 𓀕 𓀖 𓀗 𓀘 𓀙 𓀚 𓀛 𓀜 𓀝 𓀞 𓀟 𓀠 𓀡 𓀢 𓀣 𓀤 𓀥 𓀦 𓀧 𓀨 𓀩 𓀪 𓀫 𓀬 𓀭 𓀮 𓀯 𓀰 𓀱 𓀲 𓀳 𓀴 𓀵 𓀶 𓀷 𓀸 𓀹 𓀺 𓀻 𓀼 𓀽 𓀾 𓀿 𓁀 𓁁 𓁂 𓁃 𓁄 𓁅 𓁆 𓁇 𓁈 𓁉 𓁊 𓁋 𓁌 𓁍 𓁎 𓁏 𓁐 𓁑 𓀄 𓀅 𓀆."
			if(clane_type == "Visceratika")
				ADD_TRAIT(src, TRAIT_NOBLEED, MAGIC_TRAIT)
				var/obj/structure/statue/petrified/S = new(loc, src, statue_timer)
				S.name = "\improper gargoyle"
				S.desc = "Some kind of gothic architecture."
				S.icon = 'code/modules/wod13/32x48.dmi'
				S.icon_state = "gargoyle"
				S.dir = dir
				S.pixel_z = -16
