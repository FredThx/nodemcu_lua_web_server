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
local timeout = 1.5 * 1000000 --µs

local function delta(delta)
		if delta < 0 then 
			delta = delta + 2147483647
		end
		return delta
	end
for k, fourche in pairs(pcchrono.fourches) do
    gpio.mode(fourche.pin,gpio.INPUT)
    pcchrono.results[k] = {on=nil, off=nil} 
end

gpio.write(pcchrono.aimant.pin,gpio.LOW)
local start = tmr.now()
local now = start
timeout = start+timeout
for no, fourche in pairs(pcchrono.fourches) do
	--Attente passage cellule in
	--while (delta(now-start)<timeout and gpio.read(fourche.pin)==gpio.HIGH) do
	while (gpio.read(fourche.pin)==gpio.HIGH) and (now < timeout) do
		now = tmr.now()
	end
	pcchrono.results[no].on = now
	--Attente passage cellule out
	--while (delta(now-start)<timeout and gpio.read(fourche.pin)==gpio.LOW) do
	while (gpio.read(fourche.pin)==gpio.LOW) and (now < timeout) do
		now = tmr.now()
	end
		pcchrono.results[no].off = now
end

for k, fourche in pairs(pcchrono.fourches) do
    print("Fourche "..k.." on at " .. (pcchrono.results[k].on or "???") .. " microsecondes")
    print("Fourche "..k.." off at " .. (pcchrono.results[k].off or "???") .. " microsecondes")
end
