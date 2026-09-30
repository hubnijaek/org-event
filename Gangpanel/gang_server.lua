function gangCreate(player, commandname, gangname, ...)
	if arg.n == 0 and gangname then
		local playerAccount = getPlayerAccount(player)
		if not getAccountData(playerAccount, "gangs") then
			local dbName = "VOLT_" .. gangname .. "_members"
			local existinggangsWithName = executeSQLQuery("SELECT * FROM `VOLTgangdb` WHERE `gangname` = ?", gangname)
			local existinggangsWithName2 = executeSQLQuery("SELECT * FROM sqlite_master WHERE type='table' AND name=?", gangname)
			
			if existinggangsWithName[1] or existinggangsWithName2[1] then
				outputChatBox("A gang with this name already exists.", 255, 255, 0)
			else
				local query = executeSQLQuery("CREATE TABLE ? (accountname TEXT, lastname TEXT, lastlogin NUMERIC, warnings NUMERIC, level NUMERIC)", dbName )
					
				if query then
					executeSQLQuery("INSERT INTO VOLTgangdb VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", gangname, 0, "Default home screen text, change me using the button below!", 5, 5, 5, 5, 5, 0, 5, 5)
					local realTime = getRealTime()
					
					local month = tostring(realTime.month + 1)
					local monthday = tostring(realTime.monthday)
					
					if #month == 1 then month = "0" .. month end
					if #monthday == 1 then monthday = "0" .. monthday end
					
					local timestamp = realTime.year + 1900 .. "-" .. month .. "-" .. monthday

					executeSQLQuery("INSERT INTO ? VALUES(?, ?, ?, ?, ?)", dbName, getAccountName(playerAccount), getPlayerName(player), timestamp, 0, 5)
					setAccountData(playerAccount, "gangs", gangname)
					setElementData(player, "gangs", gangname)
					
					
				
				else
					
				end
			end
		else
		
		end
	else

	end
end
addCommandHandler("create", gangCreate)

function gangPanel(player)
	local playerAccount = getPlayerAccount(player)
	if getAccountData(playerAccount, "gangs") then
		triggerClientEvent(player, "displayPanel", player)
		populategangPanel(player)
	else
		OutputChatBox("You're not in a gang. Use /create to create one.", 255, 255, 0, player)
	end
end
addCommandHandler("gang", gangPanel)
addCommandHandler("squad", gangPanel)
addCommandHandler("company", gangPanel)

function populategangPanel(player)
	local playerAccount = getPlayerAccount(player)
	local gangname = getAccountData(playerAccount, "gangs")
		
	local dbName = "VOLT_" .. gangname .. "_members"
		
	local ganginfo = executeSQLQuery("SELECT * FROM `VOLTgangdb` WHERE `gangname` = ?", gangname)
	local memberinfo = executeSQLQuery("SELECT * FROM ?", dbName)
	
	for i,v in ipairs(memberinfo) do
		local account = getAccount(v['accountname'])
		if account then
			local lastLogin = getAccountData(account, "lastlogin") or v['lastlogin']
			local lastNick = getAccountData(account, "lastnick") or v['lastname']
			
			local player = getAccountPlayer(account)
			local online = false
			if player then online = true end
			
			memberinfo[i]['lastname'] = lastNick
			memberinfo[i]['lastlogin'] = lastLogin
			memberinfo[i]['online'] = online
		end
	end
	triggerClientEvent(player, "populatePanel", player, ganginfo[1], memberinfo, getAccountName(getPlayerAccount(player)))
end

function getPlayerLevel(player)
	local playerAccount = getPlayerAccount(player)
	local playerAccountName = getAccountName(playerAccount)
	
	local gangname = getAccountData(playerAccount, "gangs")
	if gangname then
		local dbName = "VOLT_" .. gangname .. "_members"
		local playerinfo = executeSQLQuery("SELECT * FROM ? WHERE `accountname` = ?", dbName, playerAccountName)
		return playerinfo[1]["level"]
	else
		return false
	end
end

function getPlayergang(player)
	local playerAccount = getPlayerAccount(player)
	local gangname = getAccountData(playerAccount, "gangs")
	return gangname
end

function getgangInfo(gangname)
	local ganginfo = executeSQLQuery("SELECT * FROM `VOLTgangdb` WHERE `gangname` = ?", gangname)
	if ganginfo[1] then
		return ganginfo[1]
	else
		return false
	end
end

-- ALL THE HANDLER FUNCTIONS ARE HERE!

