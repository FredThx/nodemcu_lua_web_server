-----------------------------------------------------------------------
-- Projet : Serveur Web 100% local
----------------------------------------------------------------------
-- description :  Enregistrement des paramètres
----------------------------------------------------------------------
-- Auteur : FredThx
----------------------------------------------------------------------
--TODO : tester arguments en entree : local server = ...
local f_params = file.open("params.cfg","w")
for k, v in pairs(server.params) do
    f_params.writeline(k.." : ".. v)
end
f_params.close()
