-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--
--	INITIALIZATION AND HELPERS
--

local _sIdentity = nil
function setIdentity(s)
	_sIdentity = s;
end
function getIdentity()
	return _sIdentity
end
function getIdentityPath()
	return "charsheet." .. _sIdentity;
end
function getIdentityToken()
	return "portrait_" .. _sIdentity .. "_token"
end
function isIdentityOwned()
	if not _sIdentity then
		return false;
	end
	return User.isOwnedIdentity(_sIdentity);
end

--
--	UI
--

function setMenuItems(sIdentity)
	if resetMenuItems and registerMenuItem then
		resetMenuItems();
		if Session.IsHost then
			registerMenuItem(Interface.getString("charlist_menu_ring"), "bell", 5);
			registerMenuItem(Interface.getString("charlist_menu_kick"), "kick", 3);
			registerMenuItem(Interface.getString("charlist_menu_kickconfirm"), "kickconfirm", 3, 5);
			registerMenuItem(Interface.getString("charlist_menu_whisper"), "broadcast", 7);
		else
			if self.isIdentityOwned() then
				registerMenuItem(Interface.getString("charlist_menu_afk"), "hand", 3);
				registerMenuItem(Interface.getString("charlist_menu_release"), "erase", 5);
			else
				registerMenuItem(Interface.getString("charlist_menu_whisper"), "broadcast", 7);
			end
		end
	end
end
function onMenuSelection(selection, subselection)
	if selection == 7 then
		ChatManager.sendWhisperToID(self.getIdentity());
	else
		if Session.IsHost then
			if selection == 5 then
				User.ringBell(User.getIdentityOwner(self.getIdentity()));
			elseif selection == 3 and subselection == 5 then
				User.kick(User.getIdentityOwner(self.getIdentity()));
			end
		else
			if self.isIdentityOwned() then
				if selection == 3 then
					CharacterListManager.toggleAFK();
				elseif selection == 5 then
					User.releaseIdentity(self.getIdentity());
				end
			end
		end
	end
end

function onClickDown(button, x, y)
	return true;
end
function onClickRelease(button, x, y)
	if Session.IsHost then
		self.bringCharacterToTop();
	else
		if self.isIdentityOwned() then
			self.setCurrentIdentity(self.getIdentity());

			local aOwned = User.getOwnedIdentities();
			if #aOwned == 1 then
				self.bringCharacterToTop();
			end
		end
	end
	return true;
end
function onDoubleClick(x, y)
	if Session.IsHost or self.isIdentityOwned() then
		self.bringCharacterToTop();
	end
	return true;
end
function onDragStart(button, x, y, draginfo)
	if Session.IsHost or self.isIdentityOwned() then
		local sToken = self.getIdentityToken();
		local sPath = self.getIdentityPath();
		local sName = DB.getValue(DB.getPath(sPath, "name"), "");
		
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
	return CharacterListManager.processDrop(self.getIdentity(), draginfo);
end

--
--	STANDARD BEHAVIORS
--

function createWidgets(sIdentity)
	self.setIdentity(sIdentity);

	portraitwidget = addBitmapWidget("portrait_" .. sIdentity .. "_charlist");
	portraitwidget.setSize(CharacterListManager.PORTRAIT_SIZE, CharacterListManager.PORTRAIT_SIZE);

	namewidget = addTextWidget({
		font = "mini_name", text = "- Unnamed -", x = 0, y = 36, 
		frame = "mini_name", frameoffset="5,2,5,2", w = 65 
	});
	
	statewidget = addBitmapWidget({ x = -23, y = -23 });
	
	colorwidget = addBitmapWidget({ icon = "charlist_pointer", x = 35, y = 16 });
	colorwidget.setVisible(false);
end

function setCurrent(nCurrentState)
	if nCurrentState then
		namewidget.setFont("mini_name_selected");
		self.setActiveState("active");
	else
		namewidget.setFont("mini_name");
		self.setActiveState("active");
	end
end
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
function setName(sName)
	if sName ~= "" then
		namewidget.setText(sName);
	else
		namewidget.setText(Interface.getString("charlist_emptyname"));
	end
end
function updateColor()
	colorwidget.setColor(User.getIdentityColor(self.getIdentity()));
	colorwidget.setVisible(true);
end

function setCurrentIdentity(sIdentity)
	UserManager.activatePlayerID(sIdentity);
end

function bringCharacterToTop()
	local sPath = self.getIdentityPath();
	local wndMain = Interface.findWindow("charsheet", sPath);
	local wndMini = Interface.findWindow("charsheetmini", sPath);
	if wndMain then
		wndMain.bringToFront();
	elseif wndMini then
		wndMini.bringToFront();
	else
		Interface.openWindow("charsheet", sPath);
	end
end