function saveMOTD(motd)
	if getPlayergang(source) then
		local ganginfo = getgangInfo(getPlayergang(source))
		local playerlevel = getPlayerLevel(source)
		if playerlevel >= tonumber(ganginfo['motdperm']) then
			executeSQLQuery("UPDATE `VOLTgangdb` SET `hometext` = ? WHERE `gangname` = ?",motd, getPlayergang(source))
			populategangPanel(source)
		end
	end
end
addEvent("_saveMOTD", true)
addEventHandler("_saveMOTD", getRootElement(), saveMOTD)

function levelPlayer(accountname)
	if getPlayergang(source) then
		local ganginfo = getgangInfo(getPlayergang(source))
		local playerlevel = getPlayerLevel(source)
		if playerlevel >= tonumber(ganginfo['levelperm']) then
			local dbName = "VOLT_" .. ganginfo['gangname'] .. "_members"
			local playerTo = executeSQLQuery("SELECT * FROM ? WHERE `accountname`=?", dbName, accountname)
			if playerTo[1] then
				if playerlevel > (tonumber(playerTo[1]['level']) + 1) and tonumber(playerTo[1]['level']) < 5 then
					local newlevel = tonumber(playerTo[1]['level']) + 1
					executeSQLQuery("UPDATE ? SET `level` = ? WHERE `accountname` = ?", dbName, newlevel, accountname)
					populategangPanel(source)
				else
					triggerClientEvent(source, "errorDisplay", source, "Error: You can't touch players equal to/over your level.")
				end
			else
				triggerClientEvent(source, "errorDisplay", source, "Error: Can not find player.")
				populategangPanel(source)
			end
		end
	end
end
addEvent("_levelPlayer", true)
addEventHandler("_levelPlayer", getRootElement(), levelPlayer)

function unlevelPlayer(accountname)
	if getPlayergang(source) then
		local ganginfo = getgangInfo(getPlayergang(source))
		local playerlevel = getPlayerLevel(source)
		if playerlevel >= tonumber(ganginfo['levelperm']) then
			local dbName = "VOLT_" .. ganginfo['gangname'] .. "_members"
			local playerTo = executeSQLQuery("SELECT * FROM ? WHERE `accountname`=?", dbName, accountname)
			if playerTo[1] then
				if playerlevel > tonumber(playerTo[1]['level']) and tonumber(playerTo[1]['level']) > 0 then
					local newlevel = tonumber(playerTo[1]['level']) - 1
					executeSQLQuery("UPDATE ? SET `level` = ? WHERE `accountname` = ?", dbName, newlevel, accountname)
					populategangPanel(source)
				else
					triggerClientEvent(source, "errorDisplay", source, "Error: You can't touch players equal to/over your level.")
				end
			else
				triggerClientEvent(source, "errorDisplay", source, "Error: Can not find player.")
				populategangPanel(source)
			end
		end
	end
end
addEvent("_unlevelPlayer", true)
addEventHandler("_unlevelPlayer", getRootElement(), unlevelPlayer)

function warnPlayer(accountname)
	if getPlayergang(source) then
		local ganginfo = getgangInfo(getPlayergang(source))
		local playerlevel = getPlayerLevel(source)
		if playerlevel >= tonumber(ganginfo['levelperm']) then
			local dbName = "VOLT_" .. ganginfo['gangname'] .. "_members"
			local playerTo = executeSQLQuery("SELECT * FROM ? WHERE `accountname`=?", dbName, accountname)
			if playerTo[1] then
				if playerlevel > tonumber(playerTo[1]['level']) and tonumber(playerTo[1]['warnings']) < 5 then
					local newwarn = tonumber(playerTo[1]['warnings']) + 1
					executeSQLQuery("UPDATE ? SET `warnings` = ? WHERE `accountname` = ?", dbName, newwarn, accountname)
					populategangPanel(source)
				else
					triggerClientEvent(source, "errorDisplay", source, "Error: You can't touch players equal to/over your level.")
				end
			else
				triggerClientEvent(source, "errorDisplay", source, "Error: Can not find player.")
				populategangPanel(source)
			end
		end
	end
end
addEvent("_warnPlayer", true)
addEventHandler("_warnPlayer", getRootElement(), warnPlayer)

function unwarnPlayer(accountname)
	if getPlayergang(source) then
		local ganginfo = getgangInfo(getPlayergang(source))
		local playerlevel = getPlayerLevel(source)
		if playerlevel >= tonumber(ganginfo['levelperm']) then
			local dbName = "VOLT_" .. ganginfo['gangname'] .. "_members"
			local playerTo = executeSQLQuery("SELECT * FROM ? WHERE `accountname`=?", dbName, accountname)
			if playerTo[1] then
				if playerlevel > (tonumber(playerTo[1]['level'])) and tonumber(playerTo[1]['warnings']) > 0 then
					local newwarn = tonumber(playerTo[1]['warnings']) - 1
					executeSQLQuery("UPDATE ? SET `warnings` = ? WHERE `accountname` = ?", dbName, newwarn, accountname)
					populategangPanel(source)
				else
					triggerClientEvent(source, "errorDisplay", source, "Error: You can't touch players equal to/over your level.")
				end
			else
				triggerClientEvent(source, "errorDisplay", source, "Error: Can not find player.")
				populategangPanel(source)
			end
		end
	end
end
addEvent("_unwarnPlayer", true)
addEventHandler("_unwarnPlayer", getRootElement(), unwarnPlayer)

function depositMoney(money)
	if tonumber(money) > 0 then
		if getPlayergang(source) then
			local ganginfo = getgangInfo(getPlayergang(source))
			local playerlevel = getPlayerLevel(source)
			if playerlevel >= tonumber(ganginfo['depositperm']) then
				local newmoney = tonumber(ganginfo['money']) + tonumber(money)
				if getPlayerMoney(source) >= tonumber(money) then
					executeSQLQuery("UPDATE `VOLTgangdb` SET `money` = ? WHERE `gangname` = ?", newmoney, getPlayergang(source))
					takePlayerMoney(source, tonumber(money))
					populategangPanel(source)
				else
					triggerClientEvent(source, "errorDisplay", source, "Error: You don't have enough money.")
					populategangPanel(source)
				end
			end
		end
	end
end
addEvent("_depositMoney", true)
addEventHandler("_depositMoney", getRootElement(), depositMoney)

function withdrawMoney(money)
	if tonumber(money) > 0 then
		if getPlayergang(source) then
			local ganginfo = getgangInfo(getPlayergang(source))
			local playerlevel = getPlayerLevel(source)
			if playerlevel >= tonumber(ganginfo['withdrawperm']) then
				local newmoney = tonumber(ganginfo['money']) - tonumber(money)
				if tonumber(ganginfo['money']) >= tonumber(money) then
					executeSQLQuery("UPDATE `VOLTgangdb` SET `money` = ? WHERE `gangname` = ?", newmoney, getPlayergang(source))
					givePlayerMoney(source, tonumber(money))
					populategangPanel(source)
				else
					triggerClientEvent(source, "errorDisplay", source, "Error: There isn't enough money in the gang account.")
					populategangPanel(source)
				end
			end
		end
	end
end
addEvent("_withdrawMoney", true)
addEventHandler("_withdrawMoney", getRootElement(), withdrawMoney)

function inviteStart()
	if getPlayergang(source) then
		local ganginfo = getgangInfo(getPlayergang(source))
		local playerlevel = getPlayerLevel(source)
		if playerlevel >= tonumber(ganginfo['inviteperm']) then
			local playas = getElementsByType("player")
			local ganglessnubs = {}
			for i, v in ipairs(playas) do
				if not getAccountData(getPlayerAccount(v), "gangs") then
					table.insert(ganglessnubs, getPlayerName(v))
				end
			end
			triggerClientEvent(source, "displayInvite", source, ganglessnubs)
		end
	end
end
addEvent("_invitePlayer", true)
addEventHandler("_invitePlayer", getRootElement(), inviteStart)

function inviteStep2(playa)
	if getPlayergang(source) then
		local playa = getPlayerFromName(playa)
		local ganginfo = getgangInfo(getPlayergang(source))
		local playerlevel = getPlayerLevel(source)
		if playerlevel >= tonumber(ganginfo['inviteperm']) then
			if playa and isElement(playa) and getElementType(playa) == "player" and not getAccountData(getPlayerAccount(playa), "gangs") then
				triggerClientEvent(playa, "inviteReceive", source, getPlayergang(source))
			end
		end
	end
end
addEvent("_inviteStep2", true)
addEventHandler("_inviteStep2", getRootElement(), inviteStep2)

