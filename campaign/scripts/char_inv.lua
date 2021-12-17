-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onEncumbranceChanged();
	DB.addHandler(DB.getPath(getDatabaseNode(), "abilities.strength.score"), "onUpdate", onStrengthChanged);
	DB.addHandler(DB.getPath(getDatabaseNode(), "size"), "onUpdate", onSizeChanged);
	DB.addHandler(DB.getPath(getDatabaseNode(), "encumbrance.stradj"), "onUpdate", onEncumbranceChanged);
	DB.addHandler(DB.getPath(getDatabaseNode(), "encumbrance.carrymult"), "onUpdate", onEncumbranceChanged);
end

function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "abilities.strength.score"), "onUpdate", onStrengthChanged);
	DB.removeHandler(DB.getPath(getDatabaseNode(), "size"), "onUpdate", onSizeChanged);
	DB.removeHandler(DB.getPath(getDatabaseNode(), "encumbrance.stradj"), "onUpdate", onEncumbranceChanged);
	DB.removeHandler(DB.getPath(getDatabaseNode(), "encumbrance.carrymult"), "onUpdate", onEncumbranceChanged);
end

function onStrengthChanged()
	onEncumbranceChanged();
end

function onSizeChanged()
	onEncumbranceChanged();
end

function onEncumbranceChanged()
	local nodeChar = getDatabaseNode();

	local nHeavy = 0;
	local nStrength = DB.getValue(nodeChar, "abilities.strength.score", 10);
	nStrength = nStrength + DB.getValue(nodeChar, "encumbrance.stradj", 0);
	if nStrength > 0 then
		if nStrength <= 10 then
			nHeavy = nStrength * 10;
		else
			nHeavy = 1.25 * math.pow(2, math.floor(nStrength / 5)) * math.floor((20 * math.pow(2, math.fmod(nStrength, 5) / 5)) + 0.5);
		end
	end
	
	nHeavy = nHeavy * DB.getValue(nodeChar, "encumbrance.carrymult", 1);
	
	local nLight = math.floor(nHeavy / 3);
	local nMedium = math.floor((nHeavy / 3) * 2);
	local nLiftOver = nHeavy;
	local nLiftOff = nHeavy * 2;
	local nPushDrag = nHeavy * 5;
	
	local nSize = ActorManagerFFd20.getSize(ActorManager.resolveActor(nodeChar));
	if (nSize < 0) then
		local nMult = 0;
		if (nSize == -1) then
			nMult = 0.75;
		elseif (nSize == -2) then
			nMult = 0.5;
		elseif (nSize == -3) then
			nMult = .25;
		elseif (nSize == -4) then
			nMult = .125;
		end
			
		nLight = math.floor(((nLight * nMult) * 100) + 0.5) / 100;
		nMedium = math.floor(((nMedium * nMult) * 100) + 0.5) / 100;
		nHeavy = math.floor(((nHeavy * nMult) * 100) + 0.5) / 100;
		nLiftOver = math.floor(((nLiftOver * nMult) * 100) + 0.5) / 100;
		nLiftOff = math.floor(((nLiftOff * nMult) * 100) + 0.5) / 100;
		nPushDrag = math.floor(((nPushDrag * nMult) * 100) + 0.5) / 100;
	elseif (nSize > 0) then
		local nMult = math.pow(2, nSize);
		
		nLight = nLight * nMult;
		nMedium = nMedium * nMult;
		nHeavy = nHeavy * nMult;
		nLiftOver = nLiftOver * nMult;
		nLiftOff = nLiftOff * nMult;
		nPushDrag = nPushDrag * nMult;
	end

	DB.setValue(nodeChar, "encumbrance.lightload", "number", nLight);
	DB.setValue(nodeChar, "encumbrance.mediumload", "number", nMedium);
	DB.setValue(nodeChar, "encumbrance.heavyload", "number", nHeavy);
	DB.setValue(nodeChar, "encumbrance.liftoverhead", "number", nLiftOver);
	DB.setValue(nodeChar, "encumbrance.liftoffground", "number", nLiftOff);
	DB.setValue(nodeChar, "encumbrance.pushordrag", "number", nPushDrag);
end
