-----------------------------------------------------------------------
--
-- Projet : PC-CHRONO
----------------------------------------------------------------------
-- Lecture des capteurs (= recepteur IR)
--
--  Usage :
--              _dofile('lecture_capteurs")
--				remplissage de pcchrono.results
--  exemple :
-- pcchrono.results[1] = {on = 1, off = 2}
			-- pcchrono.results[2] = {on = 3, off = 4}
			-- pcchrono.results[3] = {on = 5, off = 6}
			-- pcchrono.results[4] = {on = 7, off = 8}
			-- pcchrono.results[5] = {on = 9, off = 10}
			-- pcchrono.results[6] = {on = 11, off = 12}
----------------------------------------------------------------------
-- Auteur : FredThx
----------------------------------------------------------------------

do
	local timeout = 1000 --ms
	local start
	local results = {}
	pcchrono.run = true
	
	print("Lecture des capteurs pendant "..timeout .. "ms.")
	
	-- Gère le passage du compteur de temps à zero
	local function delta(delta)
			if delta < 0 then 
				delta = delta + 2147483647
			end
			return delta
		end
	
	-- Un trigueur sur chaque fourche
	-- Init results
	-- Pour optimiser, on ne fait que remplir une liste de mesures, le tri se fera ensuite
	for k, fourche in pairs(pcchrono.fourches) do
		gpio.mode(fourche.pin,gpio.INT)
		pcchrono.results[k] = {on=nil, off=nil}	
		gpio.trig(fourche.pin,"both",function(level, now)
				table.insert(results, {k,level,now})
			end)
	end

    -- Mesure	
    -- après une attente de 1s pour être sur que le µc soit bien libre.
    tmr.alarm(1,1000, tmr.ALARM_SINGLE, function()
            --Lachage de boule
	        gpio.write(pcchrono.aimant.pin,gpio.LOW)
	        start = tmr.now()
        
        	-- après timeout, eteint les trigueurs
        	tmr.alarm(2,timeout, tmr.ALARM_SINGLE, function()
        			print("Resultats :")
        			print(sjson.encode(results))
        			for k, fourche in pairs(pcchrono.fourches) do
        				gpio.trig(fourche.pin, "none")
        				for i, result in ipairs(results) do
        					if result[1]==k then
        						if result[2]==gpio.LOW then
        							pcchrono.results[k].on = delta(result[3]-start)
        						else
        							pcchrono.results[k].off = delta(result[3]-start)
        						end
        					end
        				end
        				--print("Fourche "..k.." on at " .. (pcchrono.results[k].on or "???") .. " microsecondes")
        				--print("Fourche "..k.." off at " .. (pcchrono.results[k].off or "???") .. " microsecondes")
        			end
        			pcchrono.run = false
        		end)
        end)
end
