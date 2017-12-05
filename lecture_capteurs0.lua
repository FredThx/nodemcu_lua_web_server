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

local timeout = 1*1000 --ms
print("Lecture des capteurs pendant "..timeout .. "ms.")

local function delta(delta)
		if delta < 0 then 
			delta = delta + 2147483647
		end
		return delta
	end

pcchrono.run = true
	
-- Un trigueur sur chaque fourche
-- Init results
for k, fourche in pairs(pcchrono.fourches) do
	gpio.mode(fourche.pin,gpio.INT)
	pcchrono.results[k] = {on=nil, off=nil}	
	gpio.trig(fourche.pin,"both",function(level, now)
			--now = delta(now - pcchrono.start)
			if (level == 0) then
				--print("Fourche n°"..k.."detect on after "..now.."µs.")
				pcchrono.results[k].on = now
			else
				--print("Fourche n°"..k.."detect off after "..now.."µs.")
				pcchrono.results[k].off = now
			end
		end)
end

--Lachage de boule
gpio.write(pcchrono.aimant.pin,gpio.LOW)
pcchrono.start = tmr.now()

-- après timeout, eteint les trigueurs
tmr.alarm(1,timeout, tmr.ALARM_SINGLE, function()
		for k, fourche in pairs(pcchrono.fourches) do
			gpio.trig(fourche.pin, "none")
			print("Fourche "..k.." on at " .. (pcchrono.results[k].on or "???") .. " microsecondes")
			print("Fourche "..k.." off at " .. (pcchrono.results[k].off or "???") .. " microsecondes")
		end
		pcchrono.run = false
	end)