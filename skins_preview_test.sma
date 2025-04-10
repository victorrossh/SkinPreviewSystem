#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>

#define PLUGIN "Skins Preview"
#define VERSION "1.0"
#define AUTHOR "ftl~"

#define MODEL_CLASSNAME "skin_preview"
#define SKINS_NUM 2

// Variable to store the preview entity for each player
new g_iUserEntityIndex[33];

enum eSkin
{
	szName[64],
	szModel[128],
	iSubmodel
}

// Array with test skins
new g_Skins[SKINS_NUM][eSkin] = {
	{"Knife Ahegao", "models/llg2025/v_def_knife.mdl", 26},  // Knife model from shop
	{"USP Abstract Blue", "models/llg2025/v_usp.mdl", 23}    // USP model from shop
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
	for (new i = 0; i < SKINS_NUM; i++)
	{
		precache_model(g_Skins[i][szModel]);
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

	safelyRemoveEntity(id); // Remove preview anterior
	new iEnt = createEntityModel(id, g_Skins[iChoice][szModel], g_Skins[iChoice][iSubmodel]);
	if (iEnt > 0)
	{
		g_iUserEntityIndex[id] = iEnt;
		client_print(id, print_chat, "Showing preview of %s (submodel %d). Use /preview to remove it.", g_Skins[iChoice][szName], g_Skins[iChoice][iSubmodel]);
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

	// Calculate point 30 units ahead in aim direction
	engfunc(EngFunc_MakeVectors, fAngles);
	global_get(glb_v_forward, fEnd);

	fEnd[0] = fOrigin[0] + fEnd[0] * 30.0;
	fEnd[1] = fOrigin[1] + fEnd[1] * 30.0;
	fEnd[2] = fOrigin[2] + fEnd[2] * 30.0;

	// Move entity to calculated position
	engfunc(EngFunc_SetOrigin, iEnt, fEnd);
}

public client_disconnected(id)
{
	safelyRemoveEntity(id);
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