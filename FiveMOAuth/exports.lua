local BotToken = "token"
local GuildId = "guild"
local CurRes = GetCurrentResourceName()

exports("Discord", function(method, endpoint, data)
    data = data or {}
    local response = nil
    local statuscode = nil

    PerformHttpRequest("https://discordapp.com/api" .. endpoint, function (errorCode, body, resultHeaders)
        statuscode = errorCode

        if pcall(function() json.decode(body) end) then
            response = json.decode(body)
        else
            response = body
        end

    end, method, #data ~= 0 and json.encode(data) or nil, {["Content-Type"] = "application/json", ["Authorization"] = "Bot " .. BotToken})

    while not statuscode do Wait(0) end
    if statuscode ~= nil and statuscode ~= 0 then
        while not response do Wait(0) end
        return response
    else
        return false
    end
end)

exports("GetUserInfo", function(user)
    local DiscordId = GetDiscordId(user)
    if not DiscordId then return false end
    local DiscordUser = exports[CurRes]:Discord("GET", ("/guilds/%s/members/%s"):format(GuildId, DiscordId))
    return DiscordUser
end)

exports("GetUserRoles", function(user)
    local DiscordUser = exports[CurRes]:GetUserInfo(user)
	return DiscordUser.roles
end)


