public Plugin myinfo = {
	name = "Private Messages",
	author = "Mozze",
	description = "",
	version = "1.0",
	url = "t.me/pMozze"
};

char g_szMessage[66][256];
int g_iMessageTo[66];
bool g_bSayHook[66];

public void OnPluginStart() {
	LoadTranslations("privatemessages.phrases");
	AddCommandListener(sayHook, "say");
	AddCommandListener(sayHook, "say_team");
	RegConsoleCmd("sm_pm", privateMessageCommand);
}

public void OnClientPutInServer(int iClient) {
	g_iMessageTo[iClient] = 0;
	g_bSayHook[iClient] = false;
	Format(g_szMessage[iClient], 256, "\0");
}

public Action sayHook(int iClient, const char[] szCommand, int iArgs) {
	if (g_bSayHook[iClient]) {
		g_bSayHook[iClient] = false;

		if (!IsClientInGame(g_iMessageTo[iClient])) {
			PrintToChat(iClient, "%t%t", "Prefix", "The player left the server");
			return Plugin_Stop;
		}

		char szMessage[256];
		GetCmdArgString(szMessage, sizeof(szMessage));

		StripQuotes(szMessage);
		TrimString(szMessage);

		Format(g_szMessage[iClient], 256, szMessage);
		showMessagePanel(iClient, szMessage);

		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public Action privateMessageCommand(int iClient, int iArgs) {
	char
		szClientName[128],
		szClientID[3];

	Menu
		hMenu;

	hMenu = CreateMenu(menuHandler);
	hMenu.SetTitle("%t", "Menu title");

	for (int iClientIndex = 1; iClientIndex <= MaxClients; iClientIndex++) {
		if (IsClientInGame(iClientIndex) && iClientIndex != iClient) {
			GetClientName(iClientIndex, szClientName, sizeof(szClientName));
			IntToString(iClientIndex, szClientID, sizeof(szClientID));
			hMenu.AddItem(szClientID, szClientName);
		}
	}

	hMenu.Display(iClient, 0);
}

public int menuHandler(Menu hMenu, MenuAction iAction, int iClient, int iItem) {
	switch (iAction) {
		case MenuAction_Select: {
			char szClientID[3];
			hMenu.GetItem(iItem, szClientID, sizeof(szClientID));

			g_iMessageTo[iClient] = StringToInt(szClientID);
			g_bSayHook[iClient] = true;
		}

		case MenuAction_End:
			delete hMenu;
	}
}

public void showMessagePanel(int iClient, const char[] szMessage) {
	Panel hPanel = CreatePanel(null);
	char szBuffer[512];

	Format(szBuffer, sizeof(szBuffer), "%t", "Panel title", g_iMessageTo[iClient]);
	hPanel.SetTitle(szBuffer);

	Format(szBuffer, sizeof(szBuffer), " \n%s\n ", szMessage);
	hPanel.DrawText(szBuffer);

	Format(szBuffer, sizeof(szBuffer), "%t", "Panel submit");
	hPanel.DrawItem(szBuffer);

	Format(szBuffer, sizeof(szBuffer), "%t", "Panel cancel");
	hPanel.DrawItem(szBuffer);

	hPanel.Send(iClient, messagePanelHandler, 0);
}

public int messagePanelHandler(Menu hMenu, MenuAction iAction, int iClient, int iItem) {
	switch (iAction) {
		case MenuAction_Select: {
			switch (iItem) {
				case 1: {
					if (IsClientInGame(g_iMessageTo[iClient])) {
						PrintToChat(g_iMessageTo[iClient], "%t%t", "Prefix", "Private message", iClient);
						PrintToChat(g_iMessageTo[iClient], "%t%s", "Prefix", g_szMessage[iClient]);
						PrintToChat(iClient, "%t%t", "Prefix", "Private message sended", g_iMessageTo[iClient]);

						for (int iClientIndex = 1; iClientIndex <= MaxClients; iClientIndex++) {
							if (IsClientInGame(iClientIndex) && GetUserFlagBits(iClientIndex)) {
								PrintToChat(iClientIndex, "%t%t", "Prefix", "Private message notify", iClient, g_iMessageTo[iClient]);
								PrintToChat(iClientIndex, "%t%s", "Prefix", g_szMessage[iClient]);
							}
						}
					} else {
						g_iMessageTo[iClient] = 0;
						g_bSayHook[iClient] = false;
						Format(g_szMessage[iClient], 256, "\0");
						PrintToChat(iClient, "%t%t", "Prefix", "The player left the server");
					}
				}

				case 2: {
					g_iMessageTo[iClient] = 0;
					g_bSayHook[iClient] = false;
					Format(g_szMessage[iClient], 256, "\0");
				}
			}
		}

		case MenuAction_End:
			delete hMenu;
	}
}
