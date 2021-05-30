if (CLIENT) then return end
util.AddNetworkString("vs_changepanic")
util.AddNetworkString("vs_initializepanic")
util.AddNetworkString("sv_getpanic")
util.AddNetworkString("vs_syncconf")

local panic_stages = {
    [1] = 1,
    [2] = 2,
    [3] = 3
}

svpanic = svpanic or {}
local panic_stage = panic_stage or 1

function disallowall(ply, ...)
    local args = {...}

    if (not (ply:IsAdmin() or table.HasValue(svpanic.config.trustedgroups, ply:GetUserGroup()) or table.HasValue(svpanic.config.trustedsteamid, ply:SteamID64()) or table.HasValue(svpanic.config.trustedsteamid, ply:SteamID())) or ply:GetUserGroup() == svpanic.config.blockedgroup) then
        if (panic_stage == 3) then
            return false
        else
            if (panic_stage == 2 and ply:GetNWBool("vs_blocked")) then return false end 
        end
    end
end

hook.Add("PhysgunPickup", "vs_panikphysgun", disallowall)
hook.Add("CanTool", "vs_panictool", disallowall)
hook.Add("CanPlayerUnfreeze", "vs_panicunfreeze", disallowall)
hook.Add("CanProperty", "vs_panicproperty", disallowall)
hook.Add("PlayerSpawnObject", "vs_panicobj", disallowall)
hook.Add("PlayerSpawnEffect", "vs_paniceffect", disallowall)
hook.Add("PlayerSpawnNPC", "vs_panicnpc", disallowall)
hook.Add("PlayerSpawnProp", "vs_panicprop", disallowall)
hook.Add("PlayerSpawnRagdoll", "vs_panicragdoll", disallowall)
hook.Add("PlayerSpawnSENT", "vs_panicsent", disallowall)
hook.Add("PlayerSpawnSWEP", "vs_panicswep", disallowall)
hook.Add("PlayerSpawnVehicle", "vs_panicveh", disallowall)
hook.Add("CanArmDupe", "vs_panicdupe", disallowall)

concommand.Add("panic", function(ply, cmd, args)
    if (CLIENT) then return false end
    local stage = 3

    if (args[1]) then
        stage = tonumber(args[1])
    end

    panic_stage = stage
    TellPlayers()
    Freezeallprops()
    net.Start("vs_changepanic")
    net.WriteInt(panic_stage, 3)
    net.Broadcast()
end)

concommand.Add("unpanic", function(ply, cmd, args)
    if (CLIENT) then return false end
    local stage = 1
    panic_stage = 1
    net.Start("vs_changepanic")
    net.WriteInt(panic_stage, 3)
    net.Broadcast()
    ply:SetNWBool("vs_blocked", false)
end)

concommand.Add("getpanic", function(ply, cmd, args)
    if (CLIENT) then return false end
    print(panic_stage)
end)

concommand.Add("getadmins", function(ply, cmd, args)
    if (CLIENT) then return false end

    for k, v in ipairs(player.GetHumans()) do
        print(v)
        print(v:IsAdmin())
    end
end)

hook.Add("PlayerInitialSpawn", "vs_setuppanic", function(pl)
    hook.Add("SetupMove", "VSSetup" .. pl:SteamID64(), function(ply, ...)
        if (ply:SteamID() == pl:SteamID()) then
            hook.Run("vssendtoplayer", ply)

            if (panic_stage == 2) then
                ply:SetNWBool("vs_blocked", true)
            end

            hook.Remove("SetupMove", "VSSetup" .. pl:SteamID64())
        end
    end)
end)

hook.Add("vssendtoplayer", "vs_setuppanikplayers", function(ply)
    net.Start("vs_changepanic")
    net.WriteInt(panic_stage, 3)
    net.Send(ply)
    net.Start("vs_syncconf")
    net.WriteTable(svpanic.config.trustedgroups)
    net.WriteTable(svpanic.config.trustedsteamid)
    net.WriteString(svpanic.config.blockedgroup)
    net.Send(ply)
end)

hook.Add("vs_getpanic", "vs_getpanicstatus", function() return panic_stage end)

function Freezeallprops()
    local entities = ents.GetAll()

    for k, ent in pairs(entities) do
        if (IsValid(ent) and not (ent:IsPlayer()) and ent:IsValid()) then
            local ply = ent:GetOwner()

            if (IsValid(ply) and not ply.IsAdmin == nil) then
                local physobj = ent:GetPhysicsObject()

                if (not (ply:IsAdmin() or table.HasValue(svpanic.config.trustedgroups, ply:GetUserGroup()) or table.HasValue(svpanic.config.trustedsteamid, ply:SteamID64()) or table.HasValue(svpanic.config.trustedsteamid, ply:SteamID())) or ply:GetUserGroup() == svpanic.config.blockedgroup) then
                    if (panic_stage == 3 and IsValid(physobj)) then
                        physobj:EnableMotion(false)
                    else
                        if (panic_stage == 2 and ply:GetNWBool("vs_blocked") and IsValid(physobj)) then
                            physobj:EnableMotion(false)
                        end
                    end
                end
            else
                local physobj = ent:GetPhysicsObject()

                if (IsValid(physobj)) then
                    physobj:EnableMotion(false)
                end
            end
        end
    end

    if (panic_stage > 1 and not timer.Exists("vs_freezeprops")) then
        timer.Create("vs_freezeprops", 3, 0, Freezeallprops)
    else
        if (panic_stage == 1 and timer.Exists("vs_freezeprops")) then
            timer.Remove("vs_freezeprops")
        end
    end
end

function TellPlayers()
    PrintMessage(4, "Der Server ist zurzeit in Panicmode d.h. Ihre Tätigkeiten sind eingeschränkt! ( Es dauert meistens nicht lange! )")

    if (panic_stage > 1 and not timer.Exists("vs_tellplayer")) then
        timer.Create("vs_tellplayer", 3, 0, TellPlayers)
    else
        if (panic_stage == 1 and timer.Exists("vs_tellplayer")) then
            timer.Remove("vs_tellplayer")
        end
    end
end

hook.Add("PlayerSay", "vs_panicsay", function(ply, text)
    if string.lower(text) == "!panic" then
        if (not ply:IsAdmin()) then return "" end
        ply:PrintMessage(3, "Panicmode aktiviert")
        RunConsoleCommand("panic", 3)

        return ""
    end

    if string.lower(text) == "!panic 2" then
        if (not ply:IsAdmin()) then return "" end
        ply:PrintMessage(3, "Panicmode aktiviert")
        RunConsoleCommand("panic", 2)

        return ""
    end

    if string.lower(text) == "!unpanic" then
        if (not ply:IsAdmin()) then return "" end
        ply:PrintMessage(3, "Panicmode deaktiviert")
        RunConsoleCommand("unpanic")

        return ""
    end
end)