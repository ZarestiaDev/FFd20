-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local parsed = false;

local bab = 0;
local bab_start = 0;
local bab_end = 0;

local cmb = 0;
local cmb_start = 0;
local cmb_end = 0;

local hoverbab = nil;
local hovercmb = nil;
local clickbab = nil;
local clickcmb = nil;

local dragging = false;

function onValueChanged()
	parsed = false;
end

function parseComponents()
	local sValue = getValue();
	
	local aSplit, aSplitStats = StringManager.split(sValue, "/", true);
	
	if aSplit[1] and StringManager.isNumberString(aSplit[1]) then
		bab = tonumber(aSplit[1]) or 0;
		bab_start = aSplitStats[1].startpos;
		bab_end = aSplitStats[1].endpos;
	else
		local sBAB;
		bab_start, bab_end, sBAB = string.find(sValue, "Base Atk ([+-]?%d+)");
		if sBAB then
			bab = tonumber(sBAB) or 0;
			bab_end = bab_end + 1;
		else
			bab = 0;
			bab_start = 0;
			bab_end = 0;
		end
	end
	
	if aSplit[2] and StringManager.isNumberString(aSplit[2]) then
		cmb = tonumber(aSplit[2]) or 0;
		cmb_start = aSplitStats[2].startpos;
		cmb_end = aSplitStats[2].endpos;
	else
		local sCMB;
		cmb_start, cmb_end, sCMB = string.find(sValue, "CMB ([+-]?%d+)");
		if sCMB then
			cmb = tonumber(sCMB) or 0;
			cmb_end = cmb_end + 1;
		else
			cmb = 0;
			cmb_start = 0;
			cmb_end = 0;
		end
	end
end

function onHover(oncontrol)
	if dragging then
		return;
	end

	-- Reset selection when the cursor leaves the control
	if not oncontrol then
		hoverbab = nil;
		hovercmb = nil;
		
		setCursorPosition(0);
	end
end

function onHoverUpdate(x, y)
	hoverx, hovery = x, y;

	if dragging then
		return;
	end

	hoverbab = nil;
	hovercmb = nil;
		
	if not parsed then
		parsed = true;
		parseComponents();
	end

	-- Hilight skill hovered on
	local index = getIndexAt(x, y);

	if (index >= bab_start and index < bab_end) then
		setCursorPosition(bab_start);
		setSelectionPosition(bab_end);
		
		hoverbab = true;
		
		setHoverCursor("hand");
		return true;
	end
	
	if (index >= cmb_start and index < cmb_end) then
		setCursorPosition(cmb_start);
		setSelectionPosition(cmb_end);
		
		hovercmb = true;
		
		setHoverCursor("hand");
		return true;
	end
	
	setHoverCursor("arrow");
	setCursorPosition(0);
end

function getActor()
	local nodeActor = nil;
	local node = getDatabaseNode();
	if node then
		nodeActor = DB.getChild(node, "..");
	end
	return ActorManager.resolveActor(nodeActor);
end

function actionBAB(draginfo)
	local rAttack = {};
	rAttack.label = Interface.getString("message_rollbab");
	rAttack.modifier = bab;
	rAttack.stat = "strength";
	
	local rActor = getActor();
	
	ActionAttack.performRoll(draginfo, rActor, rAttack);
	return true;
end

function actionCMB(draginfo)
	local rAttack = {};
	rAttack.label = "";
	rAttack.modifier = cmb;
	rAttack.stat = "strength";
	
	local rActor = getActor();

	ActionAttack.performCMBRoll(draginfo, rActor, rAttack);
	return true;
end

function onDoubleClick(x, y)
	if hoverbab then
		return actionBAB();
	end
	
	if hovercmb then
		return actionCMB();
	end
end

function onDragStart(button, x, y, draginfo)
	if clickbab then
		actionBAB(draginfo);
	end

	if clickcmb then
		actionCMB(draginfo);
	end

	clickbab = nil;
	clickcmb = nil;
	dragging = true;
	return true;
end

function onDragEnd(dragdata)
	setCursorPosition(0);
	dragging = false;
end

function onClickDown(button, x, y)
	-- Suppress default processing to support dragging
	clickbab = hoverbab;
	clickcmb = hovercmb;

	return true;
end

function onClickRelease(button, x, y)
	setFocus();

	local n = getIndexAt(x, y);
	setSelectionPosition(n);
	setCursorPosition(n);

	return true;
end

