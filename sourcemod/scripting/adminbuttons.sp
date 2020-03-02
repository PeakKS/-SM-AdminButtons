#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "Admin Buttons",
	author = "PikaJew",
	description = "List map buttons in the admin menu",
	version = "1.0",
	url = "https://steamcommunity.com/id/AWildPikaJew/"
};

char g_sButtons[512][32];
int g_iButtons[512];
int g_iButNum = 0;

public void OnPluginStart()
{
	RegConsoleCmd("sm_buttonwatchlist", Command_SeeAdminButtonWatchlist, "List all phrases flagged by the Admin Buttons plugin");
	RegConsoleCmd("sm_buttonlist", Command_SeeButtonList, "List all button names on the map");
	RegAdminCmd("sm_buttons", Menu_AdminButtons, ADMFLAG_GENERIC, "Allows admin to activate any buttons on the map");
	RegAdminCmd("sm_buttonadd", AddButtonToList, ADMFLAG_ROOT, "Allows root admin to add a search term and redo the button search for that term");
}

public void OnMapStart()
{
	ClearButtonList();
	CreateButtonList();
}

public Action ClearButtonList()
{
	char sTempArray[32];
	int iTempArray[512];
	for (int i = 0; i < sizeof(g_sButtons); i++)
	{
		g_sButtons[i] = sTempArray;
	}
	g_iButtons = iTempArray;
	g_iButNum = 0;
}

public Action AddButtonToList(int iClient, int iArgs)
{
	char arg[16];
	char name[32];
	int index = -1;
	
	if (iArgs < 1)
	{
		PrintToChat(iClient, "[AB] Usage: /buttonadd <substring to find>")
	}
	GetCmdArg(1, arg, sizeof(arg));
	while ((index = FindEntityByClassname(index, "func_button")) != -1)
	{
		GetEntPropString(index, Prop_Data, "m_iName", name, sizeof(name));
		PrintToChat(iClient, "Searching %s for phrase %s", name, arg);
		if (StrContains(name, arg, false) != -1)
		{
			PrintToChat(iClient, "Found %s in %s", arg, name);
			g_sButtons[g_iButNum] = name;
			g_iButtons[g_iButNum] = index;
			g_iButNum++;
		}
	}
}

public Action Command_SeeButtonList(int iClient, int iArgs)
{
	char name[32];
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
	char name[32];
	int index = -1;
	while ((index = FindEntityByClassname(index, "func_button")) != -1)
	{
		GetEntPropString(index, Prop_Data, "m_iName", name, sizeof(name));
		char path[PLATFORM_MAX_PATH];
		char line[128];
		BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"/configs/admin_buttons.txt");
		Handle fileHandle = OpenFile(path,"r"); // Opens addons/sourcemod/configs/admin_buttons.txt to read from (and only reading)
		while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle, line, sizeof(line)))
		{
			TrimString(line);
			PrintToConsoleAll("Searching %s for phrase %s", name, line);
			if (StrContains(name, line, false) != -1)
			{
				PrintToConsoleAll("Found %s in %s", line, name);
				g_sButtons[g_iButNum] = name;
				g_iButtons[g_iButNum] = index;
				g_iButNum++;
			}
		}
		CloseHandle(fileHandle);
	}
}

public Action Menu_AdminButtons(int iClient, int iArgs)
{
	char sButtonInt[16];
	Menu menu = new Menu(GenericHandler, MENU_ACTIONS_ALL);
	menu.SetTitle("Admin Buttons:");
	for (int i = 0; i <= g_iButNum; i++)
	{
		IntToString(g_iButtons[i], sButtonInt, sizeof(sButtonInt));
		menu.AddItem(sButtonInt, g_sButtons[i]);
	}
	menu.ExitButton = true;
	menu.Display(iClient, 20);
 
	return Plugin_Handled;
}

public int GenericHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			char sCName[16];
			char sBName[16];
			GetClientName(param1, sCName, sizeof(sCName));
			menu.GetItem(param2, info, sizeof(info));
			int iButtonInt = StringToInt(info);
			GetEntPropString(iButtonInt, Prop_Data, "m_iName", sBName, sizeof(sBName));
			PrintToConsoleAll("Client %s pressed button %s", sCName, sBName);
			AcceptEntityInput(iButtonInt, "Use", param1);
			
		}
	}
}

public Action Command_SeeAdminButtonWatchlist(int iClient, int iArgs)
{
	char path[PLATFORM_MAX_PATH];
	char line[128];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"/configs/admin_buttons.txt");
	Handle fileHandle = OpenFile(path,"r"); // Opens addons/sourcemod/configs/admin_buttons.txt to read from (and only reading)
	while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle, line, sizeof(line)))
	{
		PrintToChat(iClient, line);
	}
	CloseHandle(fileHandle);
}