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
	-- Gestion des includes
	txt = string.gsub(txt,"<#include [^#<>]*#>", function(include_filename)
			local txt_include = ""
			include_filename = string.gsub(include_filename, "<#include ","")
			include_filename = string.gsub(include_filename, "#>","")
			--print("include : ",include_filename,"ok")
			local include_fichier = file.open(include_filename,"r")
			if include_fichier then
				txt_include = include_fichier:read(1024*5)
				include_fichier:close()
			end
			return txt_include
		end)
	collectgarbage()
	-- Gestion des <?lua ...  ?>
	txt = string.gsub(txt,"<%?lua","§")
	txt = string.gsub(txt,"?>","²")
	txt =  string.gsub(txt,"§[^§²]*²",function(cmd)
			cmd = string.gsub(cmd, "§","")
			cmd = string.gsub(cmd, "²","")
			--print(node.heap(),cmd)
			local err, val = pcall(loadstring("return " .. cmd))
			--print(node.heap(),val)
			return val
		end)
	print(node.heap())
	collectgarbage()
	return txt
end