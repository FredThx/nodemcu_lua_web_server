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
local response_chunk_size = 1024*2


do
	M.http_pages = {}
	M.params = {}
	M.buffer = {}
	-- Read a file and execute lua code in <?lua ... >?>
	-- attention un peu de bricolage lie au limitation des pattern en lua
	-- les caracteres § et ² sont interdit dans les pages html !!!!
    local function read_file(filename)
		local fichier = file.open(filename, "r")
        if  fichier then
			local txt = fichier:read(1024*5) -- TODO : lecture bloc par bloc (au moins les non html)
			fichier:close()
			--if string.find(filename, ".*%.html") then  -- en fait ce que ça fait gagner, on le perd a augmenter le poids de cette fonction
				txt = string.gsub(txt,"<%?lua","§")
				txt = string.gsub(txt,"?>","²")
				return  string.gsub(txt,"§[^§²]*²",function(cmd)
						cmd = string.gsub(cmd, "§","")
						cmd = string.gsub(cmd, "²","")
						--print(node.heap(),cmd)
						local err, val = pcall(loadstring("return " .. cmd))
						--print(node.heap(),val)
						return val
					end)
			--else
			--	return txt
			--end
        end
    end
    M.read_file = read_file

	

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
						------------------------------------------
						-- A LA RECEPTION DE DONNES --------------
						------------------------------------------
						sck:hold()
						--print("http requeste receive.",sck, "hold")
						------------------------------------------
						-- ON COMMENCE PAS VERIFIER QUE L ON A ---
						-- BIEN TOUT LE REQUETE SINON BUFFER -----
						------------------------------------------
						if M.buffer[sck] then
							M.buffer[sck] = M.buffer[sck] .. request
						else
							M.buffer[sck] = request
						end
						if string.find(M.buffer[sck], 'GET.*\r\n\r\n') 
							or string.find(M.buffer[sck], 'POST.*\r\n.*\r\n') 
						then
							------------------------------------------
							-- SI LA REQUETTE EST COMPLETE -----------
							------------------------------------------
							--print("Request receive : ")
							--print("BEGIN")
							--print(M.buffer[sck])
							--print("END")
							---------------------------------------------
							-- PARSE LA REQUETTE => METHOD, PATH, VARS --
							---------------------------------------------
							local _, _, method, path, vars = string.find(M.buffer[sck], "([A-Z]+) (.+)?(.+) HTTP")
							if (method == nil) then
								_, _, method, path = string.find(M.buffer[sck], "([A-Z]+) (.+) HTTP")
							end
							if method == "POST" then
								vars = string.sub(string.match(M.buffer[sck],"\r\n\r\n.*"),5)
							end
							local _GET = {}
							if vars then
								for k, v in string.gmatch(vars, "([%w_]+)=([%w_]+)&*") do
									_GET[k] = v
								end
							end
							print(sck, node.heap(), "Method :", method, "Path : ", path, "Vars : ", vars)
							if method and path then
								------------------------------------------
								-- SI LA REQUETTE EST VALIDE : -----------
								--                  ... REPONSE ----------
								------------------------------------------
								local responses = {}
								local response 
								local status="200 OK"
								------------------------------------------
								-- SELON pages.lua et fichiers -----------
								--     => REPONSE              -----------
								------------------------------------------
								if M.http_pages[path] then -- page referencee
									response = M.http_pages[path](method, path, _GET)
								elseif file.exists(string.sub(path,2)) then -- page non reference mais existante
									response = M.read_file(string.sub(path,2))
								else -- pas inexistante
									status = "404 Not Found"
									response = "<html><body><p>" .. path .. " doesn't exist.</p></body></html>"
								end
								collectgarbage()
								print(sck, "****",node.heap())
								responses[1]="HTTP/1.1 " .. status .. "\r\nConnection: keep-alive\r\nCache-Control: private, no-store\r\nContent-Length: " .. #response .. "\r\n\r\n"
								print(sck, "response prepared",node.heap())
								------------------------------------------
								-- ON COUPE LA REPONSE EN BOUTS  ---------
								------------------------------------------
								responses[1]=responses[1]..response:sub(1,response_chunk_size-#responses[1])
								for i=#responses[1]+1, #response, response_chunk_size do
									responses[#responses+1] = response:sub(i,i + response_chunk_size - 1)
								end
								response = nil
								--print(sjson.encode(responses))
								collectgarbage()
								print(sck, "responses chunked",node.heap())
								------------------------------------------
								-- FONCTION RECURSIVE QUI FAIT LES SEND --
								------------------------------------------
								local function send_chunk(sk) --todo mettre fonction ailleurs
									local chunk
									if #responses > 0 then
										chunk = responses[1]
										table.remove(responses,1)
										print(sk, "chunk of",#chunk,"heap :",node.heap())
										sk:send(chunk, send_chunk)
									else
										sk:close()
										--collectgarbage()
									end
								end
								send_chunk(sck)
							end
							collectgarbage()
							M.buffer[sck] = nil
							--print("buffer cleared.")
						--else
							--print("http request buffered.")
						end
						sck:unhold()
					end)
				end)
            end
			print("http server is active.")
		end
    end)
end
return M