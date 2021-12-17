-- 
-- Please see the LICENSE.md file included with this distribution for 
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
	TokenManager.addDefaultEffectFeatures(nil, EffectManagerFFd20.parseEffectComp);
end

function getHealthInfo(nodeCT)
	local rActor = ActorManager.resolveActor(nodeCT);
	return ActorHealthManager.getTokenHealthInfo(rActor);
end

function handleIFEffectTag(rActor, nodeEffect, vComp)
	return EffectManagerFFd20.checkConditional(rActor, nodeEffect, vComp.remainder);
end
