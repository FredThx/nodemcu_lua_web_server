if file.exists("compile.lc") then
    dofile("compile.lc")
else
    dofile("compile.lua")
end
dofile("main.lc")
