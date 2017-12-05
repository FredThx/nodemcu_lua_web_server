-----------------------------------------------------------------------
--
-- Projet : Serveur Web 100% local
----------------------------------------------------------------------
-- description des pages html à charger
--
--  Usage :
--              server.http_pages[path] = function(method, path, _GET)
--                          do_actions()
--                          return server.read_file("fichier.html")
--                  ou server = dofile("server.lua")
--
--   Si la page n'est pas reference, elle est charge si existe en memoire flash
--  Interet de la reference : ajouter des traitements
----------------------------------------------------------------------
-- Auteur : FredThx
----------------------------------------------------------------------

server.http_pages['/params.html'] = function (method, path, _GET)
    if method == "POST" then
        for k,v in pairs(_GET) do
            server.params[k]=v
        end
        _dofile("set_params")
        node.restart()
    end
    return server.read_file("params.html")
end

server.http_pages['/'] = function (method, path, _GET)
        if _GET["action"]=='ON' then
            gpio.write(pcchrono.aimant.pin,gpio.HIGH)
        end
        if _GET["action"]=='OFF' then
            gpio.write(pcchrono.aimant.pin,gpio.LOW)
        end
        return server.read_file("index.html")
    end

server.http_pages['/pcchrono.html'] = function (method, path, _GET)
		if _GET["action"]=='aimant_change' then
            if (gpio.read(pcchrono.aimant.pin)==gpio.HIGH) then
                gpio.write(pcchrono.aimant.pin,gpio.LOW)
            else
                gpio.write(pcchrono.aimant.pin,gpio.HIGH)
            end
        elseif _GET["action"]=='go' then
			if not pcchrono.run then
				_dofile("lecture_capteurs")
			end
		elseif _GET["action"]=='raz' then
			pcchrono.results={}
		end
        return server.read_file("pcchrono.html")
    end

	
server.http_pages['/distances.html'] = function (method, path, _GET)
	if _GET["diametre_bille"] then
		pcchrono.aimant.diam = tonumber(_GET["diametre_bille"])
		for k, fourche in pairs(pcchrono.fourches) do
			fourche.d=tonumber(_GET["cellule_"..k])
		end
		local f_pcchrono = file.open("pcchrono.cfg","w")
		f_pcchrono.writeline(sjson.encode(pcchrono))
		f_pcchrono.close()
	end
	return server.read_file("distances.html")
end
