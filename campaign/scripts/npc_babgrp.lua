-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local parsed = false;

local bab = 0;
local bab_start = 0;
local bab_end = 0;

local grp = 0;
local grp_start = 0;
local grp_end = 0;

local hoverbab = nil;
local hovergrp = nil;
local clickbab = nil;
local clickgrp = nil;

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
		grp = tonumber(aSplit[2]) or 0;
		grp_start = aSplitStats[2].startpos;
		grp_end = aSplitStats[2].endpos;
	else
		local sGrp;
		grp_start, grp_end, sGrp = string.find(sValue, "CMB ([+-]?%d+)");
		if sGrp then
			grp = tonumber(sGrp) or 0;
			grp_end = grp_end + 1;
		else
			grp = 0;
			grp_start = 0;
			grp_end = 0;
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
		hovergrp = nil;
		
		setCursorPosition(0);
	end
end

function onHoverUpdate(x, y)
	hoverx, hovery = x, y;

	if dragging then
		return;
	end

	hoverbab = nil;
	hovergrp = nil;
		
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
	
	if (index >= grp_start and index < grp_end) then
		setCursorPosition(grp_start);
		setSelectionPosition(grp_end);
		
		hovergrp = true;
		
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
		nodeActor = node.getChild("..");
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

function actionGRP(draginfo)
	local rAttack = {};
	rAttack.label = "";
	rAttack.modifier = grp;
	rAttack.stat = "strength";
	
	local rActor = getActor();

	ActionAttack.performGrappleRoll(draginfo, rActor, rAttack);
	return true;
end

function onDoubleClick(x, y)
	if hoverbab then
		return actionBAB();
	end
	
	if hovergrp then
		return actionGRP();
	end
end

function onDragStart(button, x, y, draginfo)
	if clickbab then
		actionBAB(draginfo);
	end

	if clickgrp then
		actionGRP(draginfo);
	end

	clickbab = nil;
	clickgrp = nil;
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
	clickgrp = hovergrp;

	return true;
end

function onClickRelease(button, x, y)
	setFocus();

	local n = getIndexAt(x, y);
	setSelectionPosition(n);
	setCursorPosition(n);

	return true;
end

