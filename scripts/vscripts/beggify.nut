PrecacheModel("models/weapons/c_models/c_bet_rocketlauncher/c_bet_rocketlauncher.mdl")
PrecacheModel("models/weapons/c_models/c_soldier_arms_og.mdl")
PrecacheModel("models/weapons/c_models/c_soldier_animations_og.mdl")
PrecacheSound("weapons/doom_rocket_launcher.wav")
PrecacheSound("weapons/dumpster_rocket_reload.wav")

::BeggarsVM <- {}
::RLChoice <- {}

enum VIEWMODELS {
    STOCK = "models/weapons/w_models/w_rocketlauncher.mdl",
    BEGGARS = "models/weapons/c_models/c_dumpster_device/c_dumpster_device.mdl",
    ORIGINAL = "models/weapons/c_models/c_bet_rocketlauncher/c_bet_rocketlauncher.mdl",
    BLACKBOX = "models/weapons/c_models/c_blackbox/c_blackbox.mdl",
    BLACKBOX_FESTIVE = "models/weapons/c_models/c_blackbox/c_blackbox_xmas.mdl",
    LIBLAUNCHER = "models/weapons/c_models/c_liberty_launcher/c_liberty_launcher.mdl",
    STOCK_FESTIVE = "models/player/items/soldier/xms_rocketlauncher.mdl",
    ROCKETJUMPER = "models/weapons/c_models/c_rocketjumper/c_rocketjumper.mdl"
}

::RL_VIEWMODELS <- {
    [513] = VIEWMODELS.ORIGINAL,
    [18] = VIEWMODELS.STOCK,
    [205] = VIEWMODELS.STOCK,
    [228] =  VIEWMODELS.BLACKBOX,
    [237] = VIEWMODELS.ROCKETJUMPER,
    [414] = VIEWMODELS.LIBLAUNCHER,
    [658] = VIEWMODELS.STOCK_FESTIVE,
    [730] = VIEWMODELS.BEGGARS,
    [1085] = VIEWMODELS.BLACKBOX_FESTIVE,
    [907] = VIEWMODELS.STOCK,
    [800] = VIEWMODELS.STOCK,
    [809] = VIEWMODELS.STOCK,
    [889] = VIEWMODELS.STOCK,
    [898] = VIEWMODELS.STOCK,
    [916] = VIEWMODELS.STOCK,
    [965] = VIEWMODELS.STOCK,
    [974] = VIEWMODELS.STOCK
}

::FORBIDDEN_WEAPONS <- {
    tf_weapon_rocketlauncher_directhit = "FORBIDDEN",
    tf_weapon_particle_cannon = "FORBIDDEN",
    tf_weapon_rocketlauncher_airstrike = "FORBIDDEN"
}

// First time cleanup, if reloading the script
local garbage = null
while (garbage = Entities.FindByClassname(garbage, "tf_wearable_vm")) {
    if (garbage.GetName().find("fake_beggars_entity") != null) {
        // printl("Killed " + garbage)
        garbage.Kill()
    }
}

::CTFPlayer.deleteVM <- function() {
    local garbo = null
    while (garbo = Entities.FindByName(garbo, "fake_beggars_" + this)) {
        // printl("Deleted " + garbo)
        garbo.Kill()
    }
    if (this in BeggarsVM) {
        local rl = this.getRocketLauncher()
        if (rl != null) {
            AddThinkToEnt(rl, null)
        }
        if (this in BeggarsVM) { delete BeggarsVM[this] }
    }
}

// Delete viewmodels that don't belong to anyone
function cleanup() {
    foreach (k in BeggarsVM) {
        if (k == null) {
            BeggarsVM[k].GetMoveParent().Kill()
            BeggarsVM[k].Kill()
            delete BeggarsVM[k]
        }
    }
    foreach (k in RLChoice) {
        if (k == null) {
            delete RLChoice[k]
        }
    }
    local garbage = null
    while (garbage = Entities.FindByClassname(garbage, "tf_wearable_vm")) {
        if (garbage.GetName().find("fake_beggars_") != null) {
            if (NetProps.GetPropEntity(garbage, "m_hOwnerEntity") == null) {
                // printl("Killed " + garbage)
                garbage.Kill()
            }
        }
}
}
cleanup()

// Returns the player's rocket launcher entity if they have one. If they have a
// forbidden weapon (dh, mangler, airstrike) then freeze them in place
::CTFPlayer.getRocketLauncher <- function() {
    local wpn = null
    for (local i = 0; i < 10; i++) {
        wpn = NetProps.GetPropEntityArray(this, "m_hMyWeapons", i)
        if (wpn != null) {
            if (wpn.GetClassname() == "tf_weapon_rocketlauncher") {
                return wpn
            } else if (wpn.GetClassname() in FORBIDDEN_WEAPONS) {
                this.punish()
                return
            }
        }
    }
    return null
}

// On death, we want to clear the custom beggars stuff because it complains about things being null if we don't
// function OnGameEvent_player_death(params) {
//     if ("userid" in params) {
//         local plr = GetPlayerFromUserID(params["userid"])
//         if (plr in RLChoice) { delete RLChoice[plr] }
//     }
// }

// Changing class in a spawn room doesn't trigger the player_death or inv application afaik
function OnGameEvent_player_changeclass(params) {
    if ("userid" in params) {
        local plr = GetPlayerFromUserID(params["userid"])
        if (plr in RLChoice) { delete RLChoice[plr] }
        plr.createVM()
    }
}

// This is just to immediately detect forbidden launchers
function OnGameEvent_player_spawn(params) {
    if ("userid" in params) {
        local plr = GetPlayerFromUserID(params["userid"])
        plr.getRocketLauncher()
        plr.createVM()
    }
}

// Stop people from doing things holding a non beggifiable rocket launcher
::CTFPlayer.punish <- function() {
    this.AddCond(87)
}

::CTFPlayer.unpunish <- function() {
    this.RemoveCond(87)
}

// This stores what rl the player had equipped before equipping the beggars.
// If it's original, we do some extra shenanigans to get the normal viewmodel
// If it's already beggars, we either already have the modified beggars or have
// the beggars equipped already.
function OnGameEvent_post_inventory_application(params) {
    cleanup()
    if ("userid" in params) {
        local plr = GetPlayerFromUserID(params["userid"])
        if (plr.GetPlayerClass() == 3) {
            local rl = plr.getRocketLauncher()
            if (rl == null) {
                return 
            } else {
                plr.unpunish() // Free the player from the grip of doom since they have the correct rocket launcher equipped
            }
            local itemidx = NetProps.GetPropInt(rl, "m_AttributeManager.m_Item.m_iItemDefinitionIndex")
            printl("idx: " + itemidx)
            if (itemidx == 513) {
                RLChoice[plr] <- 513
            } else if (itemidx == 730) {
                if (!(plr in RLChoice)) {
                    RLChoice[plr] <- 730
                }
            } else if (itemidx in RL_VIEWMODELS) {
                RLChoice[plr] <- itemidx
            } else {
                RLChoice[plr] <- 730
            }
            plr.giveBeggars()
        }
    }
}
__CollectGameEventCallbacks(this)

// Sets up the beggars, including attributes and preloading an original viewmodel to use if the player is using that weapon.
// Adds a think function to the weapon that updates the viewmodel if it's an original - we have to manually hide the model
// since it's a custom model.
::CTFPlayer.giveBeggars <- function() {
    local wpn = this.getRocketLauncher()
    if (wpn == null) { return }
    wpn.RemoveAttribute("clip size penalty") // Black box has this
    wpn.AddAttribute("ammo regen", 1, 1)
    wpn.AddAttribute("auto fires full clip", 1, 1)
    wpn.AddAttribute("can overload", 1, 1)
    wpn.AddAttribute("clip size penalty HIDDEN", 0.75, 1)
    wpn.AddAttribute("reload time increased hidden", 1.3, 1)
    wpn.AddAttribute("fire rate bonus hidden", 0.3, 1)
    wpn.AddAttribute("projectile spread angle penalty", 3, 1)
    NetProps.SetPropInt(wpn, "m_iClip1", 0)
    NetProps.SetPropInt(wpn, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 730)
    this.createVM()
}

// Creates the original viewmodel entity for a player. The arms_og model is a custom one with stock rl animations
// replaced with original animations. This is the best way to get original animations on another rocket launcher
// as far as I know.
::CTFPlayer.createVM <- function() {
    if (!(this in RLChoice)) {
        RLChoice[this] <- 730
    }
    this.deleteVM()
    local hands = NetProps.GetPropEntity(this, "m_hViewModel")
    local wpn = this.getRocketLauncher()
    if (wpn == null) { return }
    local new_hands = null
    new_hands = Entities.CreateByClassname("tf_wearable_vm")
    new_hands.SetAbsOrigin(this.GetLocalOrigin())
    new_hands.SetAbsAngles(this.GetLocalAngles())
    NetProps.SetPropEntity(new_hands, "m_hOwnerEntity", this)
    NetProps.SetPropInt(new_hands, "m_iTeamNum", this.GetTeam())
    NetProps.SetPropInt(new_hands, "m_Collision.m_usSolidFlags", Constants.FSolid.FSOLID_NOT_SOLID)
    NetProps.SetPropInt(new_hands, "m_CollisionGroup", 11)
    NetProps.SetPropInt(new_hands, "m_fEffects", 129)
    NetProps.SetPropInt(new_hands, "m_AttributeManager.m_Item.m_iEntityQuality", 0)
	NetProps.SetPropInt(new_hands, "m_AttributeManager.m_Item.m_iEntityLevel", 1)
	NetProps.SetPropInt(new_hands, "m_AttributeManager.m_Item.m_bInitialized", 1)
    if (RLChoice[this] == 513) {
        NetProps.SetPropInt(new_hands, "m_nModelIndex", GetModelIndex("models/weapons/c_models/c_soldier_arms_og.mdl"))
    } else {
        NetProps.SetPropInt(new_hands, "m_nModelIndex", GetModelIndex("models/weapons/c_models/c_soldier_arms.mdl"))
    }
    new_hands.__KeyValueFromString("targetname", "fake_beggars_" + this)
    Entities.DispatchSpawn(new_hands)
    DoEntFire("!self", "SetParent", "!activator", 0, hands, new_hands)
    new_hands.DisableDraw()

    local new_vm = null
    new_vm = Entities.CreateByClassname("tf_wearable_vm")
    new_vm.SetAbsOrigin(this.GetLocalOrigin())
    new_vm.SetAbsAngles(this.GetLocalAngles())
    NetProps.SetPropEntity(new_vm, "m_hOwnerEntity", this)
    NetProps.SetPropInt(new_vm, "m_iTeamNum", this.GetTeam())
    NetProps.SetPropInt(new_vm, "m_Collision.m_usSolidFlags", Constants.FSolid.FSOLID_NOT_SOLID)
    NetProps.SetPropInt(new_vm, "m_CollisionGroup", 11)
    NetProps.SetPropInt(new_vm, "m_fEffects", 129)
    NetProps.SetPropInt(new_vm, "m_AttributeManager.m_Item.m_iEntityQuality", 0)
    NetProps.SetPropInt(new_vm, "m_AttributeManager.m_Item.m_iEntityLevel", 1)
    NetProps.SetPropInt(new_vm, "m_AttributeManager.m_Item.m_bInitialized", 1)
    new_vm.SetModelSimple(RL_VIEWMODELS[RLChoice[this]])
    NetProps.SetPropEntity(new_vm, "m_hWeaponAssociatedWith", wpn)
    NetProps.SetPropEntity(wpn, "m_hExtraWearableViewModel", new_vm)
    new_vm.__KeyValueFromString("targetname", "fake_beggars_" + this)
    Entities.DispatchSpawn(new_vm)
    DoEntFire("!self", "SetParent", "!activator", 0, new_hands, new_vm)

    if (wpn.ValidateScriptScope()) {
        local wepscript = wpn.GetScriptScope()
        wepscript["modelSwap"] <- function() {
            local owner = NetProps.GetPropEntity(self, "m_hOwner")
            if (owner == null) {
                return 1
            }
            local wpn = owner.GetActiveWeapon()
            if (wpn == null) {
                return 1
            }
            if (RLChoice[owner] == 513) {
                wpn.SetCustomViewModel("models/weapons/c_models/c_soldier_arms_og.mdl")
            }
            local oldhands = NetProps.GetPropEntity(owner, "m_hViewmodel")
            local custom_vm = BeggarsVM[owner]
            if (wpn.GetClassname() == "tf_weapon_rocketlauncher") {
                custom_vm.EnableDraw()
                oldhands.DisableDraw()
            } else {
                custom_vm.DisableDraw()
                oldhands.EnableDraw()
            }
            return 0.015
        }
        AddThinkToEnt(wpn, "modelSwap")
    }

    BeggarsVM[this] <- new_vm
}