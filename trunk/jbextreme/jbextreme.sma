/*
Changelog:

v1.4
	* Improved team select code
	* Improved team status code
	* Updated dictionary
	* Added custom model (using body+skin)
	* Added sounds
	* Added freeday menu command
	* Added lastrequest menu command & functionalities
	* Added help command
	* Added last prisoner hud message
	* Added cvar to change talk mode control (+simonvoice optional or required to talk)
	* Added cvar to allow shooting func_button to activate it
	* Added cvar to allow auto-freeday hud message after 60 seconds with no Simon selected
	* Added cvar to force round end after some time of auto-freeday
	* Added cvar to change game mode (classic counter for days)
	* Added simon footsteps decals (controlled by cvar)

v1.3
	* First public release
*/

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>
 
#define	PLUGIN_NAME	"JailBreak Extreme"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"1.5"
#define	PLUGIN_CVAR	"jbextreme"

#define TASK_STATUS	2487000
#define TASK_FREEDAY	2487100
#define TASK_ROUND	2487200
#define TASK_HELP	2487300
#define TEAM_MENU	"#Team_Select_Spect"
#define TEAM_MENU2	"#Team_Select_Spect"

#define get_bit(%1,%2) 		( %1 &   1 << ( %2 & 31 ) )
#define set_bit(%1,%2)	 	%1 |=  ( 1 << ( %2 & 31 ) )
#define clear_bit(%1,%2)	%1 &= ~( 1 << ( %2 & 31 ) )

#define vec_len(%1)		floatsqroot(%1[0] * %1[0] + %1[1] * %1[1] + %1[2] * %1[2])
#define vec_mul(%1,%2)		( %1[0] *= %2, %1[1] *= %2, %1[2] *= %2)
#define vec_copy(%1,%2)		( %2[0] = %1[0], %2[1] = %1[1],%2[2] = %1[2])

// Offsets
#define m_iPrimaryWeapon	116
#define m_iVGUI			510
#define m_fGameHUDInitialized	349
 
enum _hud { _hudsync, Float:_x, Float:_y, Float:_time }
enum _lastrequest { _knife, _deagle, _freeday, _weapon }

new gp_PrecacheSpawn
new gp_CrowbarMax
new gp_CrowbarMul
new gp_TeamRatio
new gp_CtMax
new gp_BoxMax
new gp_TalkMode
new gp_VoiceBlock
new gp_RetryTime
new gp_RoundMax
new gp_ButtonShoot
new gp_SimonSteps
new gp_GlowModels

new g_MaxClients
new g_MsgStatusText
new g_MsgStatusIcon
new g_MsgVGUIMenu
new g_MsgShowMenu
new g_MsgClCorpse
new g_MsgMOTD

// Precache
new const _FistModels[][] = { "models/p_bknuckles.mdl", "models/v_bknuckles.mdl" }
new const _CrowbarModels[][] = { "models/p_crowbar.mdl", "models/v_crowbar.mdl" }
new const _FistSounds[][] = { "weapons/cbar_hitbod2.wav", "weapons/cbar_hitbod1.wav", "weapons/bullet_hit1.wav", "weapons/bullet_hit2.wav" }
new const _RemoveEntities[][] = {
	"func_hostage_rescue", "info_hostage_rescue", "func_bomb_target", "info_bomb_target",
	"hostage_entity", "info_vip_start", "func_vip_safetyzone", "func_escapezone"
}

new const _WeaponsFree[][] = { "weapon_scout", "weapon_deagle", "weapon_mac10", "weapon_elite", "weapon_ak47", "weapon_m4a1", "weapon_mp5navy" }
new const _WeaponsFreeCSW[] = { CSW_SCOUT, CSW_DEAGLE, CSW_MAC10, CSW_ELITE, CSW_AK47, CSW_M4A1, CSW_MP5NAVY }
new const _WeaponsGuns[][] = { "weapon_usp", "weapon_deagle", "weapon_glock", "weapon_elite", "weapon_p228", "weapon_fiveseven" }
new const _WeaponsGunsCSW[] = { CSW_USP, CSW_DEAGLE, CSW_GLOCK, CSW_ELITE, CSW_P228, CSW_FIVESEVEN }
new const _WeaponsAmmo[] = { 90, 35, 100, 120, 90, 90, 120 }

// Reasons
new const g_Reasons[][] =  {
	"",
	"JBE_PRISONER_REASON_1",
	"JBE_PRISONER_REASON_2",
	"JBE_PRISONER_REASON_3",
	"JBE_PRISONER_REASON_4",
	"JBE_PRISONER_REASON_5",
	"JBE_PRISONER_REASON_6"
}

// HudSync: 0=ttinfo / 1=info / 2=simon / 3=ctinfo / 4=player / 5=day / 6=center / 7=help
new const g_HudSync[][_hud] =
{
	{0,  0.6,  0.2,  2.0},
	{0, -1.0,  0.7,  5.0},
	{0,  0.1,  0.2,  2.0},
	{0,  0.1,  0.3,  2.0},
	{0, -1.0,  0.9,  3.0},
	{0,  0.6,  0.1,  3.0},
	{0, -1.0, -1.0,  3.0},
	{0,  0.8,  0.3, 20.0}
}

// Colors: 0:Simon / 1:Freeday / 2:CT Duel / 3:TT Duel
new const g_Colors[][3] = { {0, 255, 0}, {255, 140, 0}, {255, 0, 0}, {0, 0, 255} }


new CsTeams:g_PlayerTeam[33]
new g_HelpText[512]
new g_JailDay
new g_PlayerJoin
new g_PlayerReason[33]
new g_PlayerNomic
new g_PlayerWanted
new g_PlayerCrowbar
new g_PlayerRevolt
new g_PlayerHelp
new g_PlayerFreeday
new g_PlayerLast
new g_FreedayAuto
new g_FreedayNext
new g_TeamCount[CsTeams]
new g_TeamAlive[CsTeams]
new g_BoxStarted
new g_CrowbarCount
new g_Simon
new g_SimonAllowed
new g_SimonTalking
new g_SimonVoice
new g_RoundStarted
new g_LastDenied
new g_FreeDay
new g_BlockWeapons
 
public plugin_init()
{
	unregister_forward(FM_Spawn, gp_PrecacheSpawn)
 
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
 
	register_dictionary("jbextreme.txt")

	g_MsgStatusText = get_user_msgid("StatusText")
	g_MsgStatusIcon = get_user_msgid("StatusIcon")
	g_MsgVGUIMenu = get_user_msgid("VGUIMenu")
	g_MsgShowMenu = get_user_msgid("ShowMenu")
	g_MsgMOTD = get_user_msgid("MOTD")
	g_MsgClCorpse = get_user_msgid("ClCorpse")

	register_message(g_MsgStatusText, "msg_statustext")
	register_message(g_MsgStatusIcon, "msg_statusicon")
	register_message(g_MsgVGUIMenu, "msg_vguimenu")
	register_message(g_MsgShowMenu, "msg_showmenu")
	register_message(g_MsgMOTD, "msg_motd")
	register_message(g_MsgClCorpse, "msg_clcorpse")

	register_event("CurWeapon", "current_weapon", "be", "1=1", "2=29")
	register_event("DeathMsg","player_death","a")
	register_event("StatusValue", "player_status", "be", "1=2", "2!0")
	register_event("StatusValue", "player_status", "be", "1=1", "2=0")

	register_impulse(100, "impulse_100")

	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	RegisterHam(Ham_TakeDamage, "player", "player_damage")
	RegisterHam(Ham_TraceAttack, "player", "player_attack")
	RegisterHam(Ham_TraceAttack, "func_button", "button_attack")
	RegisterHam(Ham_Killed, "player", "player_killed", 1)

	register_forward(FM_SetClientKeyValue, "set_client_kv")
	register_forward(FM_EmitSound, "sound_emit")
	register_forward(FM_Voice_SetClientListening, "voice_listening")

	register_logevent("round_end", 2, "1=Round_End")
	register_logevent("round_first", 2, "0=World triggered", "1&Restart_Round_")
	register_logevent("round_first", 2, "0=World triggered", "1=Game_Commencing")
	register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")

	register_menucmd(register_menuid(TEAM_MENU), 51, "team_select") 
	register_menucmd(register_menuid(TEAM_MENU2), 51, "team_select") 

	register_clcmd("jointeam", "cmd_jointeam")
	register_clcmd("joinclass", "cmd_joinclass")
	register_clcmd("+simonvoice", "cmd_voiceon")
	register_clcmd("-simonvoice", "cmd_voiceoff")

	register_clcmd("say /fd", "cmd_freeday")
	register_clcmd("say /freeday", "cmd_freeday")
	register_clcmd("say /day", "cmd_freeday")
	register_clcmd("say /lr", "cmd_lastrequest")
	register_clcmd("say /lastrequest", "cmd_lastrequest")
	register_clcmd("say /duel", "cmd_lastrequest")
	register_clcmd("say /simon", "cmd_simon")
	register_clcmd("say /nomic", "cmd_nomic")
	register_clcmd("say /box", "cmd_box")
	register_clcmd("say /help", "cmd_help")

	register_clcmd("jbe_freeday", "adm_freeday", ADMIN_KICK)
	register_clcmd("jbe_nomic", "adm_nomic", ADMIN_KICK)
	register_clcmd("jbe_box", "adm_box", ADMIN_KICK)
 
	gp_GlowModels = register_cvar("jbe_glowmodels", "0")
	gp_SimonSteps = register_cvar("jbe_simonsteps", "1")
	gp_CrowbarMul = register_cvar("jbe_crowbarmultiplier", "25.0")
	gp_CrowbarMax = register_cvar("jbe_maxcrowbar", "1")
	gp_TeamRatio = register_cvar("jbe_teamratio", "3")
	gp_CtMax = register_cvar("jbe_maxct", "6")
	gp_BoxMax = register_cvar("jbe_boxmax", "6")
	gp_RetryTime = register_cvar("jbe_retrytime", "10")
	gp_RoundMax = register_cvar("jbe_freedayround", "240.0")
	gp_TalkMode = register_cvar("jbe_talkmode", "2")	// 0-alltak / 1-tt
	gp_VoiceBlock = register_cvar("jbe_blockvoice", "1")	// 0-dont block / 1-block voicerecord
	gp_ButtonShoot = register_cvar("jbe_buttonshoot", "1")	// 0-standard / 1-func_button shoots!
 
	g_MaxClients = get_global_int(GL_maxClients)
 
	for(new i = 0; i < sizeof(g_HudSync); i++)
		g_HudSync[i][_hudsync] = CreateHudSyncObj()

	formatex(g_HelpText, charsmax(g_HelpText), "%L^n^n%L^n^n%L^n^n%L",
			LANG_SERVER, "JBE_HELP_TITLE",
			LANG_SERVER, "JBE_HELP_BINDS",
			LANG_SERVER, "JBE_HELP_GUARD_CMDS",
			LANG_SERVER, "JBE_HELP_PRISONER_CMDS")
}
 
public plugin_cfg()
{
	set_cvar_num("sv_alltalk", 1)
	set_cvar_num("mp_limitteams", 0)
	set_cvar_num("mp_autoteambalance", 0)
	set_cvar_num("mp_tkpunish", 0)
	set_cvar_num("mp_friendlyfire", 1)
}

public plugin_precache()
{
	static i
	precache_model("models/player/jbemodel/jbemodel.mdl")
 
	for(i = 0; i < sizeof(_FistModels); i++)
		precache_model(_FistModels[i])
 
	for(i = 0; i < sizeof(_CrowbarModels); i++)
		precache_model(_CrowbarModels[i])
 
	for(i = 0; i < sizeof(_FistSounds); i++)
		precache_sound(_FistSounds[i])

	precache_sound("jbextreme/nm_goodbadugly.wav")
	precache_sound("jbextreme/brass_bell_C.wav")
 
	gp_PrecacheSpawn = register_forward(FM_Spawn, "precache_spawn", 1)
}

public precache_spawn(ent)
{
	if(is_valid_ent(ent))
	{
		static szClass[33]
		entity_get_string(ent, EV_SZ_classname, szClass, sizeof(szClass))
		for(new i = 0; i < sizeof(_RemoveEntities); i++)
			if(equal(szClass, _RemoveEntities[i]))
				remove_entity(ent)
	}
}

public client_putinserver(id)
{
	clear_bit(g_PlayerJoin, id)
	clear_bit(g_PlayerHelp, id)
	clear_bit(g_PlayerCrowbar, id)
	clear_bit(g_PlayerNomic, id)
	clear_bit(g_PlayerWanted, id)
	clear_bit(g_SimonTalking, id)
	clear_bit(g_SimonVoice, id)
}

public client_disconnect(id)
{
	if(g_Simon == id)
	{
		g_Simon = 0
		ClearSyncHud(0, g_HudSync[2][_hudsync])
		player_hudmessage(0, 2, 5.0, _, "%L", LANG_SERVER, "JBE_SIMON_HASGONE")
	}
	team_count()
}

public client_PostThink(id)
{
	if(id != g_Simon || !get_pcvar_num(gp_SimonSteps) || !is_user_alive(id) ||
		!(entity_get_int(id, EV_INT_flags) & FL_ONGROUND) || entity_get_int(id, EV_ENT_groundentity))
		return PLUGIN_CONTINUE
	
	static Float:origin[3]
	static Float:last[3]

	entity_get_vector(id, EV_VEC_origin, origin)
	if(get_distance_f(origin, last) < 32.0)
	{
		return PLUGIN_CONTINUE
	}

	vec_copy(origin, last)
	if(entity_get_int(id, EV_INT_bInDuck))
		origin[2] -= 18.0
	else
		origin[2] -= 36.0


	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, {0,0,0}, 0)
	write_byte(TE_WORLDDECAL)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_byte(105)
	message_end()

	return PLUGIN_CONTINUE
}

 
public msg_statustext(msgid, dest, id)
{
	return PLUGIN_HANDLED
}

public msg_statusicon(msgid, dest, id)
{
	static icon[5] 
	get_msg_arg_string(2, icon, charsmax(icon))
	if(icon[0] == 'b' && icon[2] == 'y' && icon[3] == 'z')
	{
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0))
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public msg_vguimenu(msgid, dest, id)
{
	static msgarg1

	msgarg1 = get_msg_arg_int(1)
	if(msgarg1 == 2)
	{
		if(is_user_alive(id) && (cs_get_user_team(id) == CS_TEAM_T) && !is_user_admin(id))
		{
			client_print(id, print_center, "%L", LANG_SERVER, "JBE_TEAM_CANTCHANGE")
			return PLUGIN_HANDLED
		}
		show_menu(id, 51, TEAM_MENU, -1)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public msg_showmenu(msgid, dest, id)
{
	static msgarg1, roundloop
	msgarg1 = get_msg_arg_int(1)

	if(msgarg1 != 531)
		return PLUGIN_CONTINUE

	roundloop = get_pcvar_num(gp_RetryTime) / 2

	if(is_user_alive(id) && !(g_RoundStarted >= roundloop) && (cs_get_user_team(id) == CS_TEAM_T))
	{
		client_print(id, print_center, "%L", LANG_SERVER, "JBE_TEAM_CANTCHANGE")
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public msg_motd(msgid, dest, id)
{
	return PLUGIN_HANDLED
}

public msg_clcorpse(msgid, dest, id)
{
	return PLUGIN_HANDLED
}

public current_weapon(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE

	if(get_bit(g_PlayerCrowbar, id))
	{
		set_pev(id, pev_viewmodel2, _CrowbarModels[1])
		set_pev(id, pev_weaponmodel2, _CrowbarModels[0])
	}
	else
	{
		set_pev(id, pev_viewmodel2, _FistModels[1])
		set_pev(id, pev_weaponmodel2, _FistModels[0])
	}
	return PLUGIN_CONTINUE
}

public player_death(id)
{
	static killer, victim, CsTeams:kteam, CsTeams:vteam

	killer = read_data(1) 
	victim = read_data(2) 

	if(!is_user_connected(victim) || !is_user_alive(killer))
		return PLUGIN_CONTINUE

	kteam = cs_get_user_team(killer)
	vteam = cs_get_user_team(victim)

	if(vteam == CS_TEAM_CT && kteam == CS_TEAM_T && !get_bit(g_PlayerWanted, killer))
	{
		set_bit(g_PlayerWanted, killer)
		entity_set_int(killer, EV_INT_skin, 4)
		hud_status(0)
	}

	return PLUGIN_CONTINUE
}

public player_status(id)
{
	static type, player, CsTeams:team, name[32], health
	type = read_data(1)
	player = read_data(2)
	switch(type)
	{
		case(1):
		{
			ClearSyncHud(id, g_HudSync[1][_hudsync])
		}
		case(2):
		{
			team = cs_get_user_team(player)
			if((team != CS_TEAM_T) && (team != CS_TEAM_CT))
				return PLUGIN_HANDLED

			health = get_user_health(player)
			get_user_name(player, name, charsmax(name))
			player_hudmessage(id, 4, 2.0, {0, 255, 0}, "%L", LANG_SERVER,
				(team == CS_TEAM_T) ? "JBE_PRISONER_STATUS" : "JBE_GUARD_STATUS", name, health)
		}
	}
	
	return PLUGIN_HANDLED
}

public impulse_100(id)
{
	if(cs_get_user_team(id) == CS_TEAM_T)
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public player_spawn(id)
{
	static CsTeams:team

	if(!is_user_alive(id))
		return HAM_IGNORED

	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)

	clear_bit(g_PlayerCrowbar, id)
	clear_bit(g_PlayerWanted, id)
	team = cs_get_user_team(id)

	switch(team)
	{
		case(CS_TEAM_T):
		{
			g_PlayerLast = 0
			if(!g_PlayerReason[id])
				g_PlayerReason[id] = random_num(1, 6)

			player_hudmessage(id, 0, 5.0, {255, 0, 255}, "%L %L", LANG_SERVER, "JBE_PRISONER_REASON",
				LANG_SERVER, g_Reasons[g_PlayerReason[id]])

			set_user_info(id, "model", "jbemodel")
			entity_set_int(id, EV_INT_body, 2)
			if(is_freeday() || get_bit(g_FreedayAuto, id))
			{
				freeday_set(0, id)
				clear_bit(g_FreedayAuto, id)
				entity_set_int(id, EV_INT_skin, 3)
				if(get_pcvar_num(gp_GlowModels))
					player_glow(id, g_Colors[1])
			}
			else
			{
				entity_set_int(id, EV_INT_skin, random_num(0, 2))
			}

			if(g_CrowbarCount < get_pcvar_num(gp_CrowbarMax))
			{
				if(random_num(0, g_MaxClients) > (g_MaxClients / 2))
				{
					g_CrowbarCount++
					set_bit(g_PlayerCrowbar, id)
				}
			}
			first_join(id)
		}
		case(CS_TEAM_CT):
		{
			set_user_info(id, "model", "jbemodel")
			entity_set_int(id, EV_INT_body, 3)
			first_join(id)
		}
	}
	player_strip_weapons(id)
	return HAM_IGNORED
}

public player_damage(victim, ent, attacker, Float:damage, bits)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED

	if(get_user_weapon(attacker) == CSW_KNIFE && get_bit(g_PlayerCrowbar, attacker) && cs_get_user_team(victim) != CS_TEAM_T)
	{
		SetHamParamFloat(4, damage * get_pcvar_float(gp_CrowbarMul))
		return HAM_OVERRIDE
	}

	return HAM_IGNORED
}

public player_attack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	static CsTeams:vteam, CsTeams:ateam
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED

	vteam = cs_get_user_team(victim)
	ateam = cs_get_user_team(attacker)

	if(ateam == CS_TEAM_CT && vteam == CS_TEAM_CT)
		return HAM_SUPERCEDE

	if(ateam == CS_TEAM_CT && vteam == CS_TEAM_T)
	{
		if(get_bit(g_PlayerRevolt, victim))
		{
			clear_bit(g_PlayerRevolt, victim)
			hud_status(0)
		}
		return HAM_IGNORED
	}

	if(ateam == CS_TEAM_T && vteam == CS_TEAM_T && !g_BoxStarted)
		return HAM_SUPERCEDE

	if(ateam == CS_TEAM_T && vteam == CS_TEAM_CT)
	{
		if(!g_PlayerRevolt)
			revolt_start()

		set_bit(g_PlayerRevolt, attacker)
	}

	return HAM_IGNORED
}

public button_attack(button, id, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	if(is_valid_ent(button) && get_pcvar_num(gp_ButtonShoot))
		ExecuteHam(Ham_Use, button, id, 0, 2, 1.0)

	return HAM_IGNORED
}

public player_killed(id)
{
	static CsTeams:team
	team = cs_get_user_team(id)
	team_count()
	switch(team)
	{
		case(CS_TEAM_CT):
		{
			if(g_TeamCount[CS_TEAM_CT] > ctcount_allowed())
				cs_set_user_team(id, CS_TEAM_T)

			if(g_Simon == id)
			{
				g_Simon = 0
				ClearSyncHud(0, g_HudSync[2][_hudsync])
				player_hudmessage(0, 2, 5.0, _, "%L", LANG_SERVER, "JBE_SIMON_KILLED")
			}
		}
		case(CS_TEAM_T):
		{
			clear_bit(g_PlayerRevolt, id)
			clear_bit(g_PlayerWanted, id)
		}
	}
}

public set_client_kv(id, const info[], const key[])
{
	if(equal(key, "model"))
		return FMRES_SUPERCEDE

	return FMRES_IGNORED
}

public sound_emit(id, channel, sample[])
{
	if(is_user_alive(id) && equal(sample, "weapons/knife_", 14))
	{
		switch(sample[17])
		{
			case('b'):
			{
				emit_sound(id, CHAN_WEAPON, "weapons/cbar_hitbod2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			case('w'):
			{
				emit_sound(id, CHAN_WEAPON, "weapons/cbar_hitbod1.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
			}
			case('1', '2'):
			{
				emit_sound(id, CHAN_WEAPON, "weapons/bullet_hit2.wav", random_float(0.5, 1.0), ATTN_NORM, 0, PITCH_NORM)
			}
		}
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public voice_listening(receiver, sender, bool:listen)
{
	if(!is_user_connected(receiver) || !is_user_connected(sender) || (receiver == sender) || (sender == g_Simon) || is_user_admin(sender))
		return FMRES_IGNORED
 
	if(!get_bit(g_SimonVoice, sender) && get_pcvar_num(gp_VoiceBlock))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, false)
		return FMRES_SUPERCEDE
	}

	if(g_SimonTalking && (sender != g_Simon))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, false)
		return FMRES_SUPERCEDE
	}
	else if((get_pcvar_num(gp_TalkMode) == 1) && (get_user_team(sender) == _:CS_TEAM_T) && (get_user_team(receiver) == _:CS_TEAM_CT))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, false)
		return FMRES_SUPERCEDE
	}
	else if((get_pcvar_num(gp_TalkMode) == 2) && !is_user_alive(sender))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, false)
		return FMRES_SUPERCEDE
	}
	
 
	return FMRES_IGNORED
}

public round_first()
{
	g_JailDay = 0
	round_end()
}

public round_end()
{
	new CsTeams:team
	g_PlayerRevolt = 0
	g_PlayerFreeday = 0
	g_PlayerLast = 0
	g_BoxStarted = 0
	g_CrowbarCount = 0
	g_Simon = 0
	g_SimonAllowed = 0
	g_FreeDay = 0
	g_RoundStarted = 0
	g_LastDenied = 0
	g_BlockWeapons = 0
	g_TeamCount[CS_TEAM_T] = 0
	g_TeamCount[CS_TEAM_CT] = 0
	g_FreedayNext = (random_num(1,80) >= 75)

	remove_task(TASK_STATUS)
	remove_task(TASK_FREEDAY)
	remove_task(TASK_ROUND)
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(!is_user_connected(i))
			continue

		team = cs_get_user_team(i)
		player_strip_weapons(i)
		switch(team)
		{
			case(CS_TEAM_SPECTATOR):
			{
				show_menu(i, 51, TEAM_MENU, -1)
			}
		}
	}
	for(new i = 0; i < sizeof(g_HudSync); i++)
		ClearSyncHud(0, g_HudSync[i][_hudsync])

}

public round_start()
{
	team_count()
	g_JailDay++
	if(!g_Simon && is_freeday())
	{
		g_FreeDay = 1
		emit_sound(0, CHAN_AUTO, "jbextreme/brass_bell_C.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	set_task(2.0, "hud_status", TASK_STATUS, _, _, "b")
	set_task(60.0, "check_freeday", TASK_FREEDAY)
	g_SimonAllowed = 1
}

public cmd_jointeam(id)
{
	return PLUGIN_HANDLED
}

public cmd_joinclass(id)
{
	return PLUGIN_HANDLED
}

public cmd_voiceon(id)
{
	client_cmd(id, "+voicerecord")
	set_bit(g_SimonVoice, id)
	if(g_Simon == id || is_user_admin(id))
		set_bit(g_SimonTalking, id)

	return PLUGIN_HANDLED
}

public cmd_voiceoff(id)
{
	client_cmd(id, "-voicerecord")
	clear_bit(g_SimonVoice, id)
	if(g_Simon == id || is_user_admin(id))
		clear_bit(g_SimonTalking, id)

	return PLUGIN_HANDLED
}

public cmd_simon(id)
{
	static CsTeams:team, name[32]
	team = cs_get_user_team(id)
	if(g_SimonAllowed && !g_FreeDay && is_user_alive(id) && team == CS_TEAM_CT && !g_Simon)
	{
		g_Simon = id
		get_user_name(id, name, charsmax(name))
		entity_set_int(id, EV_INT_body, 1)
		if(get_pcvar_num(gp_GlowModels))
			player_glow(id, g_Colors[0])

		hud_status(0)
	}
	return PLUGIN_HANDLED
}

public cmd_nomic(id)
{
	static CsTeams:team, alive
	team = cs_get_user_team(id)
	if(team == CS_TEAM_CT)
	{
		if(g_Simon == id)
		{
			g_Simon = 0
			player_hudmessage(0, 2, 5.0, _, "%L", LANG_SERVER, "JBE_SIMON_TRANSFERED")
		}
		if(!is_user_admin(id))
			set_bit(g_PlayerNomic, id)
		alive = is_user_alive(id)
		cs_set_user_team(id, CS_TEAM_T)
		if(alive)
			spawn(id)
	}
	return PLUGIN_HANDLED
}

public cmd_box(id)
{
	static i
	if((id < 0) || (is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT))
	{
		if(g_TeamAlive[CS_TEAM_T] <= get_pcvar_num(gp_BoxMax))
		{
			for(i = 1; i <= g_MaxClients; i++)
				if(is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
					set_user_health(i, 100)

			set_cvar_num("mp_tkpunish", 0)
			set_cvar_num("mp_friendlyfire", 1)
			g_BoxStarted = 1
			player_hudmessage(0, 1, 3.0, _, "%L", LANG_SERVER, "JBE_GUARD_BOX")
		}
		else
		{
			player_hudmessage(id, 1, 3.0, _, "%L", LANG_SERVER, "JBE_GUARD_CANTBOX")
		}
	}
	return PLUGIN_HANDLED
}

public cmd_help(id)
{
	if(id > g_MaxClients)
		id -= TASK_HELP

	remove_task(TASK_HELP + id)
	switch(get_bit(g_PlayerHelp, id))
	{
		case(0):
		{
			set_bit(g_PlayerHelp, id)
			player_hudmessage(id, 7, 15.0, {230, 100, 10}, "%s", g_HelpText)
			set_task(15.0, "cmd_help", TASK_HELP + id)
		}
		default:
		{
			clear_bit(g_PlayerHelp, id)
			ClearSyncHud(id, g_HudSync[7][_hudsync])
		}
	}
}

public cmd_freeday(id)
{
	static menu, menuname[32]
	if((is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_CT) || is_user_admin(id))
	{
		formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "JBE_MENU_FREEDAY")
		menu = menu_create(menuname, "freeday_select")
		menu_addplayers(menu, CS_TEAM_T, id)
		menu_display(id, menu)
	}
	return PLUGIN_CONTINUE
}

public cmd_lastrequest(id)
{
	static menu, menuname[32], option[64]
	if(g_FreeDay || g_LastDenied || id != g_PlayerLast || get_bit(g_PlayerFreeday, id))
		return PLUGIN_CONTINUE

	formatex(menuname, charsmax(menuname), "%L", LANG_SERVER, "JBE_MENU_LASTREQ")
	menu = menu_create(menuname, "lastrequest_select")

	formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_OPT1")
	menu_additem(menu, option, "1", 0)

	formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_OPT2")
	menu_additem(menu, option, "2", 0)

	formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_OPT3")
	menu_additem(menu, option, "3", 0)

	formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_OPT4")
	menu_additem(menu, option, "4", 0)

	menu_display(id, menu)
	return PLUGIN_CONTINUE
}

public adm_freeday(id)
{
	static player, user[32]
	read_argv(1, user, charsmax(user))
	player = cmd_target(id, user, 2)
	if(is_user_connected(player) && cs_get_user_team(player) == CS_TEAM_T)
	{
		freeday_set(id, player)
	}
	return PLUGIN_HANDLED
}

public adm_nomic(id)
{
	static player, user[32]
	read_argv(1, user, charsmax(user))
	player = cmd_target(id, user, 3)
	if(is_user_connected(player))
	{
		cmd_nomic(player)
	}
	return PLUGIN_HANDLED
}

public adm_box(id)
{
	cmd_box(-1)
	return PLUGIN_HANDLED
}


public team_select(id, key)
{
	static CsTeams:team, roundloop, admin

	roundloop = get_pcvar_num(gp_RetryTime) / 2
	team = cs_get_user_team(id)
	admin = is_user_admin(id)
	team_count()

	if(!admin && (team == CS_TEAM_UNASSIGNED) && (g_RoundStarted >= roundloop) && g_TeamCount[CS_TEAM_CT] && g_TeamCount[CS_TEAM_T] && !is_user_alive(id))
	{
		team_join(id, CS_TEAM_SPECTATOR)
		client_print(id, print_center, "%L", LANG_SERVER, "JBE_TEAM_CANTJOIN")
		return PLUGIN_HANDLED
	}


	switch(key)
	{
		case(0):
		{
			if(team == CS_TEAM_T)
				return PLUGIN_HANDLED

			g_PlayerReason[id] = random_num(1, 6)

			team_join(id, CS_TEAM_T)
		}
		case(1):
		{
			if(team == CS_TEAM_CT || (!admin && get_bit(g_PlayerNomic, id)))
				return PLUGIN_HANDLED

			if(g_TeamCount[CS_TEAM_CT] < ctcount_allowed() || admin)
				team_join(id, CS_TEAM_CT)
			else
				client_print(id, print_center, "%L", LANG_SERVER, "JBE_TEAM_CTFULL")
		}
		case(5):
		{
			user_silentkill(id)
			team_join(id, CS_TEAM_SPECTATOR)
		}
	}
	return PLUGIN_HANDLED
}

public team_join(id, CsTeams:team)
{
	static restore, vgui, msgblock

	restore = get_pdata_int(id, m_iVGUI)
	vgui = restore & (1<<0)
	if(vgui)
		set_pdata_int(id, m_iVGUI, restore & ~(1<<0))

	if(team == CS_TEAM_SPECTATOR)
	{
		msgblock = get_msg_block(g_MsgShowMenu)
		set_msg_block(g_MsgShowMenu, BLOCK_ONCE)
		dllfunc(DLLFunc_ClientPutInServer, id)
		set_msg_block(g_MsgShowMenu, msgblock)
		set_pdata_int(id, m_fGameHUDInitialized, 1)
		engclient_cmd(id, "jointeam", "6")
	}
	else
	{
		msgblock = get_msg_block(g_MsgShowMenu)
		set_msg_block(g_MsgShowMenu, BLOCK_ONCE)
		engclient_cmd(id, "jointeam", (team == CS_TEAM_CT) ? "2" : "1")
		engclient_cmd(id, "joinclass", "1")
		set_msg_block(g_MsgShowMenu, msgblock)
	}
	
	if(vgui)
		set_pdata_int(id, m_iVGUI, restore)
}

public team_count()
{
	static CsTeams:team, last
	g_TeamCount[CS_TEAM_UNASSIGNED] = 0
	g_TeamCount[CS_TEAM_T] = 0
	g_TeamCount[CS_TEAM_CT] = 0
	g_TeamCount[CS_TEAM_SPECTATOR] = 0
	g_TeamAlive[CS_TEAM_UNASSIGNED] = 0
	g_TeamAlive[CS_TEAM_T] = 0
	g_TeamAlive[CS_TEAM_CT] = 0
	g_TeamAlive[CS_TEAM_SPECTATOR] = 0
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(is_user_connected(i))
		{
			team = cs_get_user_team(i)
			g_TeamCount[team]++
			g_PlayerTeam[i] = team
			if(is_user_alive(i))
			{
				g_TeamAlive[team]++
				if(team == CS_TEAM_T)
					last = i
			}
		}
		else
		{
			g_PlayerTeam[i] = CS_TEAM_UNASSIGNED
		}
	}
	if(g_TeamAlive[CS_TEAM_T] == 1)
	{
		if(last != g_PlayerLast)
		{
			prisoner_last(last)
		}
	}
	else
	{
		g_PlayerLast = 0
	}
}

public revolt_start()
{
	client_cmd(0,"speak ambience/siren")
	set_task(8.0, "stop_sound")
	hud_status(0)
}

public stop_sound(task)
{
	client_cmd(0, "stopsound")
}

public hud_status(task)
{
	static i, n
	new name[32], szStatus[64], wanted[1024]
 
	if(g_RoundStarted < (get_pcvar_num(gp_RetryTime) / 2))
		g_RoundStarted++

	n = 0
	formatex(wanted, charsmax(wanted), "%L", LANG_SERVER, "JBE_PRISONER_WANTED")
	n = strlen(wanted)
	for(i = 0; i < g_MaxClients; i++)
	{
		if(get_bit(g_PlayerWanted, i) && is_user_alive(i) && n < charsmax(wanted))
		{
			get_user_name(i, name, charsmax(name))
			n += copy(wanted[n], charsmax(wanted) - n, "^n^t")
			n += copy(wanted[n], charsmax(wanted) - n, name)
		}
	}

	team_count()
	formatex(szStatus, charsmax(szStatus), "%L", LANG_SERVER, "JBE_STATUS", g_TeamAlive[CS_TEAM_T], g_TeamCount[CS_TEAM_T])
	message_begin(MSG_BROADCAST, get_user_msgid("StatusText"), {0,0,0}, 0)
	write_byte(0)
	write_string(szStatus)
	message_end()

	if(g_Simon)
	{
		get_user_name(g_Simon, name, charsmax(name))
		player_hudmessage(0, 2, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_SIMON_FOLLOW", name)
	}
	else if(g_FreeDay)
	{
		player_hudmessage(0, 2, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_STATUS_FREEDAY")
	}

	if(g_PlayerWanted)
		player_hudmessage(0, 3, 3.0, {255, 25, 50}, "%s", wanted)
	else if(g_PlayerRevolt)
		player_hudmessage(0, 3, 3.0, {255, 25, 50}, "%L", LANG_SERVER, "JBE_PRISONER_REVOLT")

	player_hudmessage(0, 5, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_STATUS_DAY", g_JailDay)
}

public check_freeday(task)
{
	static Float:roundmax
	if(!g_Simon)
	{
		g_FreeDay = 1
		hud_status(0)
		if(roundmax > 0.0)
			set_task(roundmax - 60.0, "check_end", TASK_ROUND)
	}
	roundmax = get_pcvar_float(gp_RoundMax)
}

public check_end(task)
{
	team_count()
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(g_PlayerTeam[i] == CS_TEAM_T && is_user_alive(i))
		{
			user_silentkill(i)
			cs_set_user_deaths(i, get_user_deaths(i) - 1)
		}
	}
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(g_PlayerTeam[i] == CS_TEAM_CT && is_user_alive(i))
		{
			user_silentkill(i)
			cs_set_user_deaths(i, get_user_deaths(i) - 1)
		}
	}
	player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_STATUS_ROUNDEND")
}

public prisoner_last(id)
{
	static name[32]
	if(is_user_alive(id) && cs_get_user_team(id) == CS_TEAM_T)
	{
		get_user_name(id, name, charsmax(name))
		player_hudmessage(0, 6, 5.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_PRISONER_LAST", name)
		g_PlayerLast = id
	}
}

public freeday_select(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	static dst[32], data[5], player, access, callback

	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	player = str_to_num(data)
	freeday_set(id, player)
	return PLUGIN_HANDLED
}

public lastrequest_select(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	static i, dst[32], data[5], access, callback, option[64]

	menu_item_getinfo(menu, item, access, data, charsmax(data), dst, charsmax(dst), callback)
	get_user_name(id, dst, charsmax(dst))
	switch(data[0])
	{
		case('1'):
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_SEL1", dst)
			clear_bit(g_PlayerCrowbar, id)
			player_strip_weapons_all()
			g_BlockWeapons = 1
		}
		case('2'):
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_SEL2", dst)
			emit_sound(0, CHAN_AUTO, "jbextreme/nm_goodbadugly.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			player_strip_weapons_all()
			i = random_num(0, sizeof(_WeaponsGuns) - 1)
			give_item(id, _WeaponsGuns[i])
			g_BlockWeapons = 1
		}
		case('3'):
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_SEL3", dst)
			player_strip_weapons_all()
			i = random_num(0, sizeof(_WeaponsFree) - 1)
			give_item(id, _WeaponsFree[i])
			g_BlockWeapons = 1
			cs_set_user_bpammo(id, _WeaponsFreeCSW[i], _WeaponsAmmo[i])
		}
		case('4'):
		{
			formatex(option, charsmax(option), "%L", LANG_SERVER, "JBE_MENU_LASTREQ_SEL4", dst)
			set_bit(g_FreedayAuto, id)
			user_silentkill(id)
		}
		default:
		{
			return PLUGIN_HANDLED
		}
	}
	player_hudmessage(0, 6, 3.0, {0, 255, 0}, option)
	g_LastDenied = 1
	return PLUGIN_HANDLED
}

stock freeday_set(id, player)
{
	static src[32], dst[32]
	get_user_name(player, dst, charsmax(dst))

	if(is_user_alive(player) && !get_bit(g_PlayerWanted, player))
	{
		if(!is_freeday())
			set_bit(g_PlayerFreeday, player)

		if(0 < id <= g_MaxClients)
		{
			get_user_name(id, src, charsmax(src))
			player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_GUARD_FREEDAYGIVE", src, dst)
		}
		else if(!g_FreeDay)
		{
			player_hudmessage(0, 6, 3.0, {0, 255, 0}, "%L", LANG_SERVER, "JBE_PRISONER_HASFREEDAY", dst)
		}
	}
}

stock first_join(id)
{
	if(!get_bit(g_PlayerJoin, id))
	{
		set_bit(g_PlayerJoin, id)
		clear_bit(g_PlayerHelp, id)
		set_task(5.0, "cmd_help", TASK_HELP + id)
	}
}

stock ctcount_allowed()
{
	static count
	count = ((g_TeamCount[CS_TEAM_T] + g_TeamCount[CS_TEAM_CT]) / get_pcvar_num(gp_TeamRatio))
	if(count < 2)
		count = 2
	else if(count > get_pcvar_num(gp_CtMax))
		count = get_pcvar_num(gp_CtMax)

	return count
}

stock player_hudmessage(id, hudid, Float:time = 0.0, color[3] = {0, 255, 0}, msg[], any:...)
{
	static text[512], Float:x, Float:y
	x = g_HudSync[hudid][_x]
	y = g_HudSync[hudid][_y]
	
	if(time > 0)
		set_hudmessage(color[0], color[1], color[2], x, y, 0, 0.00, time, 0.00, 0.00)
	else
		set_hudmessage(color[0], color[1], color[2], x, y, 0, 0.00, g_HudSync[hudid][_time], 0.00, 0.00)

	vformat(text, charsmax(text), msg, 6)
	ShowSyncHudMsg(id, g_HudSync[hudid][_hudsync], text)
}

stock menu_addplayers(menu, CsTeams:team, skip=0, alive=1)
{
	static i, name[32], id[5]
	for(i = 1; i <= g_MaxClients; i++)
	{
		if(!is_user_connected(i) || (alive && !is_user_alive(i)) || (skip == i))
			continue

 		if(!(team == CS_TEAM_T || team == CS_TEAM_CT) || ((team == CS_TEAM_T || team == CS_TEAM_CT) && (cs_get_user_team(i) == team)))
		{
			get_user_name(i, name, charsmax(name))
			num_to_str(i, id, charsmax(id))
			menu_additem(menu, name, id, 0)
		}
	}
}

stock player_glow(id, color[3], amount=40)
{
	set_user_rendering(id, kRenderFxGlowShell, color[0], color[1], color[2], kRenderNormal, amount)
}

stock player_strip_weapons(id)
{
	strip_user_weapons(id)
	give_item(id, "weapon_knife")
	set_pdata_int(id, m_iPrimaryWeapon, 0)
}

stock player_strip_weapons_all()
{
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(is_user_alive(i))
		{
			player_strip_weapons(i)
		}
	}
}

stock is_freeday()
{
	return (g_FreedayNext || g_FreeDay || (g_JailDay == 1))
}
