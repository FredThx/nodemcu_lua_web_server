-----------------------------------------------------------------------
-- Projet : Serveur Web 100% local
----------------------------------------------------------------------
-- description :  des fonctions utilisé dans le code html
----------------------------------------------------------------------
-- Auteur : FredThx
----------------------------------------------------------------------

function get_checked(mode)
    if server.params["wifi_mode"]==mode then
        return "checked"
    else
        return ""
    end
end

function get_param(param)
    return server.params[param]
end

-- function get_aimant()
    -- if (gpio.read(1)==gpio.HIGH) then
        -- return "Aimant Activé"
    -- else
        -- return "Aimant Off"
    -- end
-- end

function get_go_disable()
	if (gpio.read(1)==gpio.HIGH) then
		return ""
	else
		return "disabled"
	end
end

function get_result_disable()
		if pcchrono.results[1]==nil then
			return "hidden"
		else
			return ""
		end
end

function get_results()
		if pcchrono.run then
			return "en cours"
		else
			return sjson.encode(pcchrono.results)
		end
end

function get_distance(no_fourche)
	if no_fourche==0 then
		return pcchrono.aimant.diam
	else
		return pcchrono.fourches[no_fourche].d
	end
end