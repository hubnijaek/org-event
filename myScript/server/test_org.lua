-------------------------------------------------
-- TEMPORARY ORGANIZATION SYSTEM
-- FOR LOCALHOST TESTING ONLY
-------------------------------------------------

TestOrganizations = {

    [1] = {
        id = 1,
        name = "Los Santos Vagos",
        members = {}
    },

    [2] = {
        id = 2,
        name = "Grove Street",
        members = {}
    },

    [3] = {
        id = 3,
        name = "Ballas",
        members = {}
    }
}


-------------------------------------------------
-- PLAYER DATA
-------------------------------------------------

PlayerOrganization = {}

PlayerRank = {}

LEOPlayers = {}


-------------------------------------------------
-- GET PLAYER ORGANIZATION
-------------------------------------------------

function getPlayerOrganization(player)

    local organizationId = PlayerOrganization[player]

    if not organizationId then
        return nil
    end

    return TestOrganizations[organizationId]
end


-------------------------------------------------
-- GET PLAYER RANK
-------------------------------------------------

function getPlayerOrganizationRank(player)

    return PlayerRank[player]
end


-------------------------------------------------
-- CHECK LEADER / CO-LEADER
-------------------------------------------------

function canStartShipment(player)

    local rank = getPlayerOrganizationRank(player)

    if rank == "leader" or rank == "co-leader" then
        return true
    end

    return false
end


-------------------------------------------------
-- GET ORGANIZATION MEMBERS
-------------------------------------------------

function getOrganizationMembers(organizationId)

    local organization = TestOrganizations[organizationId]

    if not organization then
        return {}
    end

    local members = {}

    for player, playerOrganizationId in pairs(PlayerOrganization) do

        if isElement(player)
        and playerOrganizationId == organizationId then

            table.insert(members, player)

        end
    end

    return members
end


-------------------------------------------------
-- COUNT ALIVE MEMBERS
-------------------------------------------------

function getAliveOrganizationMembers(organizationId)

    local members = getOrganizationMembers(organizationId)

    local aliveMembers = {}

    for _, player in ipairs(members) do

        if isElement(player)
        and not isPedDead(player) then

            table.insert(aliveMembers, player)

        end
    end

    return aliveMembers
end


-------------------------------------------------
-- COUNT ON-DUTY LEO
-------------------------------------------------

function getOnDutyLEOCount()

    local count = 0

    for player, isOnDuty in pairs(LEOPlayers) do

        if isElement(player)
        and isOnDuty then

            count = count + 1

        end
    end

    return count
end


-------------------------------------------------
-- SET ORGANIZATION
-------------------------------------------------

addCommandHandler("setorg", function(player, command, organizationId)

    organizationId = tonumber(organizationId)

    if not organizationId then
        outputChatBox(
            "Usage: /setorg [organization ID]",
            player,
            255,
            255,
            255
        )
        return
    end

    local organization = TestOrganizations[organizationId]

    if not organization then

        outputChatBox(
            "Organization does not exist.",
            player,
            255,
            0,
            0
        )

        return
    end

    PlayerOrganization[player] = organizationId

    outputChatBox(
        "You joined: " .. organization.name,
        player,
        0,
        255,
        0
    )
end)


-------------------------------------------------
-- SET RANK
-------------------------------------------------

addCommandHandler("setrank", function(player, command, rank)

    if not rank then

        outputChatBox(
            "Usage: /setrank [leader/co-leader/member]",
            player,
            255,
            255,
            255
        )

        return
    end

    rank = string.lower(rank)

    if rank ~= "leader"
    and rank ~= "co-leader"
    and rank ~= "member" then

        outputChatBox(
            "Invalid rank.",
            player,
            255,
            0,
            0
        )

        return
    end

    PlayerRank[player] = rank

    outputChatBox(
        "Your rank is now: " .. rank,
        player,
        0,
        255,
        0
    )
end)


-------------------------------------------------
-- TOGGLE LEO DUTY
-------------------------------------------------

addCommandHandler("leoduty", function(player)

    if LEOPlayers[player] then

        LEOPlayers[player] = nil

        outputChatBox(
            "You are now OFF DUTY as LEO.",
            player,
            255,
            100,
            100
        )

    else

        LEOPlayers[player] = true

        outputChatBox(
            "You are now ON DUTY as LEO.",
            player,
            0,
            255,
            0
        )

    end
end)


-------------------------------------------------
-- CLEAN PLAYER DATA
-------------------------------------------------

addEventHandler("onPlayerQuit", root, function()

    PlayerOrganization[source] = nil
    PlayerRank[source] = nil
    LEOPlayers[source] = nil

end)