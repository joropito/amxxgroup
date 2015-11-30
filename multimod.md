Description

Once this plugin is loaded for the first time, it restarts the server to correctly setup and choosing the first mod available in config file.

When it's time to vote map, all players must vote for the nextmap plugin-set (I prefer to call as Mod).

After that, you can vote for custom maps using mapchooser\_multimod or Galileo

So, with this you have:

```
- Plugin-sets/Mods to play
- Per-Mod mapcycle file
- Per-Mod cvars file
```

Cvars
```
  amx_mintime: Minimum time to play before players can make MOD voting
  amx_multimod_mode: Compatibility mode 0 (auto) ; 1 (mapchooser_multimod) ; 2 (Galileo)
```

Commands
```
  amx_votemod: Admin only command to launch MOD & MAP voting
  say /votemod: Player command to launch MOD & MAP voting
  say_team /votemod: Player command to launch MOD & MAP voting
  say nextmod: Check which MOD will be running in next map
```

Installation
```
  * Compile and put it in your plugins folder
  * Create the folder multimod in your game base directory (ej: cstrike/multimod czero/multimod)
  * Create file multimod.ini in multimod folder (see file format in examples)
  * Create those files for each mod in multimod folder (TAG is the one used in multimod.ini file)
    * TAG-plugins.ini: plugin list to be loaded for the mod (you must include multimod.amxx, admin plugins, mod specific plugins, etc)
    * TAG-maps.ini: maps list for the mod (same format as mapcycle.txt)
cfgfilename.cfg: custom cvars and values for the mod
    * Add multimod.amxx into addons/amxmodx/configs/plugins.ini
```

How it works?
```
* This plugin doesn't move, rename nor create files on the fly
* This plugin doesn't have a map voting code at this time
* This plugin will restart the server at first run to setup correctly
* After first restart, default plugins.ini will not be loaded anymore
* When there's 3 minutes left for the current map, this plugin will bring a menu for MOD voting
* Then, mapchooser/galileo will have time to work on map voting
```

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
EXAMPLE

  * multimod.ini format example
```
    ;mode name:mod tag:custom cvars cfg file
    [Gun Game]:[gungame]:[gungame-config.cfg]
    [Paint Ball]:[paintball]:[paintball-config.cfg]
```
  * With this example you will need to create:
```
    multimod/gungame-maps.ini
    multimod/gungame-plugins.ini
    multimod/gungame-config.cfg
    
    multimod/paintball-maps.ini
    multimod/paintball-plugins.ini
    multimod/paintball-config.cfg
```
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////