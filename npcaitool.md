# Introduction #

# Details #

# API #

**NPC Natives**

```
/**
 * Register a new NPC Class and setup AI Manager
 *   sName must be a registered class name
 *   iForward is a bitmask of enabled forwards
 **/
native PygClassRegister(const sName[], const iForwards)
```

```
/**
 * Create respawnable entity
 *   sName must be a registered class name
 *   iTeam is the team that this entity belongs
 *   iSpawnFlags it's how this entity will spawn/respawn
 *   fOrigin is where this entity will spawn
 **/
native PygClassSpawn(const sName[], const iTeam, const iSpawnFlags, const Float:fOrigin[3])
```

**NPC Forwards**

```
/**
 * Called at entity PreThink (engine)
 *   use PLUGIN_* values as return
 **/
forward PygmalionPreThink(const iEnt)
```

```
/**
 * Called at entity PostThink (engine)
 *   use PLUGIN_* values as return
 **/
forward PygmalionPostThink(const iEnt)
```

```
/**
 * Called at entity TakeDamage (hamsandwich)
 *   use PLUGIN_* values as return
 **/
forward PygmalionTakeDamage(const iVictim, const iInflictor, const iAttacker, const Float:damage, const damage_type)
```

**NPC Utilities (natives)**

```
/**
 * Returns amount of enemies in radius
 *   if bVisible is set, returns only the amount that are visible from entity
 **/
native PygEnemiesInRadius(const iEnt, const iRadius, const bool:bVisible)
```

```
/**
 * Returns true if vOrigin is visible and in view cone of entity iEnt
 **/
native bool:PygInViewCone(const Float:vOrigin[3], const iEnt)
```

```
/**
 * Returns true if vOrigin is visible from entity iEnt
 **/
native bool:PygVisible(const Float:vOrigin[3], const iEnt)
```

```
/**
 * Returns best target enemy
 *   if bVisible is set, returns only enemies that are visible from entity
 **/
native PygFindEnemy(const iEnt, const bool:bVisible)
```

```
/**
 * Returns nearest item
 *   returns only weapon_*, weaponbox, armoury
 *   if szItem is set and contains a valid entity classname then search only for that kind of entity (override default item types)
 **/
native PygFindItem(const iEnt, const szItem[])
```

```
/**
 * Returns leading objective based on entity's team and status
 *   only search for default CS 1.6 objectives (hostages, bomb zone, etc)
 **/
native PygFindObjective(const iEnt)
```

```
/**
 * 
 * 
 **/
native x()
```

```
/**
 * 
 * 
 **/
native x()
```

```
/**
 * 
 * 
 **/
native x()
```

```
/**
 * 
 * 
 **/
native x()
```