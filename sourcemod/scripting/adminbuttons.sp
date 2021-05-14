#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "Admin Buttons",
	author = "PikaJew",
	description = "List map buttons in the admin menu",
	version = "1.5",
	url = "https://steamcommunity.com/id/AWildPikaJew/"
};

StringMap g_Buttons;

enum struct Button
{
	int index;
	float loc[3];
	char name[64];
}

public void OnPluginStart()
{
	RegAdminCmd("sm_buttons", ButtonMenu, ADMFLAG_GENERIC, "Allows admin to activate any button on the map");
	RegAdminCmd("sm_tpbuttons", TPButtonMenu, ADMFLAG_GENERIC, "Allows admin to teleport to any button on the map");
	RegAdminCmd("sm_buttonlist", PrintAllButtons, ADMFLAG_CHANGEMAP, "List all button names on the map");
	RegAdminCmd("sm_buttonadd", AddButtonToList, ADMFLAG_CHANGEMAP, "Allows root admin to add a search term and redo the button search for that term");
}

public void OnMapStart()
{
	CreateButtonList();
}

public Action AddButtonToList(int iClient, int iArgs)
{
	char arg[64];
	char name[64];
	int index = -1;
	
	if (iArgs < 1)
	{
		PrintToChat(iClient, "[AB] Usage: /buttonadd <substring to find>")
	}
	GetCmdArg(1, arg, sizeof(arg));

	while ((index = FindEntityByClassname(index, "func_button")) != -1)
	{
		GetEntPropString(index, Prop_Data, "m_iName", name, sizeof(name));
		if (StrContains(name, arg, false) != -1)
		{
			Button button;
			strcopy(button.name, sizeof(button.name), name);
			PrintToChat(iClient, "Found %s in %s", arg, button.name);
			button.index = index;
			GetEntPropVector(index, Prop_Send, "m_vecOrigin", button.loc);
			Format(button.name, sizeof(button.name), "(%i) %s", index, button.name);
			g_Buttons.SetArray(button.name, button, sizeof(button));
		}
	}
}

public Action PrintAllButtons(int iClient, int iArgs)
{
	char name[64];
	int index = -1;
	while ((index = FindEntityByClassname(index, "func_button")) != -1)
	{
		GetEntPropString(index, Prop_Data, "m_iName", name, sizeof(name));
		PrintToChat(iClient, name);
		PrintToConsole(iClient, name);
	}
}

public Action CreateButtonList()
{
	delete g_Buttons;
	g_Buttons = new StringMap();

	char name[64]
	int index = -1;

	char path[PLATFORM_MAX_PATH];
	char line[64];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"/configs/admin_buttons.txt");

	File file = OpenFile(path,"r"); // Opens addons/sourcemod/configs/admin_buttons.txt to read from (and only reading)
	
	while ((index = FindEntityByClassname(index, "func_button")) != -1)
	{
		GetEntPropString(index, Prop_Data, "m_iName", name, sizeof(name));

		file.Seek(0, SEEK_SET);

		while(!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
		{
			TrimString(line);
			if (StrContains(name, line, false) != -1)
			{
				Button button;

				strcopy(button.name, sizeof(button.name), name);
				button.index = index;
				GetEntPropVector(index, Prop_Send, "m_vecOrigin", button.loc);

				Format(button.name, sizeof(button.name), "(%i) %s", index, button.name);

				g_Buttons.SetArray(button.name, button, sizeof(button));
			}
		}
	}
	file.Close();
}

public Action ButtonMenu(int iClient, int iArgs)
{
	Menu menu = new Menu(ActivateHandler);
	menu.SetTitle("Press Button:");

	StringMapSnapshot snap = g_Buttons.Snapshot();

	for (int i = 0; i < snap.Length; i++)
	{
		char key[64];
		snap.GetKey(i, key, sizeof(key));
		menu.AddItem(key, key);
	}

	menu.ExitButton = true;
	menu.Display(iClient, 60);
 
	return Plugin_Handled;
}

public Action TPButtonMenu(int iClient, int iArgs)
{
	Menu menu = new Menu(TeleportHandler);
	menu.SetTitle("Teleport To Button:");

	StringMapSnapshot snap = g_Buttons.Snapshot();

	for (int i = 0; i < snap.Length; i++)
	{
		char key[64];
		snap.GetKey(i, key, sizeof(key));
		menu.AddItem(key, key);
	}

	menu.ExitButton = true;
	menu.Display(iClient, 60);
 
	return Plugin_Handled;
}

public int ActivateHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sCName[64];
			GetClientName(param1, sCName, sizeof(sCName));
			
			char sBName[64];
			menu.GetItem(param2, sBName, sizeof(sBName));

			Button button;
			g_Buttons.GetArray(sBName, button, sizeof(button));

			PrintToChatAll("[SM] Admin %s pressed button %s", sCName, sBName);
			AcceptEntityInput(button.index, "Use", param1);
			ButtonMenu(param1, 0);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public int TeleportHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sBName[64];
			menu.GetItem(param2, sBName, sizeof(sBName));
			Button button;
			g_Buttons.GetArray(sBName, button, sizeof(button));

			PrintToChat(param1, "[SM] You teleported to button %s", sBName);
			
			TeleportEntity(param1, button.loc, NULL_VECTOR, NULL_VECTOR);
			TPButtonMenu(param1, 0);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}