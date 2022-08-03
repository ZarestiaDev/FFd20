-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sIdentity = nil;

function setActiveState(sUserState)
	if sUserState == "idle" then
		statewidget.setBitmap("charlist_idling");
	elseif sUserState == "typing" then
		statewidget.setBitmap("charlist_typing");
	elseif sUserState == "afk" then
		statewidget.setBitmap("charlist_afk");
	else
		statewidget.setBitmap();
	end
end

function setCurrent(nCurrentState, sUserState)
	if nCurrentState then
		namewidget.setFont("mini_name_selected");
		setActiveState(sUserState);
	else
		namewidget.setFont("mini_name");
		setActiveState("active");
	end
end

function setName(sName)
	if sName ~= "" then
		namewidget.setText(sName);
	else
		namewidget.setText(Interface.getString("charlist_emptyname"));
	end
end

function updateColor()
	colorwidget.setColor(User.getIdentityColor(sIdentity));
	colorwidget.setVisible(true);
end

function createWidgets(name)
	sIdentity = name;
	
	portraitwidget = addBitmapWidget("portrait_" .. name .. "_charlist");
	-- OVERWRITE of CoreRPG to fix the connected character portraits in the upper left
	portraitwidget.setSize(72,72);
	-- OVERWRITE END
	
	namewidget = addTextWidget("mini_name", "- Unnamed -");
	namewidget.setPosition("center", 0, 36);
	namewidget.setFrame("mini_name", 5, 2, 5, 2);
	namewidget.setMaxWidth(65);
	
	statewidget = addBitmapWidget();
	statewidget.setPosition("center", -23, -23);
	
	colorwidget = addBitmapWidget("charlist_pointer");
	colorwidget.setPosition("center", 35, 16);
	colorwidget.setVisible(false);
end

function setMenuItems(name)
	resetMenuItems();
	if Session.IsHost then
		registerMenuItem(Interface.getString("charlist_menu_ring"), "bell", 5);
		registerMenuItem(Interface.getString("charlist_menu_kick"), "kick", 3);
		registerMenuItem(Interface.getString("charlist_menu_kickconfirm"), "kickconfirm", 3, 5);
		registerMenuItem(Interface.getString("charlist_menu_whisper"), "broadcast", 7);
	else
		if User.isOwnedIdentity(name) then
			registerMenuItem(Interface.getString("charlist_menu_afk"), "hand", 3);
			registerMenuItem(Interface.getString("charlist_menu_release"), "erase", 5);
		else
			registerMenuItem(Interface.getString("charlist_menu_whisper"), "broadcast", 7);
		end
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if Session.IsHost then
		bringCharacterToTop();
	else
		if User.isOwnedIdentity(sIdentity) then
			setCurrentIdentity(sIdentity);
			
			local aOwned = User.getOwnedIdentities();
			if #aOwned == 1 then
				bringCharacterToTop();
			end
		end
	end
	return true;
end

function onDoubleClick(x, y)
	if Session.IsHost or User.isOwnedIdentity(sIdentity) then
		bringCharacterToTop();
	end
	return true;
end

function onDragStart(button, x, y, draginfo)
	if Session.IsHost or User.isOwnedIdentity(sIdentity) then
		local sName = DB.getValue("charsheet." .. sIdentity .. ".name", "");
		local sToken = "portrait_" .. sIdentity .. "_token";
		local sPath = "charsheet." .. sIdentity;
		
		draginfo.setType("shortcut");
		draginfo.setTokenData(sToken);
		draginfo.setShortcutData("charsheet", sPath);
		draginfo.setStringData(sName);
		
		local base = draginfo.createBaseData();
		base.setType("token");
		base.setTokenData(sToken);
		
		return true;
	end
end

function onDrop(x, y, draginfo)
	return CharacterListManager.processDrop(sIdentity, draginfo);
end

function onMenuSelection(selection, subselection)
	if Session.IsHost then
		if selection == 5 then
			User.ringBell(User.getIdentityOwner(sIdentity));
		elseif selection == 3 and subselection == 5 then
			User.kick(User.getIdentityOwner(sIdentity));
		elseif selection == 7 then
			ChatManager.sendWhisperToID(sIdentity);
		end
	else
		if User.isOwnedIdentity(sIdentity) then
			if selection == 3 then
				CharacterListManager.toggleAFK();
			elseif selection == 5 then
				User.releaseIdentity(sIdentity);
			end
		else
			if selection == 7 then
				ChatManager.sendWhisperToID(sIdentity);
			end
		end
	end
end

function setCurrentIdentity(sCurrentIdentity)
	User.setCurrentIdentity(sCurrentIdentity);
	
	if CampaignRegistry and CampaignRegistry.colortables and CampaignRegistry.colortables[sCurrentIdentity] then
		local colortable = CampaignRegistry.colortables[sCurrentIdentity];
		User.setCurrentIdentityColors(colortable.color or "000000", colortable.blacktext or false);
	end
end

function bringCharacterToTop()
	local wndMain = Interface.findWindow("charsheet", "charsheet." .. sIdentity);
	local wndMini = Interface.findWindow("charsheetmini", "charsheet." .. sIdentity);
	if wndMain then
		wndMain.bringToFront();
	elseif wndMini then
		wndMini.bringToFront();
	else
		Interface.openWindow("charsheet", "charsheet." .. sIdentity);
	end
end
