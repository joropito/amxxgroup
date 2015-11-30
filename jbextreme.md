**Description:**
> This plugin will manage Jail-Break gameplay.

**Gameplay:**
> The rules are simple:
    * CT's are guards / TTs are prisoners.
    * CT's must have microphone to give orders to TTs.
    * TT's must obey what CTs says.
    * At round start, some players are choosen to be CTs.
    * Every 6 players, one of them will be CT. The others will be TT.

**Cvars:**
```
  jbe_maxct: max amount of CT players
  jbe_freekill_punish: 0 (no punishment) / 1 (freeday for victim) / 2 (imprison killer) / 3 (random)
  jbe_freeday: seconds to open gate until assume it is freeday / 0 (disable auto freeday)
  jbe_crowbar: amount of random crowbar to give for TTs
  jbe_skills: 0 (disabled) / 1 (enabled)
```

**Features:**
```
  * Auto team join *done*
  * Auto CT limit *done*
  * Simon selection
  * Microphone control
  * Radio control
  * Custom models *done*
  * Random prisoner skills at join (drug dealer, brawny, athlete, junknie) *done*
  * Random crowbar for TTs
  * Freekill detection and punishment
  * Freeday management
```