client_ganginfo = {}
client_gangmembers = {}
localplayer_info = {}

lastInvite = false


function displaygangPanel()
	if not isElement(gangPanel) then
		memos = {}
		tabs = {}
		settingLabel = {}
		settingEdit = {}

		mainX, mainY = guiGetScreenSize ()
		local objX = (mainX / 2) - 300
		local objY = (mainY / 2) - 200

		gangPanel = guiCreateWindow(0.25,0.25,0.5,0.5244,"RPG Gang Panel by Neon",true)
		guiWindowSetSizable(gangPanel,false)

		tabPanel = guiCreateTabPanel(0.0141,0.1365,0.9719,0.8412,true,gangPanel)
		guiSetProperty( tabPanel, "ZOrderChangeEnabled", "False" )
		closeButton = guiCreateButton(0.8625,0.0521,0.1172,0.0471, "Close", true, gangPanel) 
		guiSetProperty( closeButton, "ZOrderChangeEnabled", "False" )

		-- Tab One - Home
		tabs[1] = guiCreateTab("MOTD",tabPanel)
		GroupInfoTab = guiCreateTabPanel(0,0,1,1,true,tabs[1])
		MOTDTab = guiCreateTab("MOTD",GroupInfoTab)
		homeChangeButton = guiCreateButton(0.9,0.915,0.09,0.075,"Edit",true,MOTDTab)
		homeSaveButton = guiCreateButton(0.8,0.915,0.09,0.075,"Save",true,MOTDTab)
		motdMemo = guiCreateMemo(0,0,1,0.9,"",true,MOTDTab)
		guiMemoSetReadOnly(motdMemo,true)

		-- memos[4] = guiCreateMemo(0,0.7604,1,0.2396,"This is your gang Panel where you can manage your gang/Squad from. there will be added more functions.\n\n        (And this will also be updated soon with new information)",true,tabs[1])
		-- guiMemoSetReadOnly(memos[4],true)

		-- Tab Two - Members
		tabs[2] = guiCreateTab("Members",tabPanel)

		memberGrid = guiCreateGridList(0,0.0028,0.75,0.7632,true,tabs[2])
		guiGridListSetSelectionMode(memberGrid,0)

		guiGridListAddColumn(memberGrid,"Last Name",0.35)
		guiGridListAddColumn(memberGrid,"Last Login",0.15)
		accountColumn = guiGridListAddColumn(memberGrid,"Account",0.20)
		levelColumn = guiGridListAddColumn(memberGrid,"Level",0.10)
		warningColumn = guiGridListAddColumn(memberGrid,"Warnings",0.10)

		inviteButton = guiCreateButton(0.7971,0.1,0.1721,0.05,"Invite Player",true,tabs[2])
		levelButton = guiCreateButton(0.7989,0.17,0.1721,0.05,"Increase Level",true,tabs[2])
		unlevelButton = guiCreateButton(0.7989,0.24,0.1721,0.05,"Decrease Level",true,tabs[2])
		warnButton = guiCreateButton(0.7989,0.31,0.1721,0.05,"Give Warning",true,tabs[2])
		unwarnButton = guiCreateButton(0.7989,0.38,0.1721,0.05,"Remove Warning",true,tabs[2])
		kickButton = guiCreateButton(0.7989,0.45,0.1721,0.05,"Kick Member",true,tabs[2])
		leaveButton = guiCreateButton(0.7989,0.52,0.1721,0.05,"Leave gang",true,tabs[2])
		transferButton = guiCreateButton(0.7989,0.59,0.1721,0.05,"Make Leader",true,tabs[2])
		deleteButton = guiCreateButton(0.7989,0.66,0.1721,0.05,"Delete gang",true,tabs[2])

		memos[1] = guiCreateMemo(0,0.7604,1,0.2396,"You can see a list of your members here, alongside some other controls.",true,tabs[2])
		guiMemoSetReadOnly(memos[1],true)

		-- Tab 3 - Money

		tabs[3] = guiCreateTab("Money",tabPanel)

		cashLabel = guiCreateLabel(0.2602,0.103,0.5495,0.2035,"100000000",true,tabs[3])
		guiLabelSetHorizontalAlign(cashLabel,"right",false)
		guiSetFont(cashLabel,"sa-header")

		dollarLabel = guiCreateLabel(0.8233,0.1005,0.0816,0.2035,"$",true,tabs[3])
		guiSetFont(dollarLabel,"sa-header")

		depositEdit = guiCreateEdit(0.0835,0.4397,0.3864,0.0754,"",true,tabs[3])
		depositButton = guiCreateButton(0.0816,0.5302,0.3845,0.108,"Deposit",true,tabs[3])
		depositLabel= guiCreateLabel(0.0816,0.3518,0.3825,0.0704,"Deposit Money:",true,tabs[3])

		withdrawButton = guiCreateButton(0.5456,0.5302,0.3806,0.108,"Withdraw",true,tabs[3])
		withdrawEdit = guiCreateEdit(0.5417,0.4397,0.3864,0.0754,"",true,tabs[3])
		withdrawLabel = guiCreateLabel(0.5417,0.3518,0.3825,0.0704,"Withdraw Money:",true,tabs[3])

		moneyLabel = guiCreateLabel(0.0602,0.0955,0.3301,0.1608,"Money:",true,tabs[3])
		guiSetFont(moneyLabel,"sa-header")
		memos[2] = guiCreateMemo(0,0.7604,1,0.2396,"Here are you able To Save Money to the gang/Squad.\n\n        (And this will also be updated soon with new information)",true,tabs[3])
		guiMemoSetReadOnly(memos[2],true)

		-- Tab 4 - Settings

		tabs[4] = guiCreateTab("Settings",tabPanel)

		settingLabel[1] = guiCreateLabel(0.062,0.1606,0.2519,0.0855,"Invite:",true,tabs[4])
		settingLabel[2] = guiCreateLabel(0.062,0.272,0.2519,0.0855,"Warn:",true,tabs[4])
		settingLabel[3] = guiCreateLabel(0.062,0.3679,0.2519,0.0855,"Kick:",true,tabs[4])
		settingLabel[4] = guiCreateLabel(0.062,0.4819,0.2519,0.0855,"Level:",true,tabs[4])
		settingLabel[5] = guiCreateLabel(0.5508,0.1477,0.2519,0.0855,"Deposit:",true,tabs[4])
		settingLabel[6] = guiCreateLabel(0.5508,0.2668,0.2519,0.0855,"Withdraw:",true,tabs[4])
		settingLabel[7] = guiCreateLabel(0.5508,0.386,0.2519,0.0855,"Home:",true,tabs[4])
		settingLabel[8] = guiCreateLabel(0.5508,0.5052,0.2519,0.0855,"Delete:",true,tabs[4])

		settingEdit["invite"] = guiCreateEdit(0.2237,0.1477,0.0977,0.0855,"",true,tabs[4]) 
		guiEditSetReadOnly(settingEdit["invite"], true) 
		guiEditSetMaxLength(settingEdit["invite"], 1)

		settingEdit["warn"] = guiCreateEdit(0.2237,0.2539,0.0977,0.0855,"",true,tabs[4]) 
		guiEditSetReadOnly(settingEdit["warn"], true) 
		guiEditSetMaxLength(settingEdit["warn"], 1)

		settingEdit["kick"] = guiCreateEdit(0.2237,0.3575,0.0977,0.0855,"",true,tabs[4]) 
		guiEditSetReadOnly(settingEdit["kick"], true) 
		guiEditSetMaxLength(settingEdit["kick"], 1)

		settingEdit["level"] = guiCreateEdit(0.2237,0.4689,0.0977,0.0855,"",true,tabs[4]) 
		guiEditSetReadOnly(settingEdit["level"], true) 
		guiEditSetMaxLength(settingEdit["level"], 1)

		settingEdit["deposit"] = guiCreateEdit(0.6842,0.1477,0.0977,0.0855,"",true,tabs[4]) 
		guiEditSetReadOnly(settingEdit["deposit"], true) 
		guiEditSetMaxLength(settingEdit["deposit"], 1)

		settingEdit["withdraw"] = guiCreateEdit(0.6842,0.2487,0.0977,0.0855,"",true,tabs[4]) 
		guiEditSetReadOnly(settingEdit["withdraw"], true) 
		guiEditSetMaxLength(settingEdit["withdraw"], 1)

		settingEdit["motd"] = guiCreateEdit(0.6842,0.3523,0.0977,0.0855,"",true,tabs[4]) 
		guiEditSetReadOnly(settingEdit["motd"], true) 
		guiEditSetMaxLength(settingEdit["motd"], 1)

		settingEdit["delete"] = guiCreateEdit(0.6842,0.456,0.0977,0.0855,"",true,tabs[4])
		guiEditSetReadOnly(settingEdit["delete"], true) 
		guiEditSetMaxLength(settingEdit["delete"], 1)

		settingChangeButton = guiCreateButton(0.0526,0.65,0.2914,0.114,"Change",true,tabs[4])
		settingSaveButton = guiCreateButton(0.5414,0.65,0.2914,0.114,"Save",true,tabs[4])

		memos[5] = guiCreateMemo(0,0.7604,1,0.2396,"This is the settings panel - only the leader can change settings.",true,tabs[4])
		guiMemoSetReadOnly(memos[5],true)

		guiSetVisible(gangPanel, true)
		showCursor(true)
		leaveClick = 0
		deleteClick = 0
		transferClick = 0

		-- Add Handlers!
		addEventHandler("onClientGUIClick", homeChangeButton, changeMOTD, false)
		addEventHandler("onClientGUIClick", homeSaveButton, saveMOTD, false)

		addEventHandler("onClientGUIClick", inviteButton, inviteTrigger, false)
		addEventHandler("onClientGUIClick", levelButton, levelTrigger, false)
		addEventHandler("onClientGUIClick", unlevelButton, unlevelTrigger, false)
		addEventHandler("onClientGUIClick", warnButton, warnTrigger, false)
		addEventHandler("onClientGUIClick", unwarnButton, unwarnTrigger, false)
		addEventHandler("onClientGUIClick", kickButton, kickTrigger, false)
		addEventHandler("onClientGUIClick", leaveButton, leaveTrigger, false)
		addEventHandler("onClientGUIClick", transferButton, transferTrigger, false)
		addEventHandler("onClientGUIClick", deleteButton, deleteTrigger, false)

		addEventHandler("onClientGUIClick", depositButton, depositMoney, false)
		addEventHandler("onClientGUIClick", withdrawButton, withdrawMoney, false)

		addEventHandler("onClientGUIClick", settingChangeButton, changeSettings, false)
		addEventHandler("onClientGUIClick", settingSaveButton, saveSettings, false)

		addEventHandler("onClientGUIClick", closeButton, closePanel, false)
	end
end
addEvent("displayPanel", true)
addEventHandler("displayPanel", getRootElement() ,displaygangPanel)

function populategangPanel(ganginfo, gangmembers, playerAccountName)
	client_ganginfo = ganginfo
	client_gangmembers = gangmembers
	client_playeraccount = playerAccountName
	
	if gangPanel then
	-- Window
	guiSetText(gangPanel, ganginfo['gangname'])
	
	-- Homepage
	guiSetText(motdMemo, ganginfo['hometext'])
	
	-- Memberlist
	guiGridListClear(memberGrid)
	for i, v in ipairs(gangmembers) do
		local row = guiGridListAddRow ( memberGrid )
        guiGridListSetItemText ( memberGrid, row, 1, v['lastname'], false, false )
		guiGridListSetItemText ( memberGrid, row, 2, v['lastlogin'], false, true )
		guiGridListSetItemText ( memberGrid, row, 3, v['accountname'], false, false )
		guiGridListSetItemText ( memberGrid, row, 4, v['level'], false, true )
		guiGridListSetItemText ( memberGrid, row, 5, v['warnings'], false, true )
		if v['online'] then
			guiGridListSetItemColor(memberGrid, row, 1, 255, 255, 0)
		end
		if(v['accountname'] == playerAccountName) then
			localplayer_info = v
			localplayerlevel = v['level']
		end		
	end
	
	-- Money
	guiSetText(cashLabel, ganginfo['money'])
	
	-- Opts
	guiSetText(settingEdit["invite"], ganginfo["inviteperm"])
	guiSetText(settingEdit["motd"], ganginfo["motdperm"])
	guiSetText(settingEdit["kick"], ganginfo["kickperm"])
	guiSetText(settingEdit["level"], ganginfo["levelperm"])
	guiSetText(settingEdit["warn"], ganginfo["warnperm"])
	guiSetText(settingEdit["deposit"], ganginfo["depositperm"])
	guiSetText(settingEdit["withdraw"], ganginfo["withdrawperm"])
	guiSetText(settingEdit["delete"], ganginfo["deleteperm"])
	end
