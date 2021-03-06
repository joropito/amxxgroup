/***
*
*	Copyright (c) 1996-2002, Valve LLC. All rights reserved.
*	
*	This product contains software technology licensed from Id 
*	Software, Inc. ("Id Technology").  Id Technology (c) 1996 Id Software, Inc. 
*	All Rights Reserved.
*
*   This source code contains proprietary and confidential information of
*   Valve LLC and its suppliers.  Access to this code is restricted to
*   persons who have executed a written SDK license with Valve.  Any access,
*   use or distribution of this code by or to any unlicensed person is illegal.
*
****/
//=========================================================
// Bloater
//=========================================================

#include	"extdll.h"
#include	"util.h"
#include    "cmbase.h"
#include "cmbasemonster.h"
#include	"monsters.h"
#include	"schedule.h"


//=========================================================
// Monster's Anim Events Go Here
//=========================================================
#define	BLOATER_AE_ATTACK_MELEE1		0x01

//=========================================================
// Classify - indicates this monster's place in the 
// relationship table.
//=========================================================
int	CMBloater :: Classify ( void )
{
	return	CLASS_ALIEN_MONSTER;
}

//=========================================================
// SetYawSpeed - allows each sequence to have a different
// turn rate associated with it.
//=========================================================
void CMBloater :: SetYawSpeed ( void )
{
/*	int ys;

	ys = 120;

#if 0
	switch ( m_Activity )
	{
	}
#endif

	pev->yaw_speed = ys; */
}

int CMBloater :: TakeDamage( entvars_t *pevInflictor, entvars_t *pevAttacker, float flDamage, int bitsDamageType )
{
	//PainSound();
	return CMBaseMonster::TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType ); 
}

void CMBloater :: PainSound( void )
{
/*#if 0	
	int pitch = 95 + RANDOM_LONG(0,9);

	switch (RANDOM_LONG(0,5))
	{
	case 0: 
		EMIT_SOUND_DYN(ENT(pev), CHAN_VOICE, "zombie/zo_pain1.wav", 1.0, ATTN_NORM, 0, pitch);
		break;
	case 1:
		EMIT_SOUND_DYN(ENT(pev), CHAN_VOICE, "zombie/zo_pain2.wav", 1.0, ATTN_NORM, 0, pitch);
		break;
	default:
		break;
	}
#endif */
}

void CMBloater :: AlertSound( void )
{
/*#if 0
	int pitch = 95 + RANDOM_LONG(0,9);

	switch (RANDOM_LONG(0,2))
	{
	case 0: 
		EMIT_SOUND_DYN(ENT(pev), CHAN_VOICE, "zombie/zo_alert10.wav", 1.0, ATTN_NORM, 0, pitch);
		break;
	case 1:
		EMIT_SOUND_DYN(ENT(pev), CHAN_VOICE, "zombie/zo_alert20.wav", 1.0, ATTN_NORM, 0, pitch);
		break;
	case 2:
		EMIT_SOUND_DYN(ENT(pev), CHAN_VOICE, "zombie/zo_alert30.wav", 1.0, ATTN_NORM, 0, pitch);
		break;
	}
#endif*/
}

void CMBloater :: IdleSound( void )
{
/*#if 0
	int pitch = 95 + RANDOM_LONG(0,9);

	switch (RANDOM_LONG(0,2))
	{
	case 0: 
		EMIT_SOUND_DYN(ENT(pev), CHAN_VOICE, "zombie/zo_idle1.wav", 1.0, ATTN_NORM, 0, pitch);
		break;
	case 1:
		EMIT_SOUND_DYN(ENT(pev), CHAN_VOICE, "zombie/zo_idle2.wav", 1.0, ATTN_NORM, 0, pitch);
		break;
	case 2:
		EMIT_SOUND_DYN(ENT(pev), CHAN_VOICE, "zombie/zo_idle3.wav", 1.0, ATTN_NORM, 0, pitch);
		break;
	}
#endif*/
}

void CMBloater :: AttackSnd( void )
{
/*#if 0
	int pitch = 95 + RANDOM_LONG(0,9);

	switch (RANDOM_LONG(0,1))
	{
	case 0: 
		EMIT_SOUND_DYN(ENT(pev), CHAN_VOICE, "zombie/zo_attack1.wav", 1.0, ATTN_NORM, 0, pitch);
		break;
	case 1:
		EMIT_SOUND_DYN(ENT(pev), CHAN_VOICE, "zombie/zo_attack2.wav", 1.0, ATTN_NORM, 0, pitch);
		break; 
	}
#endif*/
}


//=========================================================
// HandleAnimEvent - catches the monster-specific messages
// that occur when tagged animation frames are played.
//=========================================================
void CMBloater :: HandleAnimEvent( MonsterEvent_t *pEvent )
{
	/*switch( pEvent->event )
	{
		case BLOATER_AE_ATTACK_MELEE1:
		{
			// do stuff for this event.
			AttackSnd();
		}
		break;

		default:
			CMBaseMonster::HandleAnimEvent( pEvent );
			break;
	}*/
}

//=========================================================
// Spawn
//=========================================================
void CMBloater :: Spawn()
{
	Precache( );

	SET_MODEL(ENT(pev), "models/floater.mdl");
	UTIL_SetSize( pev, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX );

	pev->solid			= SOLID_SLIDEBOX;
	pev->movetype		= MOVETYPE_FLY;
	pev->spawnflags		|= FL_FLY;
	m_bloodColor		= BLOOD_COLOR_GREEN;
	pev->health			= 40;
	pev->view_ofs		= VEC_VIEW;// position of the eyes relative to monster's origin.
	m_flFieldOfView		= 0.5;// indicates the width of this monster's forward view cone ( as a dotproduct result )
	m_MonsterState		= MONSTERSTATE_NONE;

	MonsterInit();
}

//=========================================================
// Precache - precaches all resources this monster needs
//=========================================================
void CMBloater :: Precache()
{
	PRECACHE_MODEL("models/floater.mdl");
}	

//=========================================================
// AI Schedules Specific to this monster
//=========================================================

