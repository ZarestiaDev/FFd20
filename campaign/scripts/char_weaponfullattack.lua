-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local widgets = {};
local offsetx = 0;
local offsety = 0;

function onInit()
	offsetx = tonumber(icons[1].offsetx[1]);
	offsety = tonumber(icons[1].offsety[1]);

	updateWidgets();
	updateAttackFields();
end

function onValueChanged()
	updateWidgets();
	updateAttackFields();
end

function updateWidgets()
	for k, v in ipairs(widgets) do
		v.destroy();
	end
	widgets = {};

	local wt = window[icons[1].container[1]];
	local c = getValue();
	
	local w, h = getSize();
	
	for i = 1, c do
		local widget = wt.addBitmapWidget(icons[1].icon[1]);
		widget.setSize(10, 10);
		
		local ox = offsetx;
		if (i % 2) == 1 then
			ox = ox - 8;
		else
			ox = ox + 8;
		end
		local oy = offsety;
		if i <= 2 then
			oy = oy - 5;
		else
			oy = oy + 5;
		end
		widget.setPosition("center", ox, oy);
		
		widgets[i] = widget;
	end
end

function updateAttackFields()
	local c = getValue();
	
	if not isReadOnly() then
		window.attack1.setVisible(c >= 1);
		window.attack2.setVisible(c >= 2);
		window.attack3.setVisible(c >= 3);
		window.attack4.setVisible(c >= 4);
	end
end

function action(draginfo)
	local nValue = getValue();
	local nodeWeapon = window.getDatabaseNode();
	local rActor, rAttack = CharManager.getWeaponAttackRollStructures(nodeWeapon);
	
	local rRolls = {};
	local sAttack, aAttackDice, nAttackMod;
	for i = 1, getValue() do
		rAttack.modifier = DB.getValue(nodeWeapon, "attack" .. i, 0);
		rAttack.order = i;
		
		table.insert(rRolls, ActionAttack.getRoll(rActor, rAttack));
	end
	
	if not OptionsManager.isOption("RMMT", "off") and #rRolls > 1 then
		for _,v in ipairs(rRolls) do
			v.sDesc = v.sDesc .. " [FULL]";
		end
	end
	
	ActionsManager.performMultiAction(draginfo, rActor, "attack", rRolls);
	
	return true;
end

function onDragStart(button, x, y, draginfo)
	return action(draginfo);
end

function onDoubleClick(x,y)
	return action();
end			
