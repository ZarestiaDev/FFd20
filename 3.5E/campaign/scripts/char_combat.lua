-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bInitialized = false;

function isInitialized()
	return bInitialized;
end

function onInit()
	bInitialized = true;
	
	acstat.onValueChanged();
	acstat2.onValueChanged();
	cmdbase.onValueChanged();
	cmdstat.onValueChanged();
	fortitudestat.onValueChanged();
	reflexstat.onValueChanged();
	willstat.onValueChanged();
	initiativestat.onValueChanged();
	meleestat.onValueChanged();
	rangedstat.onValueChanged();
	grapplestat.onValueChanged();

	onSystemChanged();
end

function onSystemChanged()
	local bPFMode = DataCommon.isPFRPG();
	
	line_cmd.setVisible(bPFMode);
	
	cmd.setVisible(bPFMode);
	label_cmd.setVisible(bPFMode);
	cmdacarmor.setVisible(bPFMode);
	cmdacshield.setVisible(bPFMode);
	cmdacstatmod.setVisible(bPFMode);
	cmdacsize.setVisible(bPFMode);
	cmdacnatural.setVisible(bPFMode);
	cmdacdeflection.setVisible(bPFMode);
	cmdacdodge.setVisible(bPFMode);
	cmdmisc.setVisible(bPFMode);
	
	cmdstat.setVisible(bPFMode);
	cmdstatmod.setVisible(bPFMode);
	cmdbase.setVisible(bPFMode);
	cmdbasemod.setVisible(bPFMode);
	
	if bPFMode then
		acframe.setStaticBounds(15,0,480,210);
		label_grapple.setValue(Interface.getString("cmb"));
	else
		acframe.setStaticBounds(15,0,480,140);
		label_grapple.setValue(Interface.getString("grapple"));
	end
end
