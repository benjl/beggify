PrecacheModel("models/weapons/c_models/c_bet_rocketlauncher/c_bet_rocketlauncher.mdl")
PrecacheModel("models/weapons/c_models/c_soldier_arms_og.mdl")
PrecacheModel("models/weapons/c_models/c_soldier_animations_og.mdl")
PrecacheSound("weapons/doom_rocket_launcher.wav")
PrecacheSound("weapons/dumpster_rocket_reload.wav")

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

function cleanup() {
    local garbage = null
    while (garbage = Entities.FindByClassname(garbage, "tf_wearable_vm")) {
        if (garbage.ValidateScriptScope()) {
            local garbage_scope = garbage.GetScriptScope()
            if ("viewmodelWeapon" in garbage_scope) {
                try {
                    garbage_scope["viewmodelWeapon"].GetClassname()
                } catch (err) {
                    if (err == "Accessed null instance") {
                        // printl("Removed " + garbage)
                        garbage.Kill()
                    }
                }
            }
        }
    }
}

// Returns the player's rocket launcher entity if they have one. If they have a
// forbidden weapon (dh, mangler, airstrike) then freeze them in place
::CTFPlayer.getRocketLauncher <- function() {
    local wpn = null
    for (local i = 0; i < 10; i++) {
        wpn = NetProps.GetPropEntityArray(this, "m_hMyWeapons", i)
        if (wpn != null) {
            if (wpn.GetClassname() == "tf_weapon_rocketlauncher") {
                this.unpunish()
                return wpn
            } else if (wpn.GetClassname() in FORBIDDEN_WEAPONS) {
                this.punish()
                return null
            }
        }
    }
    return null
}

// This is just to immediately detect forbidden launchers
function OnGameEvent_player_spawn(params) {
    if ("userid" in params) {
        local plr = GetPlayerFromUserID(params["userid"])
        plr.getRocketLauncher()
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
            }
            if (rl.ValidateScriptScope()) {
                local rl_scope = rl.GetScriptScope()
                local itemidx = NetProps.GetPropInt(rl, "m_AttributeManager.m_Item.m_iItemDefinitionIndex")
                if (!("equippedIndex" in rl_scope)) {
                    if (!(itemidx in RL_VIEWMODELS)) {
                        itemidx = 730
                    }
                    rl_scope["equippedIndex"] <- itemidx
                }
                plr.giveBeggars()
            }
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
    local hands = NetProps.GetPropEntity(this, "m_hViewModel")
    local wpn = this.getRocketLauncher()
    if (wpn == null) { return }
    if (wpn.ValidateScriptScope()) {
        local wpn_scope = wpn.GetScriptScope()
        if (wpn_scope["equippedIndex"] == 730) { // We don't need a custom VM if it's already beggars
            wpn_scope["customVM"] <- null
            wpn_scope["customVMHands"] <- null
            return
        }
        if ("customVM" in wpn_scope) { // We don't need to recreate the VMs if they exist already
            if (wpn_scope["customVM"] != null) {
                return
            }
        }
        local new_hands = null
        new_hands = Entities.CreateByClassname("tf_wearable_vm")
        new_hands.ValidateScriptScope()
        local new_hands_scope = new_hands.GetScriptScope()
        new_hands_scope["viewmodelWeapon"] <- wpn
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
        NetProps.SetPropInt(new_hands, "m_nModelIndex", GetModelIndex("models/weapons/c_models/c_soldier_arms.mdl"))
        new_hands.__KeyValueFromString("targetname", "fake_beggars_" + this)
        Entities.DispatchSpawn(new_hands)
        DoEntFire("!self", "SetParent", "!activator", 0, hands, new_hands)
        new_hands.DisableDraw()

        local new_vm = null
        new_vm = Entities.CreateByClassname("tf_wearable_vm")
        new_vm.ValidateScriptScope()
        local new_vm_scope = new_vm.GetScriptScope()
        new_vm_scope["viewmodelWeapon"] <- wpn
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
        new_vm.SetModelSimple(RL_VIEWMODELS[wpn_scope["equippedIndex"]])
        NetProps.SetPropEntity(new_vm, "m_hWeaponAssociatedWith", wpn)
        NetProps.SetPropEntity(wpn, "m_hExtraWearableViewModel", new_vm)
        new_vm.__KeyValueFromString("targetname", "fake_beggars_" + this)
        Entities.DispatchSpawn(new_vm)
        DoEntFire("!self", "SetParent", "!activator", 0, new_hands, new_vm)

        wpn_scope["modelSwap"] <- function() {
            local owner = NetProps.GetPropEntity(self, "m_hOwner")
            if (owner == null) {
                return 1
            }
            local wpn = owner.GetActiveWeapon()
            if (wpn == null) {
                return 1
            }
            if (this["equippedIndex"] == 513) {
                wpn.SetCustomViewModel("models/weapons/c_models/c_soldier_arms_og.mdl")
            }
            local oldhands = NetProps.GetPropEntity(owner, "m_hViewmodel")
            local custom_vm = this["customVM"]
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

        wpn_scope["customVM"] <- new_vm
        wpn_scope["customVMHands"] <- new_hands
    }
}