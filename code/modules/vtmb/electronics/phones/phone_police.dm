/obj/item/vamp/device/police
	name = "\A crisis dispatch radio"
	desc = "A radio used by the police in moments of crisis to call for backup and put out all-points bulletins."
	icon = 'code/modules/wod13/items.dmi'
	icon_state = "phone_p"
	inhand_icon_state = "phone_p"
	lefthand_file = 'code/modules/wod13/lefthand.dmi'
	righthand_file = 'code/modules/wod13/righthand.dmi'
	item_flags = NOBLUDGEON
	flags_1 = HEAR_1
	w_class = WEIGHT_CLASS_SMALL
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 100)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	onflooricon = 'code/modules/wod13/onfloor.dmi'

/obj/item/vamp/device/police/Destroy()
	. = ..()
	//PSEUDO_M handle the removal of the APB from the player when the device is destroyed

/obj/item/vamp/device/police/attack_self(mob/user)
	. = ..()

	var/mob/living/carbon/human/P = usr
	var/list/jobs = list("Police Officer", "Police Chief", "Police Sergeant","Federal Investigator")
	var/list/jobs_notify = list("Police Officer", "Police Chief", "Police Sergeant","Federal Investigator", "SWAT", "National Guard")
	//PSEUDO_M we're going to signal a subsystem for this instead

	if(P.job in jobs)
		var/list/options = list(
			"Add an APB",
			"Remove an APB",
			"See APB",
			"See APB History",
			"See Most Wanted")
		var/option =  input(usr, "Select an option", "APB Option") as null|anything in options

if(option == "Add an APB")	//PSEUDO_M atomize

if(option == "Remove an APB")//PSEUDO_M atomize

if(option == "See Currents APB")//PSEUDO_M atomize

if(option == "See APB History")//PSEUDO_M atomize

if(option == "See Currents SWAT Hunts")//PSEUDO_M atomize

			to_chat(usr, text)

		//PSEUDO_M call_for_backup (spawn NPC goons to help the officer)

	else
		to_chat(usr, "<span class='warning'>You can't acess this device!</span>")



/obj/item/vamp/device/police/police_chief
	name = "\A police device for the police chief"
	desc = "A device exclusive for the police chief."

/obj/item/vamp/device/police/police_chief/attack_self(mob/user)
	// inheritance
	var/mob/living/carbon/human/P = usr
	var/list/jobs = list("Police Chief")
	var/list/jobs_notify = list("Police Officer", "Police Chief", "Police Sergeant","Federal Investigator", "SWAT", "National Guard")

	if(P.job in jobs)
		var/list/options = list("Add an APB","Remove an APB","See Currents APB","See APB History", "Request the SWAT", "Call off the SWAT","See Currents SWAT Hunts" ,"See SWAT History")
		var/option =  input(usr, "Select an option", "APB Option") as null|anything in options

/obj/item/vamp/device/police/fbi
	name = "\A device for the FBI Agents"
	desc = "A device exclusive for the FBI Agents."