end
addEvent("populatePanel", true)
addEventHandler("populatePanel", getRootElement() ,populategangPanel) --]]

function displayInvitePanel(nubs)
	local canInvite = false
	if not isElement(inviteWindow) then
		inviteWindow = guiCreateWindow(0.4, 0.2744, 0.25, 0.6, "Invite Player", true)
		guiSetAlpha(inviteWindow, 1)
		inviteGrid = guiCreateGridList(0.03, 0.06, 0.9, 0.8, true, inviteWindow)
		guiGridListSetSelectionMode(inviteGrid, 0)
		column = guiGridListAddColumn(inviteGrid, "Available Players", 0.85)
		inv_yesbtn = guiCreateButton(0.02, 0.9, 0.4, 0.06, "Invite", true, inviteWindow)
		inv_nobtn = guiCreateButton(0.5, 0.9, 0.4, 0.06, "Cancel", true, inviteWindow)
		guiSetVisible(inviteWindow, true)
		
		for i,v in ipairs(nubs) do
			local row = guiGridListAddRow(inviteGrid)
			guiGridListSetItemText(inviteGrid, row, column, v ,false, false)
		end
		
		addEventHandler("onClientGUIClick", inv_yesbtn, invitePanelHandler)
		addEventHandler("onClientGUIClick", inv_nobtn, function() 
		if inviteWindow then
			destroyElement(inviteWindow)
			inviteWindow = nil
		end
		end)
	end
