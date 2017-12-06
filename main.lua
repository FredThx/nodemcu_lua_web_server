-----------------------------------------------------------------------
--
-- Projet : Serveur Web 100% local
----------------------------------------------------------------------
-- C'est le main 
----------------------------------------------------------------------
-- Auteur : FredThx
----------------------------------------------------------------------

server = _dofile("server")

_dofile("controleur")
_dofile("pages")

--Lecture fichier de config
if file.open("pcchrono.cfg", "r") then
	local txt = file.read()
	print("read pcchrono.cfg : " .. txt)
	local ok, json = pcall(sjson.decode, txt)
	print("decode : ",ok)
	if ok then pcchrono = json end
end
if not pcchrono then
	pcchrono = {}
	pcchrono.aimant = {pin=1}
	pcchrono.bille = {diam = 17, masse = 33}
	pcchrono.fourches = {}
	pcchrono.fourches[1] = {pin = 2, d = 2}
	pcchrono.fourches[2] = {pin = 3, d = 3}
	pcchrono.fourches[3] = {pin = 4, d = 4}
	pcchrono.fourches[4] = {pin = 5, d = 5}
	pcchrono.fourches[5] = {pin = 6, d = 6}
	pcchrono.fourches[6] = {pin = 7, d = 7}
end
pcchrono.results = {}
pcchrono.run = false

gpio.mode(pcchrono.aimant.pin,gpio.OUTPUT)
gpio.write(pcchrono.aimant.pin,gpio.LOW)
for k, fourche in pairs(pcchrono.fourches) do
	gpio.mode(fourche.pin, gpio.INPUT) --?? pullup
end
