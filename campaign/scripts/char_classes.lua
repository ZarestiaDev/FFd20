-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("HRXP", onAdvancementChanged);
    DB.addHandler(DB.getPath(getDatabaseNode(), "level"), "onUpdate", calculateNeededXP)
	onAdvancementChanged();
end

function onClose()
	OptionsManager.unregisterCallback("HRXP", onAdvancementChanged);
    DB.removeHandler(DB.getPath(getDatabaseNode(), "level"), "onUpdate", calculateNeededXP)
end

function onDrop(x, y, draginfo)
    if draginfo.isType("shortcut") then
        local sClass, sRecord = draginfo.getShortcutData();
        if sClass == "referenceclass" then
            CharManager.addInfoDB(getDatabaseNode(), sClass, sRecord);
            return true;
        end
    end
end

function onAdvancementChanged()
    local sOption = OptionsManager.getOption("HRXP");
    advancement_label.setValue(StringManager.capitalize(sOption));

    calculateNeededXP();
end

function calculateNeededXP()
    local nodeChar = getDatabaseNode();
    local nLevel = DB.getValue(nodeChar, "level", 0);
    local sOption = OptionsManager.getOption("HRXP");
    local nXP = 0;

    if nLevel >= 20 then
        nLevel = 19;
    end

    if sOption == "slow" then
        nXP = DataCommon.slowxp[nLevel];
    elseif sOption == "medium" then
        nXP = DataCommon.mediumxp[nLevel];
    elseif sOption == "fast" then
        nXP = DataCommon.fastxp[nLevel];
    else
        nXP = 0;
    end

    DB.setValue(nodeChar, "expneeded", "number", nXP);
end