end
addEvent("displayInvite", true)
addEventHandler("displayInvite", getRootElement(), displayInvitePanel)

-- Invite panel handler here - misplaced but who cares dude
function invitePanelHandler(button, state)
	if button == "left" and state == "up" then
		if guiGridListGetSelectedCount(inviteGrid) == 1 then
			local row, column = guiGridListGetSelectedItem(inviteGrid)
			local player = guiGridListGetItemText(inviteGrid, row, column)
			local player = getPlayerFromName(player)
			if player and isElement(player) and getElementType(player) == "player" then
				local thisTime = getRealTime()
				local thisTimestamp = thisTime.timestamp
				
				local canInvite = false
				if not lastInvite then canInvite = true end
				if lastInvite then
					if (tonumber(thisTimestamp) - tonumber(lastInvite)) >= 300 then
						canInvite = true
					end
				end
				if canInvite then
					triggerServerEvent("_inviteStep2", getLocalPlayer(), getPlayerName(player))
					destroyElement(inviteWindow)
					lastInvite = thisTimestamp
				else
					displayError("You can only invite someone once in 5 minutes.")
				end
			end
		end
	end
end

-- Invited Panel FTW
function displayInvitedPanel(gangname)
	if not isElement(invitedWindow) then
		invitedWindow = guiCreateWindow(541,227,383,206,"Invitation",false)

		retardedLabel = guiCreateLabel(0.2089,0.1505,0.5692,0.1068,"You've been invited to join:",true,invitedWindow)
		guiLabelSetHorizontalAlign(retardedLabel,"center",false)

		gangLabel = guiCreateLabel(0.2089,0.3204,0.5692,0.1068,gangname,true,invitedWindow)
		guiLabelSetHorizontalAlign(gangLabel,"center",false)
		guiSetFont(gangLabel,"default-bold-small")
		
		playerLabel = guiCreateLabel(0.2089,0.44,0.5692,0.1068,getPlayerName(source),true,invitedWindow)
		guiLabelSetHorizontalAlign(playerLabel,"center",false)
		guiSetFont(playerLabel,"default-bold-small")

		invitedYesBTN = guiCreateButton(0.0809,0.5825,0.3916,0.3058,"Accept",true,invitedWindow)
		guiSetFont(invitedYesBTN,"sa-header")
		addEventHandler("onClientGUIClick", invitedYesBTN, function() triggerServerEvent("_inviteFin", getLocalPlayer(), guiGetText(playerLabel), guiGetText(gangLabel)) destroyElement(invitedWindow) showCursor(false) end, false)

		invitedNoBTN = guiCreateButton(0.5222,0.5825,0.3916,0.3058,"Reject",true,invitedWindow)
		guiSetFont(invitedNoBTN,"sa-header")
		addEventHandler("onClientGUIClick", invitedNoBTN, function() destroyElement(invitedWindow) showCursor(false) end, false)
		showCursor(true)
	end
end
addEvent("inviteReceive", true)
addEventHandler("inviteReceive", getRootElement(), displayInvitedPanel)

function createMessageBox()
	errorWindow = guiCreateWindow(mainX / 2 - 150, mainY / 2 - 100, 300, 200, "Information", false)
	errorLabel = guiCreateMemo(5, 25, 295, 125, "", false, errorWindow)
	guiMemoSetReadOnly(errorLabel, true)
	errorWindowButton = guiCreateButton(110, 160, 80, 25, "OK", false, errorWindow)
	guiWindowSetMovable(errorWindow, false)
	guiWindowSetSizable(errorWindow, false)
	guiSetVisible(errorWindow, false)
	addEventHandler("onClientGUIClick", errorWindowButton, function()
	guiSetVisible(errorWindow, false)
	guiSetProperty(errorWindow, "AlwaysOnTop", "False")
	errorWindow = nil
	if not gangPanel and not inviteWindow then
		showCursor(false)
	end
	end, false)
end

function displayError(error)
	if not errorWindow then
		createMessageBox()
	end
	guiSetText(errorLabel, error)
	guiSetProperty(errorWindow, "AlwaysOnTop", "True")
	guiSetVisible(errorWindow, true)
	showCursor(true)
end
addEvent("errorDisplay", true)
addEventHandler("errorDisplay", getRootElement(), displayError)

function closePanel()
	if gangPanel then
		destroyElement(gangPanel)
		gangPanel = nil
	end
	if errorWindow then
		destroyElement(errorWindow)
		errorWindow = nil
	end
	if inviteWindow then
		destroyElement(inviteWindow)
		inviteWindow = nil
	end
	showCursor(false)
end


------------------------------------------------------------ HANDLER FUNCTIONS -----------------------------------------------------------
-- Home triggers
function changeMOTD(button, state)
	if button == "left" and state == "up" and source == homeChangeButton then
		if localplayerlevel >= client_ganginfo['motdperm'] then
			guiMemoSetReadOnly(motdMemo, false)
		end
	end
end


function saveMOTD(button, state)
--	if button == "left" and state == "up" and source == homeSaveButton then
		if localplayerlevel >= client_ganginfo['motdperm'] then
			local newMotd = guiGetText(motdMemo)
			triggerServerEvent("_saveMOTD", getLocalPlayer(), newMotd)
			guiMemoSetReadOnly(motdMemo, true)
		end
--	end
end


-- Member Triggers
function inviteTrigger(button, state)
	if button == "left" and state == "up" and source == inviteButton then
		if localplayerlevel >= client_ganginfo['inviteperm'] then
			triggerServerEvent("_invitePlayer", getLocalPlayer())
		end
	end
end


function levelTrigger(button, state)
	if button == "left" and state == "up" and source == levelButton then
		if localplayerlevel >= client_ganginfo['levelperm'] then
			if guiGridListGetSelectedCount ( memberGrid ) == 5 then
				local row = guiGridListGetSelectedItem(memberGrid)
				local accountname = guiGridListGetItemText(memberGrid, row, accountColumn )
				local chosenplayerlevel = guiGridListGetItemText(memberGrid, row, levelColumn)
				local nextlevel = tonumber(chosenplayerlevel) + 1
				if localplayerlevel > nextlevel then
					if tonumber(chosenplayerlevel) < 5 then
						triggerServerEvent("_levelPlayer", getLocalPlayer(), accountname )
					end
				else
					displayError("You can only level up players below your level!")
				end
			else
				displayError("Please select a member!")
			end
		end
	end
end


function unlevelTrigger(button, state)
	if button == "left" and state == "up" and source == unlevelButton then
		if localplayerlevel >= client_ganginfo['levelperm'] then
			if guiGridListGetSelectedCount ( memberGrid ) == 5 then
				local row = guiGridListGetSelectedItem(memberGrid)
				local accountname = guiGridListGetItemText(memberGrid, row, accountColumn )
				local chosenplayerlevel = guiGridListGetItemText(memberGrid, row, levelColumn)
				if localplayerlevel > tonumber(chosenplayerlevel) then
					if tonumber(chosenplayerlevel) > 0 then
						triggerServerEvent("_unlevelPlayer", getLocalPlayer(), accountname )
					end
				else
					displayError("You can only level down players below your level!")
				end
			else
				displayError("Please select a member!")
			end
		end
	end
end

function warnTrigger(button, state)
	if button == "left" and state == "up" and source == warnButton then
		if localplayerlevel >= client_ganginfo['warnperm'] then
			if guiGridListGetSelectedCount ( memberGrid ) == 5 then
				local row = guiGridListGetSelectedItem(memberGrid)
				local accountname = guiGridListGetItemText(memberGrid, row, accountColumn )
				local chosenplayerlevel = guiGridListGetItemText(memberGrid, row, levelColumn)
				local chosenplayerwarning = guiGridListGetItemText(memberGrid, row, warningColumn)
				if localplayerlevel > tonumber(chosenplayerlevel) then
					if tonumber(chosenplayerwarning) < 5 then
						triggerServerEvent("_warnPlayer", getLocalPlayer(), accountname)
					end
				else
					displayError("You can only add warnings to players below your level!")
				end
			else
				displayError("Please select a member!")
			end
		end
	end
end

function unwarnTrigger(button, state)
	if button == "left" and state == "up" and source == unwarnButton then
		if localplayerlevel >= client_ganginfo['warnperm'] then
			if guiGridListGetSelectedCount ( memberGrid ) == 5 then
				local row = guiGridListGetSelectedItem(memberGrid)
				local accountname = guiGridListGetItemText(memberGrid, row, accountColumn )
				local chosenplayerlevel = guiGridListGetItemText(memberGrid, row, levelColumn)
				local chosenplayerwarning = guiGridListGetItemText(memberGrid, row, warningColumn)
				if localplayerlevel > tonumber(chosenplayerlevel) then
					if tonumber(chosenplayerwarning) > 0 then
						triggerServerEvent("_unwarnPlayer", getLocalPlayer(), accountname)
					end
				else
					displayError("You can only remove warnings of players below your level!")
				end
			else
				displayError("Please select a member!")
			end
		end
	end
end

function kickTrigger(button, state)
	if button == "left" and state == "up" and source == kickButton then
		if localplayerlevel >= client_ganginfo['kickperm'] then
			if guiGridListGetSelectedCount ( memberGrid ) == 5 then
				local row = guiGridListGetSelectedItem(memberGrid)
				local accountname = guiGridListGetItemText(memberGrid, row, accountColumn )
				local chosenplayerlevel = guiGridListGetItemText(memberGrid, row, levelColumn)
				if localplayerlevel > tonumber(chosenplayerlevel) then
					triggerServerEvent("_kickPlayer", getLocalPlayer(), accountname)
				else
					displayError("You can only kick players below your level!")
				end
			else
				displayError("Please select a member!")
			end
		end
	end
end

function leaveTrigger(button, state)
	if button == "left" and state == "up" and source == leaveButton then
		if leaveClick == 0 then
			leaveClick = 1
			outputChatBox("Are you sure that you want to leave this gang? If yes, press the button again.", 255, 0, 0)
		elseif leaveClick == 1 then
			triggerServerEvent("_leavegang", getLocalPlayer())
			closePanel()
		end
	end
end

function transferTrigger(button, state)
	if button == "left" and state == "up" and source == transferButton then
		if localplayerlevel == 5 then
			if transferClick == 0 then
				transferClick = 1
				outputChatBox("Are you sure that you want to give away your leadership? If yes, press the button again.", 255, 0, 0)
			elseif transferClick == 1 then
				if guiGridListGetSelectedCount ( memberGrid ) == 5 then
					local row = guiGridListGetSelectedItem(memberGrid)
					local accountname = guiGridListGetItemText(memberGrid, row, accountColumn )
					local chosenplayerlevel = guiGridListGetItemText(memberGrid, row, levelColumn)
					triggerServerEvent("_transferLeadership", getLocalPlayer(), accountname)
				else
					displayError("Please select a member!")
				end
			end
		end
	end
end

function deleteTrigger(button, state)
	if button == "left" and state == "up" and source == deleteButton then
		if localplayerlevel >= client_ganginfo['deleteperm'] then
			if deleteClick == 0 then
				outputChatBox("Are you sure that you want to delete this gang? If yes, press the button again.", 255, 0, 0)
				deleteClick = 1
			elseif deleteClick == 1 then
				triggerServerEvent("_deletegang", getLocalPlayer())
				closePanel()
			end
		end
	end
end

-- Money triggers
function depositMoney(button, state)
	if button == "left" and state == "up" and source == depositButton then
		if localplayerlevel >= client_ganginfo['depositperm'] then
			local depositMoney = guiGetText(depositEdit)
			if tonumber(depositMoney) <= getPlayerMoney() then
				triggerServerEvent("_depositMoney", getLocalPlayer(), depositMoney)
			else
				displayError("You don't have that much money!")
			end
		end
	end
end

function withdrawMoney(button, state)
	if button == "left" and state == "up" and source == withdrawButton then
		if localplayerlevel >= client_ganginfo['withdrawperm'] then
			local withdrawMoney = tonumber(guiGetText(withdrawEdit))
			local gangMoney = client_ganginfo['money']
			if withdrawMoney <= gangMoney then
				triggerServerEvent("_withdrawMoney", getLocalPlayer(), withdrawMoney)
			else
				displayError("There isn't that much money in the gang account!")
			end
		end
	end
end

-- Setting triggers
function changeSettings(button, state)
	if button == "left" and state == "up" and source == settingChangeButton then
		if localplayerlevel == 5 then
			guiEditSetReadOnly(settingEdit["invite"], false) 
			guiEditSetReadOnly(settingEdit["warn"], false) 
			guiEditSetReadOnly(settingEdit["kick"], false) 
			guiEditSetReadOnly(settingEdit["level"], false) 
			guiEditSetReadOnly(settingEdit["deposit"], false) 
			guiEditSetReadOnly(settingEdit["withdraw"], false) 
			guiEditSetReadOnly(settingEdit["motd"], false) 
			guiEditSetReadOnly(settingEdit["delete"], false) 
		end
	end
end

function saveSettings(button, state)
	if button == "left" and state == "up" and source == settingSaveButton then
		if localplayerlevel == 5 then
			guiEditSetReadOnly(settingEdit["invite"], true) 
			guiEditSetReadOnly(settingEdit["warn"], true) 
			guiEditSetReadOnly(settingEdit["kick"], true) 
			guiEditSetReadOnly(settingEdit["level"], true) 
			guiEditSetReadOnly(settingEdit["deposit"], true) 
			guiEditSetReadOnly(settingEdit["withdraw"], true) 
			guiEditSetReadOnly(settingEdit["motd"], true) 
			guiEditSetReadOnly(settingEdit["delete"], true) 
			local inviteperm = tonumber(guiGetText(settingEdit['invite']))
			local warnperm = tonumber(guiGetText(settingEdit['warn']))
			local kickperm = tonumber(guiGetText(settingEdit['kick']))
			local levelperm = tonumber(guiGetText(settingEdit['level']))
			local depositperm = tonumber(guiGetText(settingEdit['deposit']))
			local withdrawperm = tonumber(guiGetText(settingEdit['withdraw']))
			local motdperm = tonumber(guiGetText(settingEdit['motd']))
			local deleteperm = tonumber(guiGetText(settingEdit['delete']))
			if inviteperm >= 0 and inviteperm <= 5 and warnperm >= 0 and warnperm <= 5 and kickperm >= 0 and kickperm <= 5 and levelperm >= 0 and levelperm <= 5 and depositperm >= 0 and depositperm <= 5 and withdrawperm >= 0 and withdrawperm <= 5 and motdperm >= 0 and motdperm <= 5 and deleteperm >= 0 and deleteperm <= 5 then
				triggerServerEvent("_saveSettings", getLocalPlayer(), inviteperm, warnperm, kickperm, levelperm, depositperm, withdrawperm, motdperm, deleteperm)
			end
		end
	end
end