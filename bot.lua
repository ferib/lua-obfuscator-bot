local discordia = require("discordia")
local fs = require("fs")
local http = require("coro-http")
local json = require("json")
local client = discordia.Client()

-- 
local adminId = 244846359763615744
local HTTP_PATH = "https://luaobfuscator.com/api/obfuscator/"
local LuaObfuscatorGuildId = 1069422455933902949
-- helpers

local function parsePre(s)
	local res = ""
  	
	-- find ` if any
	local sx, sy = s:find("```")
	if sx == nil then
		return nin
	end
	res = s:sub(sy+1, #s)

	-- take next line
	local nx, ny = res:find("\n")
	if nx == nil then
		return nil
	end
	res = res:sub(ny+1, #s)
	
	-- take until end
	local ex, ey = res:find("```")
	if ex == nil then
		return nil
	end
	res = res:sub(1, ex-1)
	return res
end


client:on("ready", function()
	print("Logged in as ".. client.user.username)
end)

client:on("messageCreate", function(message) local s, e = pcall(messageCreateHandler, message) if not s then print(e) end end)

function messageCreateHandler(message)
	local cmd_obf = "!obfuscate"
	local cmd_obf2 = "!obf"
	local cmd_deobf = "!deobf"
	local cmd_help = "!help"

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
	if message.author.bot == false then
		-- check for help
		if message.content:sub(1, #cmd_help) == cmd_help then
			message.channel:send("To obfuscate a Lua file, type `!obf` and attach a file to the message, or embed a code snipet using tripple backticks (3x `` `). Cheer!")
			return
		end
		-- check for deobf request
		if (message.content:sub(1, #cmd_deobf) == cmd_deobf) then
			-- check server match
			print(message.guild.id .. " == 1069422455933902949")
			--print(dump(message.guild))
			if message.guild ~= nil and message.guild.id == 1069422455933902949 then
				-- OK?
			else
				--message.channel:send("You do not have permission for this command, please consider boosting/supporting the server")

				-- TODO: we can look the user up in our guild by ID and check if it owns the role
				message.channel:send("This message can only be used in the public discord channel")
				return
			end
			local premiumName = "Server Booster"
			local role = message.guild.roles:find(function(r)
				return r.name == premiumName
			end)
			if role and message.member.roles:has(role) then
				message.channel:send("TODO: add deobfuscator API xd")
				return	
			end
			message.channel:send("You do not have permission for this command, please consider boosting/supporting the server")
			return
		end
		-- check for obf request
		if (message.content:sub(1, #cmd_obf) == cmd_obf or
		    message.content:sub(1, #cmd_obf2) == cmd_obf2) then

		--print(dump(message.content))
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
		else --if message.embeds ~= nil and #message.embeds > 0 then
			if message.content:find("```") then
				local parsedMsg = parsePre(message.content)
				if parsedMsg ~= nil then
					msg = parsedMsg
				end
			end
		end

		if msg == nil or msg == "" then
			message.channel:send("Please provide a valid Lua 5.1 script _(partial support for Lua 5.4.3 is available)_")
			return
		end
		
		-- obfsucate it
		print("Obfuscating...")
		
		-- upload to create a new session
		local res, body = http.request("POST", 
			HTTP_PATH .. "one-click/hard", -- "newscript", 
			{
				{ "Content-Type", "application/json" },
				{ "apikey", "test" }
			},
			msg)
		
		-- TODO: call a pre-defined 1-click button obfuscation?	

		local data = json.parse(body)
		if data == nil then
			message.channel:send("Error during obfuscation!")
			return
		end
		local result = data.code --"https://luaobfuscator.com/?session=" .. data.sessionId
		local url = "https://luaobfuscator.com/?session=" .. data.sessionId
		--print(dump(data))
		
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
		message.channel:send {
			content = "Obfuscation complete _(tmp link <" .. url .. ">)_",
			file = { "luaObfuscated.lua", result }
		}
	end
	end
end


-- get key
local key = fs.readFileSync("key.dat")
key = key:sub(1, #key-1) -- stupid line ending I can't seem to get rid of??
client:run(key)

