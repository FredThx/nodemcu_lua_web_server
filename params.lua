local method, path = ...
if method == "POST" and _GET.wifi_mode then
	for k,v in pairs(_GET) do
		if not string.match(k, "_.*") then
			server.params[k]=v
		end
	end
	dofile("save_params.lc")
	tmr.alarm(3,1000,tmr.ALARM_SINGLE, node.restart)
end
return server.read_file("params.html", _GET)