## Block Maker FrameWork ##
  * What is this?
> It's a multi-plugin framework to allow developers build their own type of blocks for maps.

  * Why you made this?
> Because I see too many people asking for support to modify some other plugins for blocks and I think it's very annoying to modify.

  * What's change with this plugin framework?
> You can make your own block without any needs to modify the core plugin.

  * I can do anything with my block?
> Yes, you can do anything but I suggest try to limit to function calls available in this framework to avoid high cpu usage in your own block.

  * Can I ask you to make some blocks for me?
> No. Read the api, it's very simple. Anything else is up to you.

## API Details ##

There's a native function to register your block, then there's some standard calls handled by core plugin you may want to use.

You must know that every block entity is func\_breakable type.

_**reg\_block** native_

```
 native _reg_block(const name[], const ver[], const model[], const touch, const Float:cdown, const Float:size[3], const Float:sizesmall[3], const Float:sizelarge[3])
```

> This is used to register your block within the core plugin.
> You must pass all arguments.

**block\_Think** call
> This is the think of the block. It's only be called if the block entity has to think.

**block\_Spawn** call
> This is called after the block was created. You can handle here any change over the entity you may need (example: pev\_health).

**block\_Touch** call
> This is called on every touch from a player to the block.