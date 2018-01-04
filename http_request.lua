-----------------------------------------------------------------------
--
-- Projet : Serveur Web 100% local
-----------------------------------------------------------------------
-- Fonction qui lit la requette http et renvoie une reponse
-----------------------------------------------------------------------
-- Usage :                               
--			srv=net.createServer(net.TCP, 30)
--				if srv then
--					srv:listen(80, function(conn)
--						conn:on("receive", function(sck, request)
--								assert(loadfile("http_request.lc"))(sck, request)
--							end)
--						end)
--					print("http server is active.")
--				end
--
----------------------------------------------------------------------
-- Auteur : FredThx
----------------------------------------------------------------------

local sck, request =...
local response_chunk_size = 1024*2
------------------------------------------
-- A LA RECEPTION DE DONNES --------------
------------------------------------------
sck:hold()
------------------------------------------
-- ON COMMENCE PAS VERIFIER QUE L ON A ---
-- BIEN TOUT LE REQUETE SINON BUFFER -----
------------------------------------------
if server.buffer[sck] then
	server.buffer[sck] = server.buffer[sck] .. request
else
	server.buffer[sck] = request
end
if string.find(server.buffer[sck], 'GET.*\r\n\r\n') 
	or string.find(server.buffer[sck], 'POST.*\r\n.*\r\n') 
then
	------------------------------------------
	-- SI LA REQUETTE EST COMPLETE -----------
	------------------------------------------
	--print("Request receive : ")
	--print("BEGIN")
	--print(server.buffer[sck])
	--print("END")
	---------------------------------------------
	-- PARSE LA REQUETTE => METHOD, PATH, VARS --
	---------------------------------------------
	local _, _, method, path, vars = string.find(server.buffer[sck], "([A-Z]+) (.+)?(.+) HTTP")
	if (method == nil) then
		_, _, method, path = string.find(server.buffer[sck], "([A-Z]+) (.+) HTTP")
	end
	if method == "POST" then
		vars = string.sub(string.match(server.buffer[sck],"\r\n\r\n.*"),5)
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
		local cache_control = "private, no-store"
		local status="200 OK"
		------------------------------------------
		-- SELON pages.lua et fichiers -----------
		--     => REPONSE              -----------
		------------------------------------------
		if server.http_pages[path] then
			if server.http_pages[path].http then -- page referencee
				response = server.http_pages[path].http(method, path, _GET)
			end
			if server.http_pages[path].cache then
				cache_control = "public, max-age=90000"
			end
		end
		if not response then
			if file.exists(string.sub(path,2)) then -- page non reference mais existante
				response = server.read_file(string.sub(path,2))
			else -- pas inexistante
				status = "404 Not Found"
				response = "<html><body><p>" .. path .. " doesn't exist.</p></body></html>"
			end
		end
		collectgarbage()
		--print(sck, "****",node.heap())
		responses[1]="HTTP/1.1 " .. status .. "\r\nConnection: keep-alive\r\nCache-Control: " .. cache_control  .. "\r\nContent-Length: " .. #response .. "\r\n\r\n"
		--print(sck, "response prepared",node.heap())
		------------------------------------------
		-- ON COUPE LA REPONSE EN BOUTS  ---------
		------------------------------------------
		local n = response_chunk_size-#responses[1]
		responses[1]=responses[1]..response:sub(1,n)
		for i=n+1, #response, response_chunk_size do
			responses[#responses+1] = response:sub(i,i + response_chunk_size - 1)
		end
		response = nil
		--print(sjson.encode(responses))
		collectgarbage()
		--print(sck, "responses chunked",node.heap())
		------------------------------------------
		-- FONCTION RECURSIVE QUI FAIT LES SEND --
		------------------------------------------
		local function send_chunk(sk) --todo mettre fonction ailleurs
			local chunk
			if #responses > 0 then
				chunk = responses[1]
				table.remove(responses,1)
				--print(sk, "chunk of",#chunk,"heap :",node.heap())
				sk:send(chunk, send_chunk)
			else
				sk:close()
			end
		end
		send_chunk(sck)
	end
	server.buffer[sck] = nil
	collectgarbage()
end
sck:unhold()
