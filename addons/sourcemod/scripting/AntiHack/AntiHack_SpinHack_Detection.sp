// AntiHack_SpinHack_Detection.sp

public SpinHack_Detection_OnPluginStart()
{
	CreateTimer(1.0, Timer_CheckSpins, _, TIMER_REPEAT);
}

public SpinHack_Detection_OnClientDisconnect(client)
{
	g_iSpinCount[client] = 0;
	g_fSensitivity[client] = 0.0;
}

public Action:Timer_CheckSpins(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}

		if (g_fAngleDiff[i] > SPIN_ANGLE_CHANGE && IsPlayerAlive(i))
		{
			g_iSpinCount[i]++;

			if (g_iSpinCount[i] == 1)
			{
				QueryClientConVar(i, "sensitivity", Query_MouseCheck, GetClientUserId(i));
			}

			if (g_iSpinCount[i] == SPIN_DETECTIONS && g_fSensitivity[i] <= SPIN_SENSITIVITY)
			{
				Spinhack_Detected(i);
			}
		}
		else
		{
			g_iSpinCount[i] = 0;
		}

		g_fAngleDiff[i] = 0.0;
	}

	return Plugin_Continue;
}

public Query_MouseCheck(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:userid)
{
	if (result == ConVarQuery_Okay && GetClientOfUserId(userid) == client)
	{
		g_fSensitivity[client] = StringToFloat(cvarValue);
	}
}

public Action:SpinHack_Detection_OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!(buttons & IN_LEFT || buttons & IN_RIGHT))
	{
		// Only checking the Z axis here.
		g_fAngleBuffer = FloatAbs(angles[1] - g_fPrevAngle[client]);
		g_fAngleDiff[client] += (g_fAngleBuffer > 180.0) ? (g_fAngleBuffer - 360.0) * -1.0 : g_fAngleBuffer;
		g_fPrevAngle[client] = angles[1];
	}

	return Plugin_Continue;
}

Spinhack_Detected(client)
{
	decl String:sClientName[128];
	GetClientName(client,sClientName,sizeof(sClientName));

	decl String:sSteamID[64],String:sSteamID2[64];

	GetClientAuthString(client, sSteamID2, sizeof(sSteamID2));
	strcopy(sSteamID, sizeof(sSteamID), sSteamID2);
	if(GAMETF)
	{
		if(Convert_UniqueID_TO_SteamID(sSteamID2))
		{
			NotifyAdmins("%s %s %s is suspected of using a spinhack.", sClientName, sSteamID, sSteamID2);
			AntiHackLog("%s %s %s is suspected of using a spinhack.", sClientName, sSteamID, sSteamID2);
		}
		else if(Convert_SteamID_TO_UniqueID(sSteamID2))
		{
			NotifyAdmins("%s %s %s is suspected of using a spinhack.", sClientName, sSteamID, sSteamID2);
			AntiHackLog("%s %s %s is suspected of using a spinhack.", sClientName, sSteamID, sSteamID2);
		}
		else
		{
			NotifyAdmins("%s %s is suspected of using a spinhack.", sClientName, sSteamID);
			AntiHackLog("%s %s is suspected of using a spinhack.", sClientName, sSteamID);
		}
	}
	else
	{
		NotifyAdmins("%s %s is suspected of using a spinhack.", sClientName, sSteamID);
		AntiHackLog("%s %s is suspected of using a spinhack.", sClientName, sSteamID);
	}

	if(g_bCrash_OnSpinHack)
	{
		CrashClient(client);
		AntiHackLog("%s %s >> Crashed Client", sClientName, sSteamID);
	}
}
