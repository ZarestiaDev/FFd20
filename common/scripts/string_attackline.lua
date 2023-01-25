-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

local parsed = false;
local rAttackRolls = {};
local rDamageRolls = {};
local rAttackCombos = {};

local hoverDamage = nil;
local hoverAttack = nil;
local clickDamage = nil;
local clickAttack = nil;

function onValueChanged()
	parsed = false;
end

function onHover(oncontrol)
	if dragging then
		return;
	end

	-- Reset selection when the cursor leaves the control
	if not oncontrol then
		-- Clear hover tracking
		hoverDamage = nil;
		hoverAttack = nil;
		
		-- Clear any selections
		setSelectionPosition(0);
	end
end

function onHoverUpdate(x, y)
	-- If we're typing or dragging, then exit
	if dragging then
		return;
	end

	-- Compute the locations of the relevant phrases, and the mouse
	local nMouseIndex = getIndexAt(x, y);
	if not parsed then
		parsed = true;
		rAttackRolls, rDamageRolls, rAttackCombos = CombatManager2.parseAttackLine(getActor(), getValue());
	end

	hoverDamage = nil;
	hoverAttack = nil;
	
	for i = 1, #rDamageRolls do
		if rDamageRolls[i].startpos <= nMouseIndex and rDamageRolls[i].endpos > nMouseIndex then
			hoverDamage = i;			
			setCursorPosition(rDamageRolls[i].startpos);
			setSelectionPosition(rDamageRolls[i].endpos);

			setHoverCursor("hand");
			return;
		end
	end
	
	for i = 1, #rAttackCombos do
		local nFirst = rAttackCombos[i][1];
		local nLast = rAttackCombos[i][#(rAttackCombos[i])];
		
		if rAttackRolls[nFirst].startpos <= nMouseIndex and rAttackRolls[nLast].endpos > nMouseIndex then
			hoverAttack = i;
			setCursorPosition(rAttackRolls[nFirst].startpos);
			setSelectionPosition(rAttackRolls[nLast].endpos);

			setHoverCursor("hand");
			return;
		end
	end

	-- Reset the cursor
	setHoverCursor("arrow");
end

function onClickDown(button, x, y)
	-- Suppress default processing to support dragging
	clickDamage = hoverDamage;
	clickAttack = hoverAttack;
	
	return true;
end

function onClickRelease(button, x, y)
	-- Enable edit mode on mouse release
	setFocus();
	
	local n = getIndexAt(x, y);
	
	setSelectionPosition(n);
	setCursorPosition(n);
	
	return true;
end

function getActor()
	local nodeActor = nil;
	local node = getDatabaseNode();
	if node then
		nodeActor = DB.getChild(node, actorpath[1]);
	end
	
	return ActorManager.resolveActor(nodeActor);
end

function actionDamage(draginfo, rDamage)
	ActionDamage.performRoll(draginfo, getActor(), rDamage);
	return true;
end

function actionAttack(draginfo, rAttackCombo)
	local rActor = getActor();
	
	local nFirst = rAttackCombo[1];
	local nLast = rAttackCombo[#rAttackCombo];
		
	-- Build attack modifiers table, and track attack count
	local nModCount = 0;
	local aAttackModifiers = {};
	for i = nFirst, nLast do
		local rAttack = rAttackRolls[i];

		aAttackModifiers[i] = {};
		for w in string.gmatch(rAttack.modifier, "([%+%-]?%d+)/?") do
			table.insert(aAttackModifiers[i], w);
		end

		nModCount = nModCount + (rAttack.count * #(aAttackModifiers[i]));
	end
	
	local rRolls = {};
	for i = nFirst, nLast do
		local rAttack = rAttackRolls[i];

		-- Break modifier into attacks
		for j = 1, rAttack.count do
			for k = 1, #(aAttackModifiers[i]) do
				-- Determine the attack #, if any
				local nAttack = 1;
				if #(aAttackModifiers[i]) <= 1 then
					if tonumber(rAttack.count) > 1 then
						nAttack = j;
					end
				else
					nAttack = k;
				end
				
				local rAttack2 = {};
				for k2, v2 in pairs(rAttack) do
					rAttack2[k2] = v2;
				end
				rAttack2.modifier = tonumber(aAttackModifiers[i][k]) or 0;
				rAttack2.order = nAttack;

				-- Build the attack roll
				table.insert(rRolls, ActionAttack.getRoll(rActor, rAttack2));
			end
		end
	end
	
	if not OptionsManager.isOption("RMMT", "off") and #rRolls > 1 then
		for _,v in ipairs(rRolls) do
			v.sDesc = v.sDesc .. " [FULL]";
		end
	end
	
	ActionsManager.performMultiAction(draginfo, rActor, "attack", rRolls);
	
	return true;
end

function onDoubleClick(x, y)
	if hoverDamage then
		return actionDamage(nil, rDamageRolls[hoverDamage]);
	end
	
	if hoverAttack then
		return actionAttack(nil, rAttackCombos[hoverAttack]);
	end
	
	return false;
end

function onDragStart(button, x, y, draginfo)
	if clickAttack or clickDamage then
		if clickDamage then
			actionDamage(draginfo, rDamageRolls[clickDamage]);
		end
		
		if clickAttack then
			actionAttack(draginfo, rAttackCombos[clickAttack]);
		end
		
		clickDamage = nil;
		clickAttack = nil;
		dragging = true;
	end
	
	return true;
end

function onDragEnd(dragdata)
	setCursorPosition(0);
	dragging = false;
end
