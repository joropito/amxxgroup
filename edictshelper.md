# Introduction #

This tool is oriented to fix some problems when you have orphans edicts created in the map.

# Details #

It works very simple

  * Periodically checks for every entity created in the map
  * We have a number of rules to verify if some entity should be deleted or not
  * There's an option to choose between delete or only warn about orphan entity

# Safe Entities #
  * Worldspawn
  * Map entities
  * Players

# Deletion Rules #
  * Every entity without owner
  * Entities owned by disconnected players
