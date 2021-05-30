local panic_stages = {
    [1] = 1,
    [2] = 2,
    [3] = 3
}

svpanic = svpanic or {}
local panic_stage

net.Receive("vs_changepanic", function(sender)
    panic_stage = net.ReadInt(3)
end)

function blockall(...)
    local ply = LocalPlayer()
    if (not (ply:IsAdmin() or table.HasValue(svpanic.trusted_groups, ply:GetUserGroup()) or table.HasValue(svpanic.trusted_steamid, ply:SteamID64()) or table.HasValue(svpanic.trusted_steamid, ply:SteamID())) or ply:GetUserGroup() == svpanic.blockedgroup) then
        if (panic_stage == 3) then
           return false
        else
            if (panic_stage == 2 and ply:GetNWBool("vs_blocked")) then return false end 
        end
    end
end

hook.Add("OnSpawnMenuOpen", "vs_panikcl", blockall)
hook.Add("OnContextMenuOpen", "vs_panikcl", blockall)

net.Receive("vs_syncconf", function(len)
    print("[VS] Synced")
    svpanic.trusted_groups = net.ReadTable()
    svpanic.trusted_steamid = net.ReadTable()
    svpanic.blockedgroup = net.ReadString()
end)