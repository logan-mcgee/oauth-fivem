local WaitingUsers = {}
local CurRes = GetCurrentResourceName()

local TCPConvar = GetConvar("endpoint_add_tcp", "0.0.0.0:30120")
local Port = string.gsub(TCPConvar, "0.0.0.0:", "")

local config = json.decode(LoadResourceFile(GetCurrentResourceName(), "config.json"))

local OAuthQS = ""
for query, value in pairs(config.public_data) do
	OAuthQS = OAuthQS .. query .. "=" .. value .. "&"
end

local OAuthURL = "https://discordapp.com/api/oauth2/authorize?" .. OAuthQS

local InitialCard = {
	["$schema"] = "http://adaptivecards.io/schemas/adaptive-card.json",
	actions = {
		{
			title = "Link your Discord",
			type = "Action.OpenUrl",
			url = OAuthURL
		}
	},
	body = {
		{
			horizontalAlignment = "Center",
			size = "Large",
			text = "Welcome to the server, %s!",
			type = "TextBlock"
		},
		{
			items = {
				{
					size = "Small",
					text = "We require you to authenticate yourself via Discord to check your role eligibility. Please click the link below to open the authentication page.",
					type = "TextBlock",
					wrap = true
				}
			},
			type = "Container"
		}
	},
	type = "AdaptiveCard",
	version = "1.1"
}


function GetLicense(id)
	for k, identifier in pairs(GetPlayerIdentifiers(id)) do
		if string.find(identifier, "license:") then
			return identifier
		end
	end
	return false
end

function GetDiscordId(id)
	local Discord =
		MySQL.Sync.fetchAll("SELECT discordid FROM discord WHERE license=@license", {["@license"] = GetLicense(id)})
	if Discord[1] then
		return Discord[1].discordid
	else
		return false
	end
end

function TableMatch(table1, table2)
	for i = 1, #table1 do
		for x = 1, #table2 do
			if table1[i] == table2[x] then
				return true
			end
		end
	end
	return false
end

function IsUserAllowed(user)
	local roles = exports[CurRes]:GetUserRoles(user)
	if not roles then 
		return {allowed = false, reason = "There's been an error authenticating your presence in the server. This could be a FiveM issue or please consider joining us"}
	end
	local CorrectRole = TableMatch(config.private_data.permitted_roles, roles)
	local BlacklistedRole = TableMatch(config.private_data.blacklisted_roles, roles)

	if CorrectRole and not BlacklistedRole then
		return {allowed = true, reason = "uwu"} -- This message isnt shown btw ...sigh
	elseif CorrectRole and BlacklistedRole then
		return {allowed = false, reason = "You seem to be whitelisted, but your access is currently restricted."}
	elseif not CorrectRole then
		return {allowed = false, reason = "You do not seem to have the correct roles to join."}
	end
end

AddEventHandler(
	"playerConnecting",
	function(name, skr, def)
		local CardClone = InitialCard
		local s = source
		def.defer() --! Initialize the defferal

		Wait(50)

		if GetDiscordId(s) then
			local UserAllowed = IsUserAllowed(s)
			if UserAllowed.allowed then
				def.update("Hey look at you, you're special! Welcome in!")
				Wait(2000)
				def.done()
				return
			else
				def.done("Joining failed. Reason: " .. UserAllowed.reason)
				return
			end
		end

		CardClone.body[1].text = ("Welcome to Project New Dawn, %s!"):format(name) -- Format the title to make it nicer.

		local License = GetLicense(s)
		local HashedLicense = sha256(License)
		local DataToSend = {port = Port, id = HashedLicense} --* Base64 encodes the port of the server and the users license hashed, to send to the discord URL
		local Base64Data = exports[CurRes]:UrlEncode(json.encode(DataToSend))
		CardClone.actions[1].url = OAuthURL .. "state=" .. Base64Data --* Appends the data created above

		def.presentCard(json.encode(CardClone))

		for Hashed, Data in pairs(WaitingUsers) do
			if Data.license == License then
				WaitingUsers[Hashed] = nil
			end
		end

		WaitingUsers[HashedLicense] = {deferral = def, id = s, license = License}
	end
)

AddEventHandler(
	"OAuthFiveM:AuthedUser",
	function(JsonData, UserHash)

		local DiscordData = json.decode(JsonData)
		local User = WaitingUsers[UserHash]

		--* Adding user into the DB
		MySQL.Sync.execute(
			"INSERT INTO discord (license, discordid) VALUES (@license, @discord)",
			{["@license"] = GetLicense(User.id), ["@discord"] = DiscordData.id}
		)

		local UserAllowed = IsUserAllowed(User.id)
		if UserAllowed.allowed then
			User.deferral.update("Hey look at you, you're special! Welcome in!")
			Wait(2000)
			User.deferral.done()
			WaitingUsers[UserHash] = nil
			return
		else
			User.deferral.done("Joining failed. Reason: " .. UserAllowed.reason)
			WaitingUsers[UserHash] = nil
			return
		end
	end
)