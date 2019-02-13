--[[################################################################################################################################

AddonStub - A Stand-Alone Stub for loading and updating Stand-Alone Add-ons.
	by Drakanwulf and Hawkeye1889

AddonStub is a simple stub that has been designed and coded to provide a consistent method to load standalone add-ons including
itself. Because AddonStub was derived from the ESOUI LibStub (r5) add-on, its structure should be familiar to those who know
how LibStub works; however, AddonStub does some things differently than LibStub did them and it does some things that LibStub
never did. Hawkeye1889 and I would like to thank everyone who helped us develop, test, and document this add-on stub.

"Standalone" means that an AddonStub folder should be loaded by itself and should not be embedded within any other add-on
folders including yours. Use the ##DependsOn: directive to instruct the game to load an AddonStub before it attempts to load
your add-on.

As the game loads your add-on, AddonStub builds a control file with the same name as your add-on. This control file contains a
"manifest" table that has values extracted from your manifest file directives and other startup data returned as values from
other API functions. This occurs whenever AddonStub loads an add-on successfully. The table is available to each standalone
add-on that uses AddonStub to bootstrap its loading process.
If you load the "mer Torchbug" debugging utility from ESOUI at: (https://www.esoui.com/downloads/info1159-MerTorchbug.html), you
can view your add-on and its manifest tables and their contents by using "/tbug <youraddonname>" or
"/tbug <youraddonname>.manifest" chat commands. A "/tbug AddonStub" command shows you the control file contents for the stub that
helped the game load your add-on.

History:
	AddonStub is a descendant of the ESO "LibStub" library add-on which was derived from the World of Warcraft (WoW) LibStub
	library add-on. See http://www.wowace.com/wiki/LibStub for more information about the WoW LibStub.

	LibStub was developed for World of Warcraft and placed into the Public Domain by members of the WowAce community: Kaelten,
		Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, and joshborke.
	LibStub was ported from World of Warcraft and modified for use by Elder Scrolls Online by Seerah.
	LibStub was maintained, modified and updated to support ESO loading and other changes by Seerah, and then sirinsidiator.

API:
	AddonStub:Get( "addon" )
		Description: If the add-on name in "addon" exists in the ESO globals table (e.g. _G["addon"]), this function retrieves
			the "addon" and its version number. You can use this function to trap and fail duplicate load attempts of any 
			Stand-Alone add-on if you choose to do so. Please refer to the LibMaps add-on Init.lua module code if you wish to
			look at an example of how the two AddonStub API functions interact.
		Input:
			addon := string, name of the add-on (e.g. "AddonStub"). Between 1 and 64 alphanumeric characters long.
		Returns:
			nil, nil := This signal occurs whenever a global table entry for "addon" does not exist.
			pointer, version := The table entry for the add-on name in "addon"; the current version number for "addon". Because
				"pointer" contains an existing ESO add-on table entry, it is a signal that this is an attempt to load "addon"
				again. The code in your add-on decides whether to continue loading itself or to deliberately fail duplicate load
				requests.
				version := The AddOnVersion: number for the "addon" that was just loaded.

	AddonStub:New( "addon", version )
		Description: One of three results can occur whenever AddonStub:New tries to load an add-on:
			(1) It creates a new entry or resets an existing  entry in the in the ESO globals table (e.g. _G["MAJOR"]). The table
			entry contains the add-on's name (MAJOR) and its AddOnVersion (MINOR). The entry is created whenever this add-on has
			never been loaded before; the entry is reset and updated whenever MAJOR exists and the AddOnVersion number in MINOR
			is greater than the number in the table entry.
			(2) It refuses to load the add-on whenever MAJOR exists and the AddOnVersion number in MINOR is less (smaller) than
			the number in the table entry.
			(3) It retrieves the add-on and version number whenever MAJOR exists and the AddOnVersion number in MINOR equals the
			number in the table entry. This result was probably caused by another add-on embedding your add-on folder within
			itself. You can use the AddonStub:Get() function to trap these duplicate load requests if you choose to do so.
		Input:
			addon := string, name of the add-on (e.g. "AddonStub"). Between 1 and 64 alphanumeric characters long.
			version := positive integer between 1 and 2,147,483,647.  There are limited restrictions on	the integer value;
				however, there may be unexpected and/or undesired side-effects.
				The "version" value must match the ##AddOnVersion: directive value.
		Returns:
			nil, nil := This signal occurs whenever the add-on already exists but its version number is older (smaller) than the
				number in the global table entry. AddonStub refuses to load add-ons with old or out-of-date AddOnVersion numbers.
			pointer, version := The table entry for the add-on name in "addon" and the current version number for "addon".
				pointer := A pointer to the table entry for the current version of the add-on name in "addon"; the add-on may
					continue to initialize itself.
				version := The AddOnVersion number for "addon" that you want this load to use.

Table layout for:
"_G["addonName"]" = {
	manifest = {
		fileName = name,				-- Should be the complete path to the folder but it's not...
		title = Strip( title ),			-- "rawTitle" sans special characters
		author = Strip( auth ),			-- "rawAuthor" sans special characters
		description = desc,				-- From the manifest file
		isEnabled = enabled,			-- ESO boolean value
		loadState = state,				-- ESO load state
		isOutOfDate = isOOD,			-- ESO boolean value
		rawAuthor = auth,				-- From the manifest file
		rawTitle = title,				-- From the manifest file

		-- Fields I think should be in this table but are not... feel free to add to the list :)
		apiVersion = GetAPIVersion(),	-- Should be the value from the manifest file but it's not...
		addOnVersion = MINOR,			-- Should be the value from the manifest file but it's not...
	},
	addOnVersion = MINOR,				-- Should be the return value from an ESO API GetAddOnVersion() function but it's not...
	index = i,							-- Return value from the ESO API AddOnManager:GetAddOnInfo function
}

WARNING: This add-on is a stand-alone stub.  Do NOT embed it within your add-on's folder!
				
################################################################################################################################--]]

--[[--------------------------------------------------------------------------------------------------------------------------------
Local functions needed to build a manifest information table from the manifest directives and other data retrieved via the ESO
"AddOnManager:GetAddOnInfo()" API function. AddonStub builds this table for every add-on it loads.
----------------------------------------------------------------------------------------------------------------------------------]]
local function Strip( text: string )
    return text:gsub( "|c%x%x%x%x%x%x", "" )
end

-- Find our add-on in the ESO global add-ons table
local function BuildManifestTable( addonName: string )
	local AM = GetAddOnManager()
	local numAddOns = AM:GetNumAddOns()
	local i, search
	-- Iterate through the table entries 
    for i = 1, numAddOns do
        _, search = AM:GetAddOnInfo( i )
		if Strip( search ) == addonName then					-- We found a match!
			-- Load the table with addon manifest information
			local file, name, auth, desc, enabled, state, isOOD = AM:GetAddOnInfo( i )
			local manifestInfo = {
				fileName = file,						-- The file name
				rawAuthor = auth,						-- From the manifest file
				rawTitle = name,						-- From the manifest file
				author = Strip( auth ),					-- "rawAuthor" sans special characters
				title = Strip( name ),					-- "rawTitle" sans special characters
				description = desc,						-- From the manifest file
				isEnabled = enabled,					-- ESO boolean value
				loadState = state,						-- ESO load state (i.e. loaded; not loaded)
				isOutOfDate = isOOD,					-- ESO boolean value

				-- New fields as of API 100026
				addOnVersion = AM:GetAddOnVersion( i ) or 0,		-- The value from the manifest file
				filePath = AM:GetAddOnRootDirectoryPath( i ) or "",	-- Path to the add-on file

				-- Fields I wish were retrievable from the manifest file
				-- OODVersion = AM:GetAPIVersion( i ),					-- The API value from the manifest file...
			}

			return manifestInfo
		end
	end

	error( strformat( "AddonStub:BuildManifestTable: Could not find a matching add-on entry for %s.", addonName ), 2 )
end

--[[--------------------------------------------------------------------------------------------------------------------------------
Local variables shared by multiple functions in this add-on.
----------------------------------------------------------------------------------------------------------------------------------]]
local strformat = string.format
local oldversion

--[[--------------------------------------------------------------------------------------------------------------------------------
Bootstrap code to load or update AddonStub depending on whether its name and current version exist or not.
----------------------------------------------------------------------------------------------------------------------------------]]
-- Same MAJOR, MINOR parameters for AddonStub as for LibStub except MINOR must match the AddOnVersion: value in the manifest.
local MAJOR, MINOR = "AddonStub", 100

-- Either initialize or update AddonStub; everything else is a mistake!
local AddonStub = _G[MAJOR] or nil				-- Point to the latest AddonStub, if there is one.
if not AddonStub or AddonStub.addOnVersion < MINOR then
	AddonStub = {}
	AddonStub.manifest = BuildManifestTable( MAJOR )
	-- AddOnStub must have an AddOnVersion: directive in its manifest file, and...
	oldversion = AddonStub.manifest.addOnVersion
	if not oldversion or oldversion == 0 then
		error( strformat( "AddonStub:V%q: AddOnVersion number is missing from the Manifest!", tostring( MINOR ) ), 2 )
		return nil
		-- The numbers in the code and manifest must match!
	elseif oldversion ~= MINOR then
		error( strformat( "AddonStub:V%q: AddOnVersion numbers do not match (Manifest vs MINOR)!", tostring( MINOR ) ), 2 )
		return nil
	end
	
	AddonStub.addOnVersion = MINOR
	_G[MAJOR] = AddonStub

	--[[----------------------------------------------------------------------------------------------------------------------------
	Define the AddonStub load and update API functions.
	------------------------------------------------------------------------------------------------------------------------------]]
	local addon

	-- The Havok notation "addon: string" causes the Havok VM to type check the "addon" variable for string content.
	function AddonStub:Get( addonName: string )
		addon = _G[addonName]							-- Point to the latest version of addon, if there is one.
		if addon then
			return addon, addon.addOnVersion or nil
		else
			return nil, nil
		end
	end

	-- The Havok notation "version: number" causes the Havok VM to type check the "version" variable for numeric content.
	function AddonStub:New( addonName: string, version: number )
		addon = _G[addonName]							-- Point to the latest version of addon, if there is one.
		-- Either load the addon or update it. Anything else is a potential mistake!
		if not addon or addon.addOnVersion < version then
			addon = {}
			addon.manifest = BuildManifestTable( addonName )
			-- addonName must have an AddOnVersion: directive in its manifest file, and...
			oldversion = addon.manifest.addOnVersion
			if not oldversion or oldversion == 0 then
				error( strformat( "AddonStub:New: AddOnVersion directive is missing from the Manifest!", tostring( version ) ), 2 )
				return nil, nil
			-- The numbers in the code and manifest must match!
			elseif oldversion ~= version then
				error( strformat( "AddonStub:New: AddOnVersion values do not match!", tostring( version ) ), 2 )
				return nil, nil
			end
			
			addon.addOnVersion = version
			_G[addonName] = addon
			return addon, version

		-- Equal version numbers are signals of potential duplicates problems. In a standalone design, duplicate copies should
		-- be errors; however, the current (uncommented) code lets the invoking add-on decide if duplcates are an error or not.
		elseif oldversion == version then
			return _G[addonName], version or nil
		--	oldversion = addon.addOnVersion
		--	error( strformat( "AddonStub:New: Will not load duplicate copies of the same add-on! %s V%q", addonName, tostring( oldversion ) ), 2 )
		--	return nil, nil

		-- Reject allattempts to load older versions of any add-on.
		elseif oldversion > version then
			oldversion = addon.addOnVersion
			error( strformat( "AddonStub:New: Will not load older versions of the same add-on! %s V%q", addonName, tostring( oldversion ) ), 2 )
			return nil, nil
		end
	end
	
--[[--------------------------------------------------------------------------------------------------------------------------------
Because it is a standalone stub, AddonStub error handling traps and fails all attempts to load itself multiple times.
----------------------------------------------------------------------------------------------------------------------------------]]
elseif AddonStub.addOnVersion == MINOR then
	oldversion = AddonStub.addOnVersion or 0
	error( strformat( "AddonStub:V%q: Is already loaded. Do NOT load AddonStub twice!", tostring( oldversion ) ), 2 )
	return nil

-- Trying to load older, out-of-date, versions of any add-on is a gross oversight! 
elseif AddonStub.addOnVersion > MINOR then
	oldversion = AddonStub.addOnVersion or 0
	error( strformat( "AddonStub:V%q: Will not load older versions of itself!", tostring( oldversion ) ), 2 )
	return nil
end