function inviteFin(sender, gangname)
	local sender = getPlayerFromName(sender)
	local ganginfo = getgangInfo(getPlayergang(sender))
	local playerAccount = getPlayerAccount(source)
	
	if not getAccountData(playerAccount, "gangs") then	
		local realTime = getRealTime()
		
		local month = tostring(realTime.month + 1)
		local monthday = tostring(realTime.monthday)
		
		if #month == 1 then month = "0" .. month end
		if #monthday == 1 then monthday = "0" .. monthday end
		
		local timestamp = realTime.year + 1900 .. "-" .. month .. "-" .. monthday
		
		local dbName = "VOLT_" .. gangname .. "_members"
		
		executeSQLQuery("INSERT INTO ? VALUES(?, ?, ?, ?, ?)", dbName, getAccountName(playerAccount), getPlayerName(source), timestamp, 0, 0)
		
		setAccountData(playerAccount, "gangs", gangname)
		setElementData(source, "gangs", gangname)
		
		triggerClientEvent(player, "TopChat:addMessage", root,getPlayerName(source) .. " is now in " .. gangname .. ".", 0, 255, 0) 
		
		populategangPanel(source)
		if isElement(sender) then
			populategangPanel(sender)
		end
	else
		triggerClientEvent(source, "errorDisplay", source, "Error: You're already in a gang.")
	end
end
addEvent("_inviteFin", true)
addEventHandler("_inviteFin", getRootElement(), inviteFin)

function leavegang()
	if getPlayergang(source) then
		local ganginfo = getgangInfo(getPlayergang(source))
		local gangname = ganginfo['gangname']
		local playerlevel = getPlayerLevel(source)
		if playerlevel < 5 then
			local dbName = "VOLT_" .. gangname .. "_members"
			local accName = getAccountName(getPlayerAccount(source))
			executeSQLQuery("DELETE FROM ? WHERE `accountname`=?", dbName, accName)
			
			setAccountData(getPlayerAccount(source), "gangs", false)
			setElementData(source, "gangs", false)
			triggerClientEvent(player, "TopChat:addMessage", root,getPlayerName(source) .. " is no longer in " .. gangname .. ".", 255, 255, 0) 
		else
			triggerClientEvent(source, "errorDisplay", source, "Error: You can't leave if you are the leader. You must give leadership to someone else first.")
		end
	end
end
addEvent("_leavegang", true)
addEventHandler("_leavegang", getRootElement(), leavegang)

function kickPlayer(accountname)
	if getPlayergang(source) then
		local ganginfo = getgangInfo(getPlayergang(source))
		local playerlevel = getPlayerLevel(source)
		local gangname = ganginfo['gangname']
		if playerlevel >= tonumber(ganginfo['kickperm']) then
			local dbName = "VOLT_" .. ganginfo['gangname'] .. "_members"
			local playerTo = executeSQLQuery("SELECT * FROM ? WHERE `accountname`=?", dbName, accountname)
			if playerTo[1] then
				if playerlevel > (tonumber(playerTo[1]['level'])) then
					local kickedAccount = getAccount(accountname)
					
					setAccountData(kickedAccount, "gangs", false)
					if getAccountPlayer(kickedAccount) then
						setElementData(getAccountPlayer(kickedAccount), "gangs", false)
					end

					executeSQLQuery("DELETE FROM ? WHERE `accountname` = ?", dbName, accountname)
					outputChatBox(playerTo[1]['lastname'] .. " is no longer in " .. gangname .. ".", 255, 255, 0) 
					
					populategangPanel(source)
				else
					triggerClientEvent(source, "errorDisplay", source, "Error: You can't kick players equal to/over your level.")
				end
			else
				triggerClientEvent(source, "errorDisplay", source, "Error: Can not find player.")
				populategangPanel(source)
			end
		end
	end
end
addEvent("_kickPlayer", true)
addEventHandler("_kickPlayer", getRootElement(), kickPlayer)

function transferLeadership(accountname)
	if getPlayergang(source) then
		local ganginfo = getgangInfo(getPlayergang(source))
		local playerlevel = getPlayerLevel(source)
		local gangname = ganginfo['gangname']
		if playerlevel == 5 then
			local dbName = "VOLT_" .. ganginfo['gangname'] .. "_members"
			local playerTo = executeSQLQuery("SELECT * FROM ? WHERE `accountname`=?", dbName, accountname)
			if playerTo[1] then
				local tranferAccount = getAccount(playerTo[1]['accountname'])

				executeSQLQuery("UPDATE ? SET `level` = 4 WHERE `accountname` = ?", dbName, getAccountName(getPlayerAccount(source)))
				executeSQLQuery("UPDATE ? SET `level` = 5 WHERE `accountname` = ?", dbName, accountname)

				populategangPanel(source)
			else
				triggerClientEvent(source, "errorDisplay", source, "Error: Can not find player.")
				populategangPanel(source)
			end
		end
	end
end
addEvent("_transferLeadership", true)
addEventHandler("_transferLeadership", getRootElement(), transferLeadership)

function deletegang()
	if getPlayergang(source) then
		local ganginfo = getgangInfo(getPlayergang(source))
		local gangname = ganginfo['gangname']
		local playerlevel = getPlayerLevel(source)
		if playerlevel >= tonumber(ganginfo['deleteperm']) then
			local dbName = "VOLT_" .. gangname .. "_members"
			local accName = getAccountName(getPlayerAccount(source))

			local players = executeSQLQuery("SELECT * FROM ?", dbName)
			for i, v in ipairs(players) do
				local thisAccount = getAccount(v['accountname'])
				setAccountData(thisAccount, "gangs", false)
				if getAccountPlayer(thisAccount) then
				setElementData(getAccountPlayer(thisAccount), "gangs", false)
				outputChatBox(v['lastname'] .. " is no longer in " .. gangname .. ".", 255, 255, 0) 
			end
			
			executeSQLQuery("DELETE FROM `VOLTgangdb` WHERE `gangname` =?", gangname)
			executeSQLQuery("DROP TABLE ?", dbName)
		end
	end
end
end
addEvent("_deletegang", true)
addEventHandler("_deletegang", getRootElement(), deletegang)

function saveSettings(inviteperm, warnperm, kickperm, levelperm, depositperm, withdrawperm, motdperm, deleteperm)
	if getPlayergang(source) then
		local ganginfo = getgangInfo(getPlayergang(source))
		local gangname = ganginfo['gangname']
		local playerlevel = getPlayerLevel(source)
		if playerlevel == 5 then
			if inviteperm >= 0 and inviteperm <= 5 and warnperm >= 0 and warnperm <= 5 and kickperm >= 0 and kickperm <= 5 and levelperm >= 0 and levelperm <= 5 and depositperm >= 0 and depositperm <= 5 and withdrawperm >= 0 and withdrawperm <= 5 and motdperm >= 0 and motdperm <= 5 and deleteperm >= 0 and deleteperm <= 5 then
				executeSQLQuery("UPDATE `VOLTgangdb` SET `inviteperm`=?,`warnperm`=?,`kickperm`=?,`levelperm`=?,`depositperm`=?,`withdrawperm`=?,`motdperm`=?,`deleteperm`=? WHERE `gangname`=?",inviteperm, warnperm, kickperm, levelperm, depositperm, withdrawperm, motdperm, deleteperm, gangname)
				populategangPanel(source)
			else
				triggerClientEvent(source, "errorDisplay", source, "Error: Only numbers between 0 and 5 are allowed.")
			end
		end
	end
end
addEvent("_saveSettings", true)
addEventHandler("_saveSettings", getRootElement(), saveSettings)

-- Extra functions

function onLoginInformation()
	if getPlayergang(source) then
		local ganginfo = getgangInfo(getPlayergang(source))
		local gangname = ganginfo['gangname']
		local dbName = "VOLT_" .. gangname .. "_members"
		
		local playerName = getPlayerName(source)
		local playerAccount = getPlayerAccount(source)
		local accName = getAccountName(source)
			
		local realTime = getRealTime()
				
		local month = tostring(realTime.month + 1)
		local monthday = tostring(realTime.monthday)
			
		if #month == 1 then month = "0" .. month end
		if #monthday == 1 then monthday = "0" .. monthday end
				
		local timestamp = realTime.year + 1900 .. "-" .. month .. "-" .. monthday
		
		executeSQLQuery("UPDATE ? SET lastname=?,lastlogin=? WHERE `accountname`=?", dbName, playerName, timestamp, accName)
	end
end
addEvent("onPlayerLoginSuccess", true)
addEventHandler("onPlayerLoginSuccess", getRootElement(), onLoginInformation)

-- Clanchat

function onPlayerClanchat(player, command, ...)
	if getPlayergang(player) then
		local ganginfo = getgangInfo(getPlayergang(player))
		local gangname = ganginfo['gangname']
		local dbName = "VOLT_" .. gangname .. "_members"
		
		local message = table.concat(arg, " ")
		
		local gangmembers = executeSQLQuery("SELECT * FROM ?", dbName)
		for i,v in ipairs(gangmembers) do
			local accname = v['accountname']
			local acc = getAccount(accname)
			if getAccountPlayer(acc) then
				outputChatBox("*CC*" .. getPlayerName(player) .. ": " .. message, getAccountPlayer(acc), 255, 100, 0, true)
			end
		end
	end
end
addCommandHandler("cc", onPlayerClanchat)