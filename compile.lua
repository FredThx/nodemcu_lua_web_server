for name,size  in pairs(file.list()) do
    if (string.match(name,".*%.lua") and name ~="init.lua") then
        node.compile(name)
        file.remove(name)
        print(name .. " compiled")
    end
end


