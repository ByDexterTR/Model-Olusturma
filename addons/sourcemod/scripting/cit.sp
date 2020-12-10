#include <sourcemod>
#include <sdktools>
#include <warden>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Çit Modeli Oluşturma", 
	author = "quantum. - ByDexter", 
	description = "", 
	version = "1.1", 
	url = "http://plugimerkezi.com/"
};

int CitModel = 0, Koyulancit = 0;
ConVar g_cityetki = null, g_citsinir = null;

public void OnPluginStart()
{
	RegConsoleCmd("sm_cit", Command_Cit);
	RegConsoleCmd("sm_citm", Command_Cit);
	HookEvent("round_start", RoundStartEnd);
	HookEvent("round_end", RoundStartEnd);
	g_cityetki = CreateConVar("sm_cit_flag", "f", "Komutçu harici çit oluşturabilecek yetkiler", FCVAR_NOTIFY);
	g_citsinir = CreateConVar("sm_cit_max", "64", "En fazla kaç tane çit oluşturulsun?", 0, true, 1.0);
	AutoExecConfig(true, "Cit", "ByDexter");
}

public void OnMapStart()
{
	Koyulancit = 0;
	PrecacheAndMaterialDownloader("models/fortnite/brick_wall");
	PrecacheAndMaterialDownloader("models/fortnite/metal_ramp");
	PrecacheAndMaterialDownloader("models/fortnite/wood_wall");
	PrecacheAndModelDownloader("dexter/fortnite/brick_wall");
	PrecacheAndModelDownloader("dexter/fortnite/metal_wall");
	PrecacheAndModelDownloader("dexter/fortnite/wood_wall");
}

public void OnPluginEnd()
{
	char ModelPath[PLATFORM_MAX_PATH];
	for (int i = MaxClients; i < GetMaxEntities(); i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", ModelPath, sizeof(ModelPath));
			if (StrContains(ModelPath, "dexter/fortnite/brick_wall") != -1 || StrContains(ModelPath, "dexter/fortnite/metal_wall") != -1 || StrContains(ModelPath, "dexter/fortnite/wood_wall") != -1)
			{
				RemoveEntity(i);
			}
		}
	}
}

public Action Command_Cit(int client, int args)
{
	if (IsClientInGame(client))
	{
		char Yetki[4];
		g_cityetki.GetString(Yetki, sizeof(Yetki));
		if (warden_iswarden(client) || CheckAdminFlag(client, Yetki))
		{
			CitMenu().Display(client, MENU_TIME_FOREVER);
			return Plugin_Handled;
		}
		else
		{
			PrintToChat(client, "[SM] Bu menüye erişiminiz yok.");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

Menu CitMenu()
{
	Menu menu = new Menu(Menu_CallBack);
	menu.SetTitle("▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬\n         ★ Çit Olşturma ★\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
	menu.AddItem("1", "→ Oluştur");
	menu.AddItem("2", "→ Sil");
	menu.AddItem("3", "→ Hepsini Sil");
	if (CitModel == 0)
		menu.AddItem("0", "→ Model Değiştir\n4. → Model: Fortnite Odun\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
	else if (CitModel == 1)
		menu.AddItem("0", "→ Model Değiştir\n4. → Model: Fortnite Metal\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
	else if (CitModel == 2)
		menu.AddItem("0", "→ Model Değiştir\n4. → Model: Fortnite Tuğla\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
	menu.AddItem("4", "→ Kapat");
	menu.ExitBackButton = false;
	menu.ExitButton = false;
	return menu;
}

public int Menu_CallBack(Menu menu, MenuAction action, int client, int Position)
{
	if (action == MenuAction_Select)
	{
		char Item[4];
		menu.GetItem(Position, Item, sizeof(Item));
		if (strcmp(Item, "0", false) == 0)
		{
			CitModel++;
			if (CitModel == 3)
				CitModel = 0;
			CitMenu().Display(client, MENU_TIME_FOREVER);
		}
		else if (strcmp(Item, "1", false) == 0)
		{
			if (Koyulancit >= g_citsinir.IntValue)
			{
				PrintToChat(client, "[SM] Çit oluşturulmadı: Çit sınırı dolmuş.");
			}
			else
			{
				float origin[3] = 0.0;
				GetAimCoords(client, origin);
				int Ent = CreateEntityByName("prop_physics_override");
				if (IsValidEntity(Ent))
				{
					DispatchKeyValue(Ent, "physdamagescale", "0.0");
					
					if (CitModel == 0)
						DispatchKeyValue(Ent, "model", "models/dexter/fortnite/wood_wall.mdl");
					else if (CitModel == 1)
						DispatchKeyValue(Ent, "model", "models/dexter/fortnite/metal_wall.mdl");
					else if (CitModel == 2)
						DispatchKeyValue(Ent, "model", "models/dexter/fortnite/brick_wall.mdl");
					
					DispatchSpawn(Ent);
					SetEntityMoveType(Ent, MOVETYPE_PUSH);
					float vAngles[3] = 0.0;
					GetEntPropVector(Ent, Prop_Data, "m_angRotation", vAngles);
					float iView[3] = 0.0;
					GetClientEyeAngles(client, iView);
					vAngles[1] = iView[1];
					TeleportEntity(Ent, origin, vAngles, NULL_VECTOR);
					Koyulancit++;
				}
				else
				{
					Ent = 0;
					PrintToChat(client, "[SM] Çit oluşturulmadı: Hata algılanıd, tekrar deneyin.");
				}
			}
			CitMenu().Display(client, MENU_TIME_FOREVER);
		}
		else if (strcmp(Item, "2", false) == 0)
		{
			int ent = GetClientAimTarget(client, false);
			if (IsValidEntity(ent))
			{
				char ModelPath[PLATFORM_MAX_PATH];
				GetEntPropString(ent, Prop_Data, "m_ModelName", ModelPath, sizeof(ModelPath));
				if (StrContains(ModelPath, "dexter/fortnite/brick_wall") != -1 || StrContains(ModelPath, "dexter/fortnite/metal_wall") != -1 || StrContains(ModelPath, "dexter/fortnite/wood_wall") != -1)
				{
					RemoveEntity(ent);
					Koyulancit--;
				}
			}
			CitMenu().Display(client, MENU_TIME_FOREVER);
		}
		else if (strcmp(Item, "3", false) == 0)
		{
			char ModelPath[PLATFORM_MAX_PATH];
			for (int i = MaxClients; i < GetMaxEntities(); i++)
			{
				if (IsValidEdict(i) && IsValidEntity(i))
				{
					GetEntPropString(i, Prop_Data, "m_ModelName", ModelPath, sizeof(ModelPath));
					if (StrContains(ModelPath, "dexter/fortnite/brick_wall") != -1 || StrContains(ModelPath, "dexter/fortnite/metal_wall") != -1 || StrContains(ModelPath, "dexter/fortnite/wood_wall") != -1)
					{
						RemoveEntity(i);
					}
				}
			}
			Koyulancit = 0;
			CitMenu().Display(client, MENU_TIME_FOREVER);
		}
		else if (strcmp(Item, "4", false) == 0)
		{
			delete menu;
			return;
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action RoundStartEnd(Event event, const char[] name, bool dontBroadcast)
{
	char ModelPath[PLATFORM_MAX_PATH];
	for (int i = MaxClients; i < GetMaxEntities(); i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", ModelPath, sizeof(ModelPath));
			if (StrContains(ModelPath, "dexter/fortnite/brick_wall") != -1 || StrContains(ModelPath, "dexter/fortnite/metal_wall") != -1 || StrContains(ModelPath, "dexter/fortnite/wood_wall") != -1)
			{
				RemoveEntity(i);
			}
		}
	}
	Koyulancit = 0;
}

public void GetAimCoords(int client, float vector[3])
{
	float vAngles[3];
	float vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(trace))
		TR_GetEndPosition(vector, trace);
	trace.Close();
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients;
}

stock bool CheckAdminFlag(int client, const char[] flags)
{
	int iCount = 0;
	char sflagNeed[22][8], sflagFormat[64];
	bool bEntitled = false;
	
	Format(sflagFormat, sizeof(sflagFormat), flags);
	ReplaceString(sflagFormat, sizeof(sflagFormat), " ", "");
	iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[]));
	
	for (int i = 0; i < iCount; i++)
	{
		if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i]) == ReadFlagString(sflagNeed[i])) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			bEntitled = true;
			break;
		}
	}
	return bEntitled;
}

stock void PrecacheAndMaterialDownloader(char[] sMaterialname)
{
	char sBuffer[256];
	Format(sBuffer, sizeof(sBuffer), "materials/%s.vmt", sMaterialname);
	AddFileToDownloadsTable(sBuffer);
	Format(sBuffer, sizeof(sBuffer), "materials/%s.vtf", sMaterialname);
	AddFileToDownloadsTable(sBuffer);
}

stock void PrecacheAndModelDownloader(char[] sModelname)
{
	char sBuffer[256];
	Format(sBuffer, sizeof(sBuffer), "models/%s.dx90.vtx", sModelname);
	AddFileToDownloadsTable(sBuffer);
	Format(sBuffer, sizeof(sBuffer), "models/%s.mdl", sModelname);
	PrecacheModel(sBuffer);
	AddFileToDownloadsTable(sBuffer);
	Format(sBuffer, sizeof(sBuffer), "models/%s.phy", sModelname);
	AddFileToDownloadsTable(sBuffer);
	Format(sBuffer, sizeof(sBuffer), "models/%s.vvd", sModelname);
	AddFileToDownloadsTable(sBuffer);
} 