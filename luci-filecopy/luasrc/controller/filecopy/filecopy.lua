module("luci.controller.filecopy.filecopy", package.seeall)

--http://luci.subsignal.org/api/luci/index.html
require("luci.dispatcher")
require("luci.fs")
require("luci.sys")

--http://luci.subsignal.org/api/nixio/index.html
require("nixio.fs")
require("nixio.util")


function index()
	entry({"admin", "services", "filecopy"}, call("handle_index"), _("File Copy"))
	entry({"admin", "services", "filecopy", "contentsof"}, call("action_contentsof"))
	entry({"admin", "services", "filecopy", "cancopy"}, call("action_cancopy"))
	entry({"admin", "services", "filecopy", "copy"}, call("action_copy"))
	entry({"admin", "services", "filecopy", "results"}, call("handle_results"), _("Results"))
end



function handle_index()
	luci.template.render("index", {})
end



function handle_results()
	luci.template.render("result", {})
end



function action_contentsof()
	local path = luci.http.formvalue("path")
	
	local entries = {}
	if path ~= '/' then
		table.insert(entries, {
			name = ".."
			,path = luci.fs.dirname(path) .. '/'
			,type = "dir"
		})
	end
	
	local stat = nixio.fs.stat(path)
	if stat then
		if stat.type == "dir" then
			local direntries = nixio.util.consume((nixio.fs.dir(path)))
			for _, entryName in ipairs(direntries) do
				local fullDirPath = path..entryName
				local dirStat = nixio.fs.stat(fullDirPath) or {}
				if dirStat.type == "dir" then
					fullDirPath = fullDirPath .. '/'
				end
				table.insert(entries, {
					name = entryName
					,path = fullDirPath
					,type = dirStat.type
				})
			end
		end
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json({
		entries = entries
	})
end



function action_cancopy()
	local source = luci.http.formvalue("source")
	local validSource = false
	local sourceStat = nixio.fs.stat(source)
	if sourceStat then
		if sourceStat.type == "dir" then
			sourceEntries = nixio.util.consume((nixio.fs.dir(source)))
			local haveFiles = table.getn(sourceEntries) > 0
			if haveFiles then
				validSource = true
			end
		elseif sourceStat.type == "reg" then
			validSource = true
		end
	end
	
	local destination = luci.http.formvalue("destination")
	local validDestination = false
	local destinationStat = nixio.fs.stat(destination)
	if destinationStat then
		if destinationStat.type == "dir" then
			validDestination = true
		end
	end
	
	local method = luci.http.formvalue("method")
	local validMethod = true
	local methods = {backup=1, noclobber=1, update=1, overwrite=1}
	if methods[method] then
		validMethod = true
	end
	
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		valid = validSource and validDestination and validMethod
	})
end



function action_copy()
	local filepath = "/tmp/filecopy.".. os.date("%Y%m%d%H%M%S")
	
	local source = luci.http.formvalue("source")
	local sourceStat = nixio.fs.stat(source)
	local sourceFolder = false
	if sourceStat.type == "dir" then
		sourceFolder = true
	end
	
	local destination = luci.http.formvalue("destination")
	local destinationStat = nixio.fs.stat(destination)
	if destinationStat.type ~= "dir" then
		error("destination not a dir")
	end
	
	local method = luci.http.formvalue("method")
	
	local script = "/sbin/noisycopy"
	if sourceFolder then
		script = script.." r"
	end
	if method == "overwrite" then
		script = script.." overwrite"
	end
	script = script.." \""..source.."\""
	script = script.." \""..destination.."\""
	script = script.." >> \""..filepath.."\""
	script = script.." &"
	
	nixio.fs.writefile(filepath, script.."\n\n")
	luci.sys.exec(script)
	
	-- write parameters to log file
	-- create command to do the copy, append into log file
	local redirectUrl = luci.dispatcher.build_url("admin/services/filecopy/results")
	luci.http.redirect(redirectUrl)
end