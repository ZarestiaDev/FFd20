-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if not Session.IsHost then
		TokenManager.addDefaultHealthFeatures(getHealthInfo, {"hp", "hptemp", "nonlethal", "wounds", "status"});
	else
		TokenManager.addDefaultHealthFeatures(getHealthInfo, {"hp", "hptemp", "nonlethal", "wounds"});
	end
	
	TokenManager.addEffectTagIconConditional("IF", handleIFEffectTag);
	TokenManager.addEffectTagIconSimple("IFT", "");
	TokenManager.addEffectTagIconBonus(DataCommon.bonuscomps);
	TokenManager.addEffectTagIconSimple(DataCommon.othercomps);
	TokenManager.addEffectConditionIcon(DataCommon.condcomps);
	TokenManager.addDefaultEffectFeatures(nil, EffectManager35E.parseEffectComp);
end

function getHealthInfo(nodeCT)
	local rActor = ActorManager.resolveActor(nodeCT);
	return ActorHealthManager.getTokenHealthInfo(rActor);
end

function handleIFEffectTag(rActor, nodeEffect, vComp)
	return EffectManager35E.checkConditional(rActor, nodeEffect, vComp.remainder);
end
