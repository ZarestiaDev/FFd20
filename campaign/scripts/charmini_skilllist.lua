-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local nodeChar = getDatabaseNode().getParent();
	local sChar = nodeChar.getPath();
	DB.addHandler(sChar ..  ".abilities", "onChildUpdate", onStatUpdate);
end

function onClose()
	local nodeChar = getDatabaseNode().getParent();
	local sChar = nodeChar.getPath();
	DB.removeHandler(sChar ..  ".abilities", "onChildUpdate", onStatUpdate);
end

function onStatUpdate()
	for _,w in pairs(getWindows()) do
		w.onStatUpdate();
	end
end