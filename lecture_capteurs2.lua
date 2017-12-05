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
local timeout = 1 * 1000000 --µs

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
-- C'est moche!
local pin1 = pcchrono.fourches[1].pin
local pin2 = pcchrono.fourches[2].pin
local pin3 = pcchrono.fourches[3].pin
local pin4 = pcchrono.fourches[4].pin
local pin5 = pcchrono.fourches[5].pin
local pin6 = pcchrono.fourches[6].pin

results = {}

gpio.write(pcchrono.aimant.pin,gpio.LOW)
local start = tmr.now()
local now = start
timeout = start+timeout



-- Cellule 1
while (gpio.read(pin1)==1) and (now < timeout) do
	now = tmr.now()
end
table.insert(results ,now)
while (gpio.read(pin1)==0) and (now < timeout) do
	now = tmr.now()
end
table.insert(results ,now)
-- Cellule 2
while (gpio.read(pin2)==1) and (now < timeout) do
	now = tmr.now()
end
table.insert(results ,now)
while (gpio.read(pin2)==0) and (now < timeout) do
	now = tmr.now()
end
table.insert(results ,now)
-- Cellule 3
while (gpio.read(pin3)==1) and (now < timeout) do
	now = tmr.now()
end
table.insert(results ,now)
while (gpio.read(pin3)==0) and (now < timeout) do
	now = tmr.now()
end
table.insert(results ,now)
-- Cellule 4
while (gpio.read(pin4)==1) and (now < timeout) do
	now = tmr.now()
end
table.insert(results ,now)
while (gpio.read(pin4)==0) and (now < timeout) do
	now = tmr.now()
end
table.insert(results ,now)
-- Cellule 5
while (gpio.read(pin5)==1) and (now < timeout) do
	now = tmr.now()
end
table.insert(results ,now)
while (gpio.read(pin5)==0) and (now < timeout) do
	now = tmr.now()
end
table.insert(results ,now)
-- Cellule 6
while (gpio.read(pin6)==1) and (now < timeout) do
	now = tmr.now()
end
table.insert(results ,now)
while (gpio.read(pin6)==0) and (now < timeout) do
	now = tmr.now()
end
table.insert(results ,now)

local i =1
for k, fourche in pairs(pcchrono.fourches) do
    pcchrono.results[k].on = results[i]
	i=i+1
	pcchrono.results[k].off = results[i]
    print("Fourche "..k.." on at " .. (pcchrono.results[k].on or "???") .. " microsecondes")
    print("Fourche "..k.." off at " .. (pcchrono.results[k].off or "???") .. " microsecondes")
end
