-----------------------------------------------------------------------
--
-- Projet : Serveur Web 100% local
-----------------------------------------------------------------------
-- Read a file and execute lua code in <?lua ... >?>
-----------------------------------------------------------------------
-- attention un peu de bricolage lie au limitation des pattern en lua
-- les caracteres § et ² sont interdit dans les pages html !!!!
--
----------------------------------------------------------------------
-- Auteur : FredThx
----------------------------------------------------------------------

	
local filename = ...
local fichier = file.open(filename, "r")
if  fichier then
	local txt = fichier:read(1024*5) -- TODO : lecture bloc par bloc (au moins les non html)
	fichier:close()
	-- Gestion des <?lua ...  ?>
	txt = string.gsub(txt,"<%?lua","§")
	txt = string.gsub(txt,"?>","²")
	return string.gsub(txt,"§[^§²]*²",function(cmd)
			cmd = string.gsub(cmd, "§","")
			cmd = string.gsub(cmd, "²","")
			--print(node.heap(),cmd)
			local err, val = pcall(loadstring("return " .. cmd))
			--print(node.heap(),val)
			return val
		end)
end