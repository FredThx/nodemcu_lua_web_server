do
	local f_params = file.open("params.json","w")
	f_params:write(sjson.encode(server.params))
	f_params:write('\r\n')
	f_params:close()
end