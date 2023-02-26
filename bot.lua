local discordia = require("discordia")
local fs = require("fs")
local http = require("coro-http")
local json = require("json")
local client = discordia.Client()

-- 
local adminId = 244846359763615744
local HTTP_PATH = "https://luaobfuscator.com/api/obfuscator/"


client:on("ready", function()
	print("Logged in as ".. client.user.username)
end)

client:on("messageCreate", function(message)
	local cmd = "!obfuscate"
	local cmd2 = "!obf"

	-- helper
	function dump(o)
		if type(o) ~= "table" then return tostring(o) end
		local s = "{ "
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"' ..k.. '"' end
			s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
		end
		return s .. '} '
	end

	-- check for command
	if message.author.bot == false and 
		(message.content:sub(1, #cmd) == cmd or
		message.content:sub(1, #cmd2) == cmd2) then

		--message.channel:send(message.content)
		print("Obfuscation request by: " .. message.author.username)	
		
		-- check for files/content one way or another
		local msg = ""
		if message.attachments ~= nil and #message.attachments > 0 then
			local url = message.attachments[1].url -- TODO: HTTP GET
			local res, body = http.request("POST", url, "")
			if res.code ~= 200 then
				message.channel:send("Error obtaining file from Discord (" .. res.code .. ")")
				return
			end
			msg = body
		--elseif message.embeds ~= nil and #message.embeds > 0 then
		--	pp.print(dump(message.embeds))	
		end
		if message.attachments == nil or #message.attachments == 0 then
			message.channel:send("Please provide a valid Lua 5.1 script _(partial support for Lua 5.4.3 is available)_")
			return
		end

		--print("message: " .. message.content)
		--print("embed count: " .. #message.embeds)
		--print("file count: " .. #message.attachments)

		-- content check
		--print(dump(message.attachments[1]))

		-- obfsucate it
		print("Obfuscating...")
		
		-- upload to create a new session
		local res, body = http.request("POST", 
			HTTP_PATH .. "newscript", 
			{
				{ "Content-Type", "application/json" },
				{ "apikey", "test" }
			},
			msg)
		
		-- TODO: call a pre-defined 1-click button obfuscation?	

		print(dump(options))
		local data = json.parse(body)
		local result = "https://luaobfuscator.com/?session=" .. data.sessionId
		print(dump(res))
		
		-- handle HTTP errors
		if res.code ~= 200 then
			message.channel:send("Unknown server error (" .. tostring(res.status) .. ")")
			return
		end

		-- handle server errors
		if body.message ~= nil then
			message.channel:send("Server error:\n" .. body.message)
			return
		end

		-- OK?
		message.channel:send(result)
	end
end)


-- get key
local key = fs.readFileSync("key.dat")
key = key:sub(1, #key-1) -- stupid line ending I can't seem to get rid of??

client:run(key)

