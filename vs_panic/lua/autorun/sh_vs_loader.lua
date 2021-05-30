local rootDir = "vs"
vsloader = vsloader or {}
if (vsloader.isloaded) then return false end
vsloader.isloaded = true

local function AddFile(File, dir)
    local fileSide = string.lower(string.Left(File, 3))

    if SERVER and fileSide == "sv_" then
        include(dir .. File)
        MsgN("[LOADVS] SV INCLUDE: " .. File)
    elseif fileSide == "sh_" then
        if SERVER then
            AddCSLuaFile(dir .. File)
            MsgN( "[LOADVS] SH ADDCS: " .. File)
        end

        include(dir .. File)
        MsgN( "[LOADVS] SH INCLUDE: " .. File )
    elseif fileSide == "cl_" then
        if SERVER then
            AddCSLuaFile(dir .. File)
            MsgN( "[LOADVS] CL ADDCL: " .. File )
        elseif CLIENT then
            include(dir .. File)
            MsgN( "[LOADVS] CL INCLUDE: " .. File )
        end
    end
end

local function IncludeDir(dir)
    dir = dir .. "/"
    local File, Directory = file.Find(dir .. "*", "LUA")

    for k, v in ipairs(File) do
        if string.EndsWith(v, ".lua") then
            AddFile(v, dir)
        end
    end

    for k, v in ipairs(Directory) do
        MsgN( "==================================")
        MsgN( "[LOADVS] Directory: " .. v )
        IncludeDir(dir .. v)
    end
end

local function load()
    -- Fancy shit
    MsgN( "==================================")
    MsgN( "==========Loading VS==============")
    MsgN( "==================================")
    IncludeDir(rootDir)
    MsgN( "==================================")
    MsgN( "==========   Fertig   ============")
    MsgN( "==================================")
end

hook.Add("Initialize", "VS_Loader", load())