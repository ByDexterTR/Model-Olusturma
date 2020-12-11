#include <sourcemod>
#include <sdktools>
#include <warden>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Araç Modeli Oluşturma", 
	author = "quantum. - ByDexter", 
	description = "", 
	version = "1.0", 
	url = "http://plugimerkezi.com/"
};

int Koyulanarac = 0;
bool aracModel = true;
ConVar g_aracyetki = null, g_aracsinir = null;

public void OnPluginStart()
{
	RegConsoleCmd("sm_arac", Command_arac);
	RegConsoleCmd("sm_aracm", Command_arac);
	HookEvent("round_start", RoundStartEnd);
	HookEvent("round_end", RoundStartEnd);
	g_aracyetki = CreateConVar("sm_arac_flag", "f", "Komutçu harici Araç oluşturabilecek yetkiler", FCVAR_NOTIFY);
	g_aracsinir = CreateConVar("sm_arac_max", "64", "En fazla kaç tane Araç oluşturulsun?", 0, true, 1.0);
	AutoExecConfig(true, "arac", "ByDexter");
}

public void OnMapStart()
{
	Koyulanarac = 0;
	PrecacheAndMaterialDownloader("models/prop_vehicles/flatnose_truck");
	PrecacheAndMaterialDownloader("models/prop_vehicles/4carz1024");
	AddFileToDownloadsTable("materials/models/prop_vehicles/4carz1024_envmask.vtf");
	PrecacheAndModelDownloader("dexter/props_vehicles/longnose_truck");
	PrecacheAndModelDownloader("dexter/props_vehicles/cara_95sedan");
}

public void OnPluginEnd()
{
	char ModelPath[PLATFORM_MAX_PATH];
	for (int i = MaxClients; i < GetMaxEntities(); i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", ModelPath, sizeof(ModelPath));
			if (StrContains(ModelPath, "dexter/props_vehicles/longnose_truck") != -1 || StrContains(ModelPath, "dexter/props_vehicles/cara_95sedan") != -1)
			{
				RemoveEntity(i);
			}
		}
	}
}

public Action Command_arac(int client, int args)
{
	if (IsClientInGame(client))
	{
		char Yetki[4];
		g_aracyetki.GetString(Yetki, sizeof(Yetki));
		if (warden_iswarden(client) || CheckAdminFlag(client, Yetki))
		{
			aracMenu().Display(client, MENU_TIME_FOREVER);
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

Menu aracMenu()
{
	Menu menu = new Menu(Menu_CallBack);
	menu.SetTitle("▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬\n        ★ Araç Olşturma ★\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
	menu.AddItem("1", "→ Oluştur");
	menu.AddItem("2", "→ Sil");
	menu.AddItem("3", "→ Hepsini Sil");
	if (aracModel)
		menu.AddItem("0", "→ Model Değiştir\n4. → Model: Araba\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
	else
		menu.AddItem("0", "→ Model Değiştir\n4. → Model: Tır\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
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
			if (aracModel)
				aracModel = false;
			else
				aracModel = true;
			aracMenu().Display(client, MENU_TIME_FOREVER);
		}
		else if (strcmp(Item, "1", false) == 0)
		{
			if (Koyulanarac >= g_aracsinir.IntValue)
			{
				PrintToChat(client, "[SM] Araç oluşturulmadı: Araç sınırı dolmuş.");
			}
			else
			{
				float origin[3] = 0.0;
				GetAimCoords(client, origin);
				int Ent = CreateEntityByName("prop_physics_override");
				if (IsValidEntity(Ent))
				{
					DispatchKeyValue(Ent, "physdamagescale", "0.0");
					
					if (aracModel)
						DispatchKeyValue(Ent, "model", "models/dexter/props_vehicles/cara_95sedan.mdl");
					else
						DispatchKeyValue(Ent, "model", "models/dexter/props_vehicles/longnose_truck.mdl");
					
					DispatchSpawn(Ent);
					SetEntityMoveType(Ent, MOVETYPE_PUSH);
					float vAngles[3] = 0.0;
					GetEntPropVector(Ent, Prop_Data, "m_angRotation", vAngles);
					float iView[3] = 0.0;
					GetClientEyeAngles(client, iView);
					vAngles[1] = iView[1];
					TeleportEntity(Ent, origin, vAngles, NULL_VECTOR);
					Koyulanarac++;
				}
				else
				{
					Ent = 0;
					PrintToChat(client, "[SM] Araç oluşturulmadı: Hata algılanıd, tekrar deneyin.");
				}
			}
			aracMenu().Display(client, MENU_TIME_FOREVER);
		}
		else if (strcmp(Item, "2", false) == 0)
		{
			int ent = GetClientAimTarget(client, false);
			if (IsValidEntity(ent))
			{
				char ModelPath[PLATFORM_MAX_PATH];
				GetEntPropString(ent, Prop_Data, "m_ModelName", ModelPath, sizeof(ModelPath));
				if (StrContains(ModelPath, "dexter/props_vehicles/longnose_truck") != -1 || StrContains(ModelPath, "dexter/props_vehicles/cara_95sedan") != -1)
				{
					RemoveEntity(ent);
					Koyulanarac--;
				}
			}
			aracMenu().Display(client, MENU_TIME_FOREVER);
		}
		else if (strcmp(Item, "3", false) == 0)
		{
			char ModelPath[PLATFORM_MAX_PATH];
			for (int i = MaxClients; i < GetMaxEntities(); i++)
			{
				if (IsValidEdict(i) && IsValidEntity(i))
				{
					GetEntPropString(i, Prop_Data, "m_ModelName", ModelPath, sizeof(ModelPath));
					if (StrContains(ModelPath, "dexter/props_vehicles/longnose_truck") != -1 || StrContains(ModelPath, "dexter/props_vehicles/cara_95sedan") != -1)
					{
						RemoveEntity(i);
					}
				}
			}
			Koyulanarac = 0;
			aracMenu().Display(client, MENU_TIME_FOREVER);
		}
		else if (strcmp(Item, "4", false) == 0)
		{
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
			if (StrContains(ModelPath, "dexter/props_vehicles/longnose_truck") != -1 || StrContains(ModelPath, "dexter/props_vehicles/cara_95sedan") != -1)
			{
				RemoveEntity(i);
			}
		}
	}
	Koyulanarac = 0;
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