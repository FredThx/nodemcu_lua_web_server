-----------------------------------------------------------------------
--
-- Projet : Serveur Web 100% local
-----------------------------------------------------------------------
-- Module representant un serveur web    
-----------------------------------------------------------------------
-- Usage :                               
--          server = dofile("server.lua")
--          server.http_pages['/'] = function (method, path, _GET)
--                      return server.read_file("index.html")
--                  end
--      avec dans index.html
--              - du code html
--              - balise <?lua unefonctionlua() ?>
--                  où unefonctionLua() retourne un string qui va bien
----------------------------------------------------------------------
-- Auteur : FredThx
----------------------------------------------------------------------

local M = {}
local defaut = {
    ssid = "ESP8266",
    pwd = "12345678",
    ip = "192.168.68.1",
    mask = "255.255.255.0",
    dhcp_start = "192.168.68.10"
}
do
    -- Read a file and execute lua code in <?lua ... >?>
	-- attention un peu de bricolage lie au limitation des pattern en lua
	-- les caracteres § et ² sont interdit dans les pages html !!!!
    local function read_file(filename)
        if file.open(filename, "r") then
			local txt = file.read(1024*5)
			file.close()
			txt = string.gsub(txt,"<%?lua","§")
			txt = string.gsub(txt,"?>","²")
			return  string.gsub(txt,"§[^§²]*²",function(cmd)
                    cmd = string.gsub(cmd, "§","")
                    cmd = string.gsub(cmd, "²","")
                    return loadstring("return " .. cmd)() -- TODO gerer erreur et renvoyer texte erreur
                end)
        end
    end
    M.read_file = read_file
    M.http_pages = {}
	M.params = {}
	local function save_params()
		local f_params = file.open("params.json","w")
		f_params:write(sjson.encode(M.params))
		f_params:write('\r\n')
		f_params:close()
	end
	M.save_params = save_params
    -- Lecture des paramètres
    local f_params = file.open("params.json","r")
    if f_params then
		if pcall(function() 
					M.params = sjson.decode(f_params:read(2*1024)) 
				end) then -- limite a 2*1024 bytes
			print("lecture parametres du serveur :", sjson.encode(M.params))
		else
			print("Error reading params.json") 
		end
        f_params:close()
    end
    if not M.params["wifi_mode"] then M.params["wifi_mode"]="ap" end
    if not M.params["wifi_ssid"] then M.params["wifi_ssid"]=defaut.ssid end
    if not M.params["wifi_pwd"] then M.params["wifi_pwd"]=defaut.pwd end
    station_cfg={}
    station_cfg.ssid = M.params["wifi_ssid"]
    station_cfg.pwd = M.params["wifi_pwd"]
    -- WIFI configuration
    if M.params["wifi_mode"]=='sta' then
        wifi.setmode(wifi.STATION)
        wifi.sta.config(station_cfg)
    else
        wifi.setmode(wifi.SOFTAP)
        --wifi.cfg.auth=wifi.OPEN
        if not pcall(function() wifi.ap.config(station_cfg) end) then
            wifi.ap.config({ssid=defaut.ssid, pwd=defaut.pwd})
        end
        wifi.ap.setip({ip=defaut.ip, netmask=defaut.mask, gateway=defaut.ip})
        wifi.ap.dhcp.config({start = defaut.dhcp_start})
        wifi.ap.dhcp.start()
    end
    
    -- Attend la connexion wifi...
    tmr.alarm(1,1000,tmr.ALARM_AUTO, function()
        if (wifi.sta.getip() or wifi.ap.getip()) then
            tmr.stop(1)
            print("WIFI connected")
            if wifi.sta.getip() then
                print(wifi.sta.getip())
            else
                print(wifi.ap.getip())
            end
            srv=net.createServer(net.TCP, 30)
            -- Ecoute du port 80 .. et reponse.
            if srv then
              srv:listen(80, function(conn)
                conn:on("receive", function(sck, request)
						--sck.hold()
						print("http requeste receive.")
						if M.buffer == nil then
							M.buffer = request
						else
							M.buffer = M.buffer .. request
						end
						-- A opimiser en une seule ligne
						if string.find(M.buffer, 'GET.*\r\n\r\n') 
							or string.find(M.buffer, 'POST.*\r\n.*\r\n') 
						then
							http_response(sck,M.buffer)
							M.buffer = ""
							print("buffer cleared.")
						else
							print("http request buffered.")
						end
						--sck.unhold()
					end)
				end)
            end
			print("http server is active.")
		end
    end)
	--Lecture de la requette http
	--Parse
	--Find page to send
	--Send response
	function http_response(sck, request)
		--print("Request receive : ")
		--print("BEGIN")
		--print(request)
		--print("END")
		--Parse la requete http
		local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP")
		if (method == nil) then
			_, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP")
		end
		if method == "POST" then
			vars = string.sub(string.match(request,"\r\n\r\n.*"),5)
		end
		local _GET = {}
		if vars then
			for k, v in string.gmatch(vars, "([%w_]+)=([%w_]+)&*") do
				--print(k,v)
				_GET[k] = v
			end
		end
		print("Method :", method, "Path : ", path, "Vars : ", vars)
		if method and path then
			--Selon http_pages[path], renvoie la reponse
			local response, status
			if M.http_pages[path] then
				response = M.http_pages[path](method, path, _GET)
				status = "200 OK"
			else -- Si pas reference, essaye quand meme de charger la page
				print("Read unrecorded file :", path)
				response = M.read_file(string.sub(path,2))
				print(node.heap())
				if response then
					status = "200 OK"
				else
					response = "<html><body><p>" .. path .. " doesn't exist.</p></body></html>"
					status = "404 Not Found"
				end
			end
			print("Send http response...")
			sck:send("HTTP/1.1 " .. status .. "\r\nConnection: keep-alive\r\nCache-Control: private, no-store\r\nContent-Length: " .. #response .. "\r\n\r\n" .. response
					, function(sk)
					sk:close()
				  end)
		end
		collectgarbage()
	end
end
return M