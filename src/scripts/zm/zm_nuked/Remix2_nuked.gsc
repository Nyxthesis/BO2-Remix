#include maps/mp/zombies/_zm_utility;
#include maps/mp/_utility;
#include common_scripts/utility;
#include maps/mp/zombies/_zm_blockers;
#include maps/mp/zombies/_zm_magicbox;
// #include maps/mp/zm_nuked_perks;

#include scripts/zm/zm_nuked/remix/_nuked_weapons;
#include scripts/zm/zm_nuked/remix/_nuked_zones;


main()
{
    replaceFunc( maps/mp/zm_nuked_perks::perks_from_the_sky, ::perks_from_the_sky_override );
    replaceFunc( maps/mp/zm_nuked_perks::init_nuked_perks, ::init_nuked_perks_override );

	level.initial_spawn_nuked = true;
    level thread set_magicbox_location();
    level thread onplayerconnect();
}

onplayerconnect()
{   
    for(;;)
    {
        level waittill("connected", player);
        player thread onplayerspawned();
    }
}

onplayerspawned()
{
    self endon("disconnect");
    self.initial_spawn_nuked = true;
    
    for(;;)
    {
        self waittill("spawned_player");

        if(self.initial_spawn_nuked)
		{
            self.initial_spawn_nuked = false;
        }

        if(level.initial_spawn_nuked)
        {
            level.initial_spawn_nuked = false;

			flag_wait( "start_zombie_round_logic" );
   			wait 0.05;

			limit_m72();
            remove_ground_spawns();
        }
    }
}

set_magicbox_location()
{
	if( getDvar("nuked_box") == "" )
        setDvar("nuked_box", " ");
	box = getDvar("nuked_box");

	// choose box location
	level.pap_at_green_house = false;
	if(cointoss())
		level.pap_at_green_house = true;
	if(box == "green")
		level.pap_at_green_house = true;
	if(box == "yellow")
		level.pap_at_green_house = false;

	// set box location
	flag_wait( "start_zombie_round_logic" );
	wait 4;
	if(level.pap_at_green_house == true)
		start_chest = "start_chest1";
	else
		start_chest = "start_chest2";

	for(i = 0; i < level.chests.size; i++)
	{
		if(level.chests[i].script_noteworthy == start_chest)
			desired_chest_index = i; 
		else if(level.chests[i].hidden == 0)
			nondesired_chest_index = i;               	
	}
	if( isdefined(nondesired_chest_index) && (nondesired_chest_index < desired_chest_index))
	{
		level.chests[nondesired_chest_index] hide_chest();
		level.chests[nondesired_chest_index].hidden = 1;

		level.chests[desired_chest_index].hidden = 0;
		level.chests[desired_chest_index] show_chest();
		level.chest_index = desired_chest_index;
	}            	
}

/*
* *****************************************************
*	
* ********************* Overrides **********************
*
* *****************************************************
*/


init_nuked_perks_override() //checked changed to match cerberus output
{
	level.perk_arrival_vehicle = getent( "perk_arrival_vehicle", "targetname" );
	level.perk_arrival_vehicle setmodel( "tag_origin" );
	flag_init( "perk_vehicle_bringing_in_perk" );
	structs = getstructarray( "zm_perk_machine", "targetname" );
	for ( i = 0; i < structs.size; i++ )
	{
		structs[ i ] structdelete();
	}
	level.nuked_perks = [];
	level.nuked_perks[ 0 ] = spawnstruct();
	level.nuked_perks[ 0 ].model = "zombie_vending_revive";
	level.nuked_perks[ 0 ].script_noteworthy = "specialty_quickrevive";
	level.nuked_perks[ 0 ].turn_on_notify = "revive_on";
	level.nuked_perks[ 1 ] = spawnstruct();
	level.nuked_perks[ 1 ].model = "zombie_vending_sleight";
	level.nuked_perks[ 1 ].script_noteworthy = "specialty_fastreload";
	level.nuked_perks[ 1 ].turn_on_notify = "sleight_on";
	level.nuked_perks[ 2 ] = spawnstruct();
	level.nuked_perks[ 2 ].model = "zombie_vending_doubletap2";
	level.nuked_perks[ 2 ].script_noteworthy = "specialty_rof";
	level.nuked_perks[ 2 ].turn_on_notify = "doubletap_on";
	level.nuked_perks[ 3 ] = spawnstruct();
	level.nuked_perks[ 3 ].model = "zombie_vending_jugg";
	level.nuked_perks[ 3 ].script_noteworthy = "specialty_armorvest";
	level.nuked_perks[ 3 ].turn_on_notify = "juggernog_on";
	level.nuked_perks[ 4 ] = spawnstruct();
	level.nuked_perks[ 4 ].model = "p6_anim_zm_buildable_pap";
	level.nuked_perks[ 4 ].script_noteworthy = "specialty_weapupgrade";
	level.nuked_perks[ 4 ].turn_on_notify = "Pack_A_Punch_on";
	level.override_perk_targetname = "zm_perk_machine_override";
    
	random_perk_structs = [];
	perk_structs = getstructarray( "zm_random_machine", "script_noteworthy" );
	for ( i = 0; i < perk_structs.size; i++ )
	{
		random_perk_structs[ i ] = getstruct( perk_structs[ i ].target, "targetname" );
		random_perk_structs[ i ].script_int = perk_structs[ i ].script_int;
	}
	if ( !isDefined( level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ] ) )
	{
		level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ] = [];
	}

	//Perk Structs Indexes
	/*
	left greenhouse backyard (-2055.91, 238.03, 7934) script_int 7
	right greenhouse backyard (-1716.2, 970.42, 7932) script_int 5
	garage (-844.93, 60.8, 7939) script_int 8
	on corner of greenhouse in the first room (-455.42, 617.4, 7932) script_int 9
	dead end of first room next to yellow house (804.1, -56.86, 7929) script_int 3
	yellow house next to stairs (1353.63, 584.12, 7936) script_int 1
	dead end of yellow house backyard (2041.63, 153.13, 7928) script_int 0
	next to the sign in the first room (-82.07, 740.67, 7932) script_int 6
	left corner of the yellow house script_int 2
	inside the yellow house script_int 4

    example:
    level.random_perk_structs[ 0 ] = getstruct( perk_structs[ 9 ].target, "targetname" ); sets revive to "on corner of greenhouse in the first room"
	*/
    if( level.pap_at_green_house )
    {
        level.random_perk_structs = [];
        level.random_perk_structs[ 0 ] = getstruct( perk_structs[ 9 ].target, "targetname" );
        level.random_perk_structs[ 0 ].targetname = "zm_perk_machine_override";
        level.random_perk_structs[ 0 ].model = level.nuked_perks[ 0 ].model;
        level.random_perk_structs[ 0 ].blocker_model = getent( level.random_perk_structs[ 0 ].target, "targetname" );
        level.random_perk_structs[ 0 ].script_noteworthy = level.nuked_perks[ 0 ].script_noteworthy;
        level.random_perk_structs[ 0 ].turn_on_notify = level.nuked_perks[ 0 ].turn_on_notify;
        level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ][ level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ].size ] = level.random_perk_structs[ 0 ];

        level.random_perk_structs[ 1 ] = getstruct( perk_structs[ 3 ].target, "targetname" );
        level.random_perk_structs[ 1 ].targetname = "zm_perk_machine_override";
        level.random_perk_structs[ 1 ].model = level.nuked_perks[ 1 ].model;
        level.random_perk_structs[ 1 ].blocker_model = getent( level.random_perk_structs[ 1 ].target, "targetname" );
        level.random_perk_structs[ 1 ].script_noteworthy = level.nuked_perks[ 1 ].script_noteworthy;
        level.random_perk_structs[ 1 ].turn_on_notify = level.nuked_perks[ 1 ].turn_on_notify;
        level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ][ level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ].size ] = level.random_perk_structs[ 1 ];
		
        level.random_perk_structs[ 2 ] = getstruct( perk_structs[ 6 ].target, "targetname" );
        level.random_perk_structs[ 2 ].targetname = "zm_perk_machine_override";
        level.random_perk_structs[ 2 ].model = level.nuked_perks[ 2 ].model;
        level.random_perk_structs[ 2 ].blocker_model = getent( level.random_perk_structs[ 2 ].target, "targetname" );
        level.random_perk_structs[ 2 ].script_noteworthy = level.nuked_perks[ 2 ].script_noteworthy;
        level.random_perk_structs[ 2 ].turn_on_notify = level.nuked_perks[ 2 ].turn_on_notify;
        level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ][ level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ].size ] = level.random_perk_structs[ 2 ];

        level.random_perk_structs[ 3 ] = getstruct( perk_structs[ 5 ].target, "targetname" );
        level.random_perk_structs[ 3 ].targetname = "zm_perk_machine_override";
        level.random_perk_structs[ 3 ].model = level.nuked_perks[ 3 ].model;
        level.random_perk_structs[ 3 ].blocker_model = getent( level.random_perk_structs[ 3 ].target, "targetname" );
        level.random_perk_structs[ 3 ].script_noteworthy = level.nuked_perks[ 3 ].script_noteworthy;
        level.random_perk_structs[ 3 ].turn_on_notify = level.nuked_perks[ 3 ].turn_on_notify;
        level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ][ level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ].size ] = level.random_perk_structs[ 3 ];

        level.random_perk_structs[ 4 ] = getstruct( perk_structs[ 7 ].target, "targetname" );
        level.random_perk_structs[ 4 ].targetname = "zm_perk_machine_override";
        level.random_perk_structs[ 4 ].model = level.nuked_perks[ 4 ].model;
        level.random_perk_structs[ 4 ].blocker_model = getent( level.random_perk_structs[ 4 ].target, "targetname" );
        level.random_perk_structs[ 4 ].script_noteworthy = level.nuked_perks[ 4 ].script_noteworthy;
        level.random_perk_structs[ 4 ].turn_on_notify = level.nuked_perks[ 4 ].turn_on_notify;
        level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ][ level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ].size ] = level.random_perk_structs[ 4 ];
    }
    else
    {
        level.random_perk_structs[ 0 ] = getstruct( perk_structs[ 9 ].target, "targetname" );
        level.random_perk_structs[ 0 ].targetname = "zm_perk_machine_override";
        level.random_perk_structs[ 0 ].model = level.nuked_perks[ 0 ].model;
        level.random_perk_structs[ 0 ].blocker_model = getent( level.random_perk_structs[ 0 ].target, "targetname" );
        level.random_perk_structs[ 0 ].script_noteworthy = level.nuked_perks[ 0 ].script_noteworthy;
        level.random_perk_structs[ 0 ].turn_on_notify = level.nuked_perks[ 0 ].turn_on_notify;
        level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ][ level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ].size ] = level.random_perk_structs[ 0 ];

        level.random_perk_structs[ 1 ] = getstruct( perk_structs[ 3 ].target, "targetname" );
        level.random_perk_structs[ 1 ].targetname = "zm_perk_machine_override";
        level.random_perk_structs[ 1 ].model = level.nuked_perks[ 1 ].model;
        level.random_perk_structs[ 1 ].blocker_model = getent( level.random_perk_structs[ 1 ].target, "targetname" );
        level.random_perk_structs[ 1 ].script_noteworthy = level.nuked_perks[ 1 ].script_noteworthy;
        level.random_perk_structs[ 1 ].turn_on_notify = level.nuked_perks[ 1 ].turn_on_notify;
        level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ][ level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ].size ] = level.random_perk_structs[ 1 ];

        level.random_perk_structs[ 2 ] = getstruct( perk_structs[ 6 ].target, "targetname" );
        level.random_perk_structs[ 2 ].targetname = "zm_perk_machine_override";
        level.random_perk_structs[ 2 ].model = level.nuked_perks[ 2 ].model;
        level.random_perk_structs[ 2 ].blocker_model = getent( level.random_perk_structs[ 2 ].target, "targetname" );
        level.random_perk_structs[ 2 ].script_noteworthy = level.nuked_perks[ 2 ].script_noteworthy;
        level.random_perk_structs[ 2 ].turn_on_notify = level.nuked_perks[ 2 ].turn_on_notify;
        level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ][ level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ].size ] = level.random_perk_structs[ 2 ];

        level.random_perk_structs[ 3 ] = getstruct( perk_structs[ 0 ].target, "targetname" );
        level.random_perk_structs[ 3 ].targetname = "zm_perk_machine_override";
        level.random_perk_structs[ 3 ].model = level.nuked_perks[ 3 ].model;
        level.random_perk_structs[ 3 ].blocker_model = getent( level.random_perk_structs[ 3 ].target, "targetname" );
        level.random_perk_structs[ 3 ].script_noteworthy = level.nuked_perks[ 3 ].script_noteworthy;
        level.random_perk_structs[ 3 ].turn_on_notify = level.nuked_perks[ 3 ].turn_on_notify;
        level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ][ level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ].size ] = level.random_perk_structs[ 3 ];

        level.random_perk_structs[ 4 ] = getstruct( perk_structs[ 1 ].target, "targetname" );
        level.random_perk_structs[ 4 ].targetname = "zm_perk_machine_override";
        level.random_perk_structs[ 4 ].model = level.nuked_perks[ 4 ].model;
        level.random_perk_structs[ 4 ].blocker_model = getent( level.random_perk_structs[ 4 ].target, "targetname" );
        level.random_perk_structs[ 4 ].script_noteworthy = level.nuked_perks[ 4 ].script_noteworthy;
        level.random_perk_structs[ 4 ].turn_on_notify = level.nuked_perks[ 4 ].turn_on_notify;
        level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ][ level.struct_class_names[ "targetname" ][ "zm_perk_machine_override" ].size ] = level.random_perk_structs[ 4 ];
    }
}

perks_from_the_sky_override()
{
	level thread maps/mp/zm_nuked_perks::turn_perks_on();
	top_height = 8000;
	machines = [];
	machine_triggers = [];
	machines[ 0 ] = getent( "vending_revive", "targetname" );
	machine_triggers[ 0 ] = getent( "vending_revive", "target" );
	maps/mp/zm_nuked_perks::move_perk( machines[ 0 ], top_height, 5, 0.001 );
	machine_triggers[ 0 ] trigger_off();
	machines[ 1 ] = getent( "vending_doubletap", "targetname" );
	machine_triggers[ 1 ] = getent( "vending_doubletap", "target" );
	maps/mp/zm_nuked_perks::move_perk( machines[ 1 ], top_height, 5, 0.001 );
	machine_triggers[ 1 ] trigger_off();
	machines[ 2 ] = getent( "vending_sleight", "targetname" );
	machine_triggers[ 2 ] = getent( "vending_sleight", "target" );
	maps/mp/zm_nuked_perks::move_perk( machines[ 2 ], top_height, 5, 0.001 );
	machine_triggers[ 2 ] trigger_off();
	machines[ 3 ] = getent( "vending_jugg", "targetname" );
	machine_triggers[ 3 ] = getent( "vending_jugg", "target" );
	maps/mp/zm_nuked_perks::move_perk( machines[ 3 ], top_height, 5, 0.001 );
	machine_triggers[ 3 ] trigger_off();
	machine_triggers[ 4 ] = getent( "specialty_weapupgrade", "script_noteworthy" );
	machines[ 4 ] = getent( machine_triggers[ 4 ].target, "targetname" );
	maps/mp/zm_nuked_perks::move_perk( machines[ 4 ], top_height, 5, 0.001 );
	machine_triggers[ 4 ] trigger_off();

	flag_wait( "initial_blackscreen_passed" );
    maps/mp/zm_nuked_perks::wait_for_round_range( 2, 4 );
	wait randomintrange( 30, 60 );
	bring_random_perk1( machines, machine_triggers );
	maps/mp/zm_nuked_perks::wait_for_round_range( 4, 7 );
	wait randomintrange( 30, 60 );
	bring_random_perk1( machines, machine_triggers );
	maps/mp/zm_nuked_perks::wait_for_round_range( 8, 11 );
	wait randomintrange( 30, 60  );
	bring_random_perk1( machines, machine_triggers );
	maps/mp/zm_nuked_perks::wait_for_round_range( 12, 15 );
	wait randomintrange( 30, 60  );
	bring_random_perk1( machines, machine_triggers );
	maps/mp/zm_nuked_perks::wait_for_round_range( 15, 18 );
	wait randomintrange( 30, 60  );
	bring_random_perk1( machines, machine_triggers );
}

bring_random_perk1( machines, machine_triggers ) //checked matches cerberus output
{
	//Perk Indexes
	/*
		0 = quick revive
		4 = double tap
		1 = speed cola
		3 = jugg
		2 = pack
	*/
	if ( !isDefined( level.machines_fallen ) )
	{
		level.machines_fallen = 0;
		index = 0;
	}
	else if ( level.machines_fallen == 1 )
	{
		index = 3;
	}
	else if ( level.machines_fallen == 2 )
	{
		index = 4;
	}
	else if ( level.machines_fallen == 3 )
	{
		index = 2;
	}
    else if ( level.machines_fallen == 4 )
	{
		index = 1;
	}
	if ( level.machines_fallen > 4 )
	{
		return;
	}

	maps/mp/zm_nuked_perks::bring_perk( machines[ index ], machine_triggers[ index ] );
	level.machines_fallen++;
}
