local discordia = require("discordia")
local fs = require("fs")
local pp = require("pretty-print")
local https = require("https")
local client = discordia.Client()

-- 
local adminId = 244846359763615744



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
		pp.print("Obfuscation request by: " .. message.author.username)	
		
		-- check for files/content one way or another
		local msg = ""
		if message.attachments ~= nil and #message.attachments > 0 then
			msg = message.attachments[1].url -- TODO: HTTP GET
		--elseif message.embeds ~= nil and #message.embeds > 0 then
		--	pp.print(dump(message.embeds))	
		end
		if message.attachments == nil or #message.attachments == 0 then
			message.channel:send("Please provide a valid Lua 5.1 script _(partial support for Lua 5.4.3 is available)_")
			return
		end

		pp.print("message: " .. message.content)
		--pp.print("embed count: " .. #message.embeds)
		pp.print("file count: " .. #message.attachments)

		-- content check
		pp.print(dump(message.attachments[1]))

		-- obfsucate it
		pp.print("Obfuscating...")
		local options = {
			host = "luaobfuscator.com",
			port = 443,
			path = "/api/obfuscator/newscript/"
		}

		local req = https.request(options, function (res)
			res:on("data", function (chunk)
				pp.print(chunk)
			end)
		end)
		req:done()
		message.channel:send(message.attachments[1].url)
			
		--[[
		message:reply {
			embed = {
				title = "Obfuscation Request",
				description = "Please provide a Lua 5.1 file (or partial limited 5.4.3) and click obfuscate button",
				author= {
					name = message.author.username,
					icon_url = message.author.avatarURL,
				},
				fields = {
					{
						name = "Test",
						value = "Obfuscate",
						inline = false,
					}
				},
				footer = { text = "luaObfuscator.com" },
				color = 0x000000
			}
		}]]--
		--[[
		message.channel:send {
			content = "Select your choise",
			components = {
				{
					type = 1,
					components = {
						{
							tpye = 2,
							style = 1,
							label = "> OBFUSCATE <",
							custom_id = "pre-3",
							disbaled = false,
						}
					}
				}
			}
		}]]--
	end
end)


-- get key
local key = fs.readFileSync("key.dat")
key = key:sub(1, #key-1) -- stupid line ending I can't seem to get rid of??
client:run(key)

