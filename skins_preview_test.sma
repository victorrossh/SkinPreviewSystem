#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#define PLUGIN "Skins Preview"
#define VERSION "1.0"
#define AUTHOR "ftl~"

#define MODEL_CLASSNAME "skin_preview"
#define SKINS_NUM 6
#define PREVIEW_TIME 15.0 // Time in seconds before preview is automatically removed

// Variable to store the preview entity for each player
new g_iUserEntityIndex[33];
new Float:g_fPreviewDistance[33] = {50.0, ...}; // Default distance
new g_iPreviewTask[33]; // Store task IDs for countdown and removal
new Float:g_fPreviewStartTime[33]; // Store start time of preview for each player

enum eSkin
{
	szName[64],
	szModel[128],
	iSubmodel
}

// Array with test skins
new g_Skins[SKINS_NUM][eSkin] = {
	{"Knife Ahegao", "models/llg2025/v_def_knife.mdl", 26},
	{"USP Abstract Blue", "models/llg2025/v_usp.mdl", 23},
	{"Pink Panther", "models/player/llg2025_panther/llg2025_panther.mdl", 0},
	{"Neo", "models/player/llg_player_compiled/llg_player_compiled.mdl", 7},
	{"Mila", "models/player/llg2025_mila/llg2025_mila.mdl", 0},
	{"Banana", "models/player/llg_player_compiled/llg_player_compiled.mdl", 6}
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_clcmd("say /preview", "cmd_test_preview");

	// Register thinker for the entity to follow the aim
	register_think(MODEL_CLASSNAME, "think_preview");
}

public plugin_precache()
{
	new mdl[128];
	
	// Precache all models from g_Skins array
	for (new i = 0; i < SKINS_NUM; i++)
	{
		precache_model(g_Skins[i][szModel]);
		
		// Check and precache T model if it exists (for player models)
		if (containi(g_Skins[i][szModel], "models/player/") != -1)
		{
			format(mdl, charsmax(mdl), "%sT.mdl", g_Skins[i][szModel]);
			if (file_exists(mdl))
				precache_generic(mdl);
		}
	}

	precache_model("models/rpgrocket.mdl");
}

public cmd_test_preview(id)
{
	if (!is_user_alive(id))
	{
		client_print(id, print_chat, "You need to be alive to test the preview!");
		return PLUGIN_HANDLED;
	}

	if (g_iUserEntityIndex[id] != 0)
	{
		safelyRemoveEntity(id);
		client_print(id, print_chat, "Preview removed.");
		return PLUGIN_HANDLED;
	}

	new menu = menu_create("Skin Preview Menu", "menu_handler");
	new szMenuItem[128], szData[6];
	for (new i = 0; i < SKINS_NUM; i++)
	{
		formatex(szMenuItem, charsmax(szMenuItem), "%s (Submodel: %d)", g_Skins[i][szName], g_Skins[i][iSubmodel]);
		formatex(szData, charsmax(szData), "%d", i);
		menu_additem(menu, szMenuItem, szData);
	}

	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);

	return PLUGIN_HANDLED;
}

public menu_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new szData[6], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);
	new iChoice = str_to_num(szData);

	menu_destroy(menu);

	if (!is_user_alive(id))
	{
		client_print(id, print_chat, "You need to be alive to show the preview!");
		return PLUGIN_HANDLED;
	}

	safelyRemoveEntity(id); // Remove previous preview
	new iEnt = createEntityModel(id, g_Skins[iChoice][szModel], g_Skins[iChoice][iSubmodel]);
	if (iEnt > 0)
	{
		g_iUserEntityIndex[id] = iEnt;
		client_print(id, print_chat, "Showing preview of %s (submodel %d). Preview will be removed in %.0f seconds.", 
			g_Skins[iChoice][szName], g_Skins[iChoice][iSubmodel], PREVIEW_TIME);
		
		// Store the start time of the preview
		g_fPreviewStartTime[id] = get_gametime();
		
		// Set repeating task to display countdown on center screen and handle removal
		g_iPreviewTask[id] = set_task(1.0, "update_preview_timer", id, _, _, "b");
		
		show_preview_control_menu(id);
	}
	else
	{
		client_print(id, print_chat, "Failed to show preview!");
	}
	return PLUGIN_HANDLED;
}

// Function to create the preview entity
createEntityModel(id, const model[], submodel)
{
	new iEnt = create_entity("info_target");
	if (!pev_valid(iEnt))
		return 0;

	// Set the model
	engfunc(EngFunc_SetModel, iEnt, model);

	// Set the submodel if applicable
	if (submodel > 0)
	{
		set_pev(iEnt, pev_body, submodel);
	}

	// Make the entity visible
	set_pev(iEnt, pev_rendermode, kRenderNormal);
	set_pev(iEnt, pev_renderamt, 255.0);
	set_pev(iEnt, pev_movetype, MOVETYPE_NOCLIP);
	set_pev(iEnt, pev_classname, MODEL_CLASSNAME);
	set_pev(iEnt, pev_iuser1, id);

	// Adjust entity size using pev_scale
	set_pev(iEnt, pev_scale, 2.0);

	// Set initial position and start the thinker
	updateEntityPosition(id, iEnt);
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1);

	return iEnt;
}

// Function to update the entity position based on aim
public think_preview(iEnt)
{
	if (!pev_valid(iEnt))
		return;

	new id = pev(iEnt, pev_iuser1);
	if (!is_user_alive(id) || g_iUserEntityIndex[id] != iEnt)
	{
		remove_entity(iEnt);
		g_iUserEntityIndex[id] = 0;
		return;
	}

	// Update position to follow aim
	updateEntityPosition(id, iEnt);

	// Automatic rotation
	static Float:fFloatVector[3];
	fFloatVector[1] = 30.0;
	set_pev(iEnt, pev_avelocity, fFloatVector);

	// Set next think time
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1);
}

// Function to show the preview control menu
public show_preview_control_menu(id)
{
	new control_menu = menu_create("Preview Control Menu", "preview_control_handler");
	menu_additem(control_menu, "Move Closer", "1");
	menu_additem(control_menu, "Move Away", "2");
	menu_additem(control_menu, "Remove Preview", "3");
	menu_setprop(control_menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, control_menu, 0);
}

public preview_control_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	if (!is_user_alive(id) || !g_iUserEntityIndex[id])
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new iEnt = g_iUserEntityIndex[id];
	if (!pev_valid(iEnt))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new szData[2], iAccess, iCallback;
	menu_item_getinfo(menu, item, iAccess, szData, charsmax(szData), _, _, iCallback);
	new iChoice = str_to_num(szData);

	switch (iChoice)
	{
		case 1: // Move Closer
		{
			g_fPreviewDistance[id] -= 5.0;
			if (g_fPreviewDistance[id] < 20.0)
				g_fPreviewDistance[id] = 20.0;
			updateEntityPosition(id, iEnt);
			client_print(id, print_chat, "Preview moved closer. Distance: %.1f", g_fPreviewDistance[id]);
		}
		case 2: // Move Away
		{
			g_fPreviewDistance[id] += 5.0;
			if (g_fPreviewDistance[id] > 70.0)
				g_fPreviewDistance[id] = 70.0;
			updateEntityPosition(id, iEnt);
			client_print(id, print_chat, "Preview moved away. Distance: %.1f", g_fPreviewDistance[id]);
		}
		case 3: // Remove Preview
		{
			// Remove the automatic removal task
			if (g_iPreviewTask[id])
			{
				remove_task(g_iPreviewTask[id]);
				g_iPreviewTask[id] = 0;
			}
			safelyRemoveEntity(id);
			client_print(id, print_chat, "Preview removed.");
		}
	}

	// Reopen the menu unless they chose to remove the preview
	iChoice != 3 ? show_preview_control_menu(id) : menu_destroy(menu);

	return PLUGIN_HANDLED;
}

// Function to display remaining preview time on center screen and handle removal
public update_preview_timer(id)
{
	if (!is_user_alive(id) || !g_iUserEntityIndex[id])
	{
		if (g_iPreviewTask[id])
		{
			remove_task(g_iPreviewTask[id]);
			g_iPreviewTask[id] = 0;
		}
		safelyRemoveEntity(id);
		return;
	}

	// Calculate remaining time based on start time
	new Float:timeleft = PREVIEW_TIME - (get_gametime() - g_fPreviewStartTime[id]);
	if (timeleft <= 0.0)
	{
		// Time is up, remove preview
		if (g_iPreviewTask[id])
		{
			remove_task(g_iPreviewTask[id]);
			g_iPreviewTask[id] = 0;
		}
		safelyRemoveEntity(id);
		client_print(id, print_chat, "Preview automatically removed after %.0f seconds.", PREVIEW_TIME);
		return;
	}

	// Round the remaining time to the nearest integer (seconds only)
	new seconds = floatround(timeleft);
	
	// Display remaining time on center screen
	client_print(id, print_center, "Display time remaining: %d", seconds);
}

// Function to calculate and update the entity position
updateEntityPosition(id, iEnt)
{
	new Float:fOrigin[3], Float:fEnd[3], Float:fAngles[3], Float:fViewOfs[3];

	// Get player position (eye position)
	pev(id, pev_origin, fOrigin);
	pev(id, pev_view_ofs, fViewOfs);
	fOrigin[0] += fViewOfs[0];
	fOrigin[1] += fViewOfs[1];
	fOrigin[2] += fViewOfs[2];

	// Get player's aim angles
	pev(id, pev_v_angle, fAngles);

	// Calculate point based on current distance
	engfunc(EngFunc_MakeVectors, fAngles);
	global_get(glb_v_forward, fEnd);

	fEnd[0] = fOrigin[0] + fEnd[0] * g_fPreviewDistance[id];
	fEnd[1] = fOrigin[1] + fEnd[1] * g_fPreviewDistance[id];
	fEnd[2] = fOrigin[2] + fEnd[2] * g_fPreviewDistance[id];

	// Move entity to calculated position
	engfunc(EngFunc_SetOrigin, iEnt, fEnd);
}

public client_disconnected(id)
{
	safelyRemoveEntity(id);
	if (g_iPreviewTask[id])
	{
		remove_task(g_iPreviewTask[id]);
		g_iPreviewTask[id] = 0;
	}
}

// Function to remove preview entity
safelyRemoveEntity(id)
{
	new iEnt = g_iUserEntityIndex[id];
	if (iEnt && pev_valid(iEnt))
	{
		remove_entity(iEnt);
	}
	g_iUserEntityIndex[id] = 0;
}