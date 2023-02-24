-- 
-- Please see the LICENSE.md file included with this distribution for 
-- attribution and copyright information.
--

function deleteAll()
	DB.deleteChildren(getDatabaseNode());
end
