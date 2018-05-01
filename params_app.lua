local method, path = ...
print(method, path)
if method == "POST" then
	if (_GET.master_code1 or _GET.master_code0) and _GET.master_code0 == pcchrono.master_code and _GET.master_code1 == _GET.master_code2 then
		pcchrono.master_code = _GET.master_code1
		print("Master code modified")
	end
	if (_GET.admin_code1 or _GET.admin_code0) and _GET.admin_code0 == pcchrono.admin_code and _GET.admin_code1 == _GET.admin_code2 then
		pcchrono.admin_code = _GET.admin_code1
		print("Admin code modified")
	end
	if _GET.decimal_separator then
		pcchrono.decimal_separator = _GET.decimal_separator
	end
	local f_pcchrono = file.open("pcchrono.cfg","w")
	f_pcchrono.writeline(sjson.encode(pcchrono))
	f_pcchrono.close()
end
return server.read_file("params_app.html", _GET)