module("luci.controller.filecopy.filecopy", package.seeall)

function index()
	entry({"admin", "services", "filecopy"}, call("handle_index"), _("File Copy"))
	entry({"admin", "services", "filecopy", "result"}, call("handle_result"), _("Result"))
end



function handle_index()
	require("luci.fs")
	require("nixio.fs")
	require("nixio.util")
	
	local validSource = false
	local source = luci.http.formvalue("source") or '/mnt/'
	local newSource = luci.http.formvalue("newSource") or ""
	if newSource ~= '' then
		source = newSource
	end

	local sourceStat = nixio.fs.stat(source)
	local sourceText = "The source is a BROKEN path"
	local sourceEntries = {}
	local sourceUp = '/'
	if sourceStat then
		sourceUp = luci.fs.dirname(source)
		if sourceUp ~= '/' then
			sourceUp = sourceUp..'/'
		end
		
		if sourceStat.type == "dir" then
			sourceEntries = nixio.util.consume((nixio.fs.dir(source)))
			local haveFiles = table.getn(sourceEntries) > 0
			if haveFiles then
				sourceText = "Will copy the contents of folder"
				validSource = true
			else
				sourceText = "Can't copy this folder as it is empty"
			end
		elseif sourceStat.type == "reg" then
			sourceText = "Will copy the file"
			validSource = true
		end
	end
	
	
	local validDestination = false
	local destination = luci.http.formvalue("destination") or '/mnt/'
	local newDestination = luci.http.formvalue("newDestination") or ""
	if newDestination ~= '' then
		destination = newDestination
	end
	
	local destinationStat = nixio.fs.stat(destination)
	local destinationEntries = {}
	local destinationUp = '/'
	if destinationStat then
		destinationUp = luci.fs.dirname(destination)
		if destinationUp ~= '/' then
			destinationUp = destinationUp..'/'
		end
		
		if destinationStat.type == "dir" then
			destinationEntries = nixio.util.consume((nixio.fs.dir(destination)))
			validDestination = true
		end
	end
	
	
	local canCopy = validSource and validDestination
	local copyUrl = luci.dispatcher.build_url("admin/services/filecopy/result")
	if source == destination then
		canCopy = false
	end
	
	luci.template.render("index", {
		sourceEntries = sourceEntries
		,source = source
		,sourceText = sourceText
		,sourceUp = sourceUp
		,destination = destination
		,destinationEntries = destinationEntries
		,destinationUp = destinationUp
		,canCopy = canCopy
		,copyUrl = copyUrl
	})
end



function handle_result()
	luci.template.render("result", {
		
	})
end