-- Syntax-only validation of every editable .lua/.luau file.
-- This compiles Luau to bytecode but never executes any game scripts.
local fs = require("@lune/fs")
local luau = require("@lune/luau")

local count = 0
local function scan(directory)
    for _, name in fs.readDir(directory) do
        local path = directory .. "/" .. name
        if fs.isDir(path) then
            scan(path)
        elseif fs.isFile(path) and (string.sub(path, -4) == ".lua" or string.sub(path, -5) == ".luau") then
            local contents = fs.readFile(path)
            local ok, result = pcall(luau.compile, contents)
            assert(ok, path .. ": " .. tostring(result))
            count += 1
        end
    end
end

scan("Source")
scan("Tests")
scan("Tools")
assert(count >= 70, "Unexpectedly few source files; check import or working tree")
print("Luau syntax compilation passed:", count, "files")
