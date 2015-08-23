module("luci.controller.filecopy.result", package.seeall)

--http://luci.subsignal.org/api/luci/index.html
require("luci.dispatcher")

--http://luci.subsignal.org/api/nixio/index.html
require("nixio.fs")
require("nixio.util")


function index()
	entry({"admin", "services", "filecopy", "results"}, call("handle_results"), _("Results"))
	entry({"admin", "services", "filecopy", "result_remove"}, call("action_remove"))
end



function action_remove()
	local path = luci.http.formvalue("path")
	nixio.fs.remove(path)
	
	local redirectUrl = luci.dispatcher.build_url("admin/services/filecopy/results")
	luci.http.redirect(redirectUrl)
end


function handle_results()
	local rawResults = {}
	
	local tempFiles, matches = nixio.util.consume((nixio.fs.glob("/tmp/filecopy.*")))
	for _, tempFile in ipairs(tempFiles) do
		local stat = nixio.fs.stat(tempFile)
		if stat.type == "reg" then
			local fileName = nixio.fs.basename(tempFile)
			local contents = nixio.fs.readfile(tempFile, 10485760)
			rawResults[fileName] = {
				fileName = fileName
				,filePath = tempFile
				,contents = contents
				,created = stat.ctime
				,modified = stat.mtime
			}
		end
	end
	
	-- sort by the key (filename) then insert it in reverse so the latest result appears at the top
	local orderedResults = {}
	for k,v in luci.util.kspairs(rawResults) do
		table.insert(orderedResults, 0, v)
	end
	
	luci.template.render("result", {
		matchingFiles = matches
		,results = orderedResults
	})
end
