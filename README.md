# beggify
VScript for TF2 that forces soldiers to use the Beggar's Bazooka.
If the user has stock, Original, Liberty Launcher, Black Box, or Rocket Jumper equipped, they will retain that viewmodel.
In addition, equipping the Original will cause your Beggar's to be center-fire.

## Usage
You can either pack this in a .bsp and have a `logic_auto` do a `RunScriptFile beggify.nut`, or if you want to use this on an existing map, you can put the contents of this repository into your custom folder and run `script_execute beggify.nut` from the console. This only works locally.

## Known Issues
- **The script hates being reloaded.** Bunch of errors with entities being deleted and missing references, you should reload the map if you wish to reload the script. This could be fixed with an actually good use of null-checking and garbage checking.  
- **Cow Mangler, Airstrike, and Direct Hit don't work.** This probably has to do with their different classnames (`tf_weapon_particle_cannon`, etc.) so I just made it so the player is locked out of doing anything until they switch off those rocket launchers. In the future, it would be best to completely delete their primary weapon and create a new one from scratch, and probably do some more Animation Fuckery to get the Mangler to work, if that's even possible.  
- **All non-stock items retain their other attributes.** Once again probably just a matter of starting from a blank weapon, but this does make interesting combinations of weapons, such as 4-rocket clips with the Liberty Launcher, 2-rocket clips with the Black Box, and no self-damage with the Rocket Jumper.

## Credits
Thanks to Yakibomb for their [Give Weapon Script](https://github.com/Yakibomb/Team_Fortress_2_VScript), it was great reference to use for getting custom viewmodels working.  
