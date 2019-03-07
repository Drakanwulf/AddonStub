--[[################################################################################################################################

AddonStub - A standalone stub for loading and updating standalone add-ons.
	by Drakanwulf and Hawkeye1889

AddonStub is a simple, standalone, add-on stub that has been designed and coded to provide a consistent method to load standalone 
add-ons, including itself.

AddonStub is a descendant of the ESOUI LibStub (r5) add-on which was derived from the World of Warcraft (WoW) LibStub add-on. Its 
structure should be familiar to anyone who knows how LibStub works; however, AddonStub does some things differently than LibStub 
does them and AddonStub does some things that LibStub does not do. Hawkeye1889 and I would like to thank everyone who helped us 
develop, test, and document our add-on stub.

"Standalone" means that AddonStub should not be embedded. Please load only one instance of AddonStub from the "/Addons" directory 
and use the "##DependsOn:" directive to instruct the game to verify that an AddonStub exists before it loads your add-on. 
Do NOT embed an AddonStub folder within your add-on!

"Stub" means that AddonStub provides only an interface to help your add-on start up correctly and to prevent accidental attempts 
to load the same (or older) versions of an add-on multiple times.

API:
	Definitions:
		Duplicate := any add-on where the addonName in a control entry (e.g. _G["addonName"]) matches the addonName in the code 
			(e.g. "addonName" or MAJOR). AddOnVersion numbers determine what happens next when duplicates are found,
		MAJOR := Contains the "addonName" of this add-on enclosed in quotation marks.
		MINOR := Contains the AddOnVersion number for this add-on. Note: This number must exist in your code and it must match 
			the value in the AddOnVersion: directive in the manifest file.

	AddonStub:Get( "addonName" )
		Description: If a global control entry for "addonName" exists (e.g. _G[MAJOR]), this function accesses the manifest table 
			data in the control entry to return the values for "addonName" and "addonVersion".
			Use this function to detect duplicate start up attempts when your add-on needs to determine whether to discard, fail, 
			or continue executing a duplicate.
		Input:
			addonName := string, name of the add-on (e.g. "AddonStub"). Between 1 and 64 alphanumeric characters long.
		Returns:
			nil, nil := These return values indicate that a global control entry for "addonName" does not exist.
			addon, version := These return values indicate that the game is attempting to start up "addonName" again.
				addon := Contains a pointer to the global control entry for "addonName".
				version := Contains the AddOnVersion number for the duplicate copy of "addonName". The code in your add-on must 
					decide whether to: 
						* discard or fail the duplicate (code = control entry).
						* let the duplicate continue executing (code > control entry).
						* fail the duplicate (code < control entry).

	AddonStub:New( "addonName", version )
		Description: This function creates new or resets existing global control entries (e.g. _G[MAJOR]) for a given addonName. 
			The function creates new control entries whenever an add-on has never been started before; resets and reloads 
			existing control entries whenever the AddOnVersion number in MINOR is greater than the AddOnVersion number in the 
			control entry; and fails all other startup attempts.
		Input:
			addon := string, name of the add-on (e.g. "AddonStub"). Between 1 and 64 alphanumeric characters long.
			version := positive integer between 1 and 2,147,483,647.  There are limited restrictions on	the integer value; 
			however, there may be unexpected and/or undesired side-effects if the "version" number  is not greater than its 
			predecessor. The "version" number (e.g. MINOR) and the AddOnVersion: directive number from the manifest must be equal.
		Returns:
			nil, nil := These return values indicate that a global control entry for "addonName" already exists. AddonStub refuses
				to start up add-ons with AddOnVersion numbers that are older than (lesser values) or duplicates of (equal values)
				the AddOnVersion number in this copy of the add-on code (e.g. MINOR).
			addon, version := These return values indicate that AddonStub has successfully created or updated the control entry 
				for "addonName".
				addon := Contains a pointer to the global control entry for "addonName".
				version := Contains the AddOnVersion number in the control entry for "addonName".

Control Entry layout for:
	_G["addonName"] = {
		addOnVersion,                    	-- AddOnVersion from the code (e.g. MINOR)
		apiVersion,							-- Current API version number from the game
		index,								-- Ordinal position of this add-on in the AddOnManager's add-on table
		manifest = {
			-- These values are returned from API functions
			fileName,						-- The file/folder/manifest name
			filePath,						-- User Path to the add-on file/folder (new as of 100026)
			isEnabled,						-- ESO boolean value
			loadState,						-- ESO load state (i.e. loaded; not loaded)
			isOutOfDate,					-- ESO boolean value

			-- These values come from the manifest file	directives
			addOnVersion,					-- From the AddonVersion: directive (new as of 100026)
			rawAuthor,						-- From the Author: directive
			rawTitle,						-- From the Title: directive
			description,					-- From the Description: directive
			author,							-- "rawAuthor" sans any special characters
			title,							-- "rawTitle" sans any special characters

			-- Fields I wish were retrievable from the manifest file
			-- OODVersion = AM:GetAPIVersion( i ),		-- The API number from the manifest file
		},
	}

WARNING: This add-on is a standalone stub. Do NOT embed it within your add-on folder!
				
################################################################################################################################--]]

--[[--------------------------------------------------------------------------------------------------------------------------------
Local variables shared by multiple functions within this add-on.
----------------------------------------------------------------------------------------------------------------------------------]]
local AM = GetAddOnManager()
local oldversion
local strformat = string.format

--[[--------------------------------------------------------------------------------------------------------------------------------
Local functions needed to build a manifest information table from the manifest directives and other data retrieved via the ESO
"AddOnManager:GetAddOnInfo()" API function. AddonStub builds this table for every add-on it loads.
----------------------------------------------------------------------------------------------------------------------------------]]
-- Strip colorization strings from the input text 
local function Strip( text: string )
    return text:gsub( "|c%x%x%x%x%x%x", "" )
end

-- Find our add-on and build a manifest table for it
local function BuildManifestTable( addonName: string )
	local numAddOns = AM:GetNumAddOns()
	local i, search
	-- Iterate through the table entries 
    for i = 1, numAddOns do
        _, search = AM:GetAddOnInfo( i )
		if Strip( search ) == addonName then					-- We found a match!
			-- Load the table with addon manifest information
			local file, name, auth, desc, enabled, state, isOOD = AM:GetAddOnInfo( i )
			local manifestInfo = {
				fileName = file or "",					-- The add-on's folder and file name
				rawAuthor = auth or "",					-- Raw text including coloring, etc.
				rawTitle = name or "",					-- Raw text including coloring, etc.
				description = desc or "",				-- From the manifest file
				author = Strip( auth ) or "",			-- "rawAuthor" sans special characters
				title = Strip( name ) or "",			-- "rawTitle" sans special characters
				isEnabled = enabled,					-- ESO boolean value
				loadState = state,						-- ESO load state (i.e. loaded; not loaded)
				isOutOfDate = isOOD,					-- ESO boolean value

				-- New fields as of API 100026
				addOnVersion = AM:GetAddOnVersion( i ) or 0,	-- The value from the manifest file
				filePath = AM:GetAddOnRootDirectoryPath( i ),	-- Path to the add-on file

				-- Fields I wish were retrievable from the manifest file
				-- OODVersion = AM:GetAPIVersion( i ),					-- The API value from the manifest file...
			}
			-- An AddOnVersion: directive number must exist in the manifest
			oldversion = manifestInfo.addOnVersion
			if not oldversion or oldversion == 0 then
				error( strformat( "AddonStub:BuildManifestTable: AddOnVersion number is missing for %s!", addonName ), 2 )
			end
			
			return i, manifestInfo
		end
	end

	error( strformat( "AddonStub:BuildManifestTable: Could not find a matching AddOnManager entry for %s!", addonName ), 2 )
end

--[[--------------------------------------------------------------------------------------------------------------------------------
Bootstrap code to load or update AddonStub depending on whether its name and current version exist or not.
----------------------------------------------------------------------------------------------------------------------------------]]
-- Same MAJOR, MINOR parameters for AddonStub as for LibStub except MINOR must match the AddOnVersion: value in the manifest.
local MAJOR, MINOR = "AddonStub", 100

-- Either initialize or update AddonStub; everything else is a mistake!
local AddonStub = _G[MAJOR] or nil				-- Point to the latest AddonStub, if there is one.
if not AddonStub or AddonStub.addOnVersion < MINOR then
	AddonStub = {}
	AddonStub.apiVersion = GetAPIVersion()
	AddonStub.index, AddonStub.manifest = BuildManifestTable( MAJOR )
	-- The AddOnVersion: directive values in the code and manifest must match!
	oldversion = AddonStub.manifest.addOnVersion
	if oldversion ~= MINOR then
		error( strformat( "AddonStub:V%q: AddOnVersion numbers do not match (Manifest vs MINOR)!", tostring( oldversion ) ), 2 )
	end
	AddonStub.addOnVersion = MINOR
	_G[MAJOR] = AddonStub

-- Trap and fail any attempt to load AddonStub multiple times
else
	oldversion = AddonStub.addOnVersion or 0
	if oldversion == MINOR then
		error( strformat( "AddonStub:V%q: Is already loaded. Do NOT load AddonStub twice!", tostring( oldversion ) ), 2 )
	else
		error( strformat( "AddonStub:V%q: Will not load older versions of itself!", tostring( oldversion ) ), 2 )
	end
end

--[[----------------------------------------------------------------------------------------------------------------------------
Define the AddonStub API functions.
------------------------------------------------------------------------------------------------------------------------------]]
local addon

-- The Havok notation "addonName: string" causes the Havok VM to type check the "addonName" variable for string content.
function AddonStub:Get( addonName: string )
	addon = _G[addonName]							-- Point to the latest version of addonName, if there is one.
	-- Return existing control entry values
	if addon then
		return addon, addon.addOnVersion
	else
		return nil, nil
	end
end

-- The Havok notation "version: number" causes the Havok VM to type check the "version" variable for numeric content.
function AddonStub:New( addonName: string, version: number )
	addon = _G[addonName]							-- Point to the latest version of addonName, if there is one.
	-- Either create or reset and reload a control entry. Anything else is a mistake!
	if not addon or addon.addOnVersion < version then
		addon = {}
		addon.apiVersion = GetAPIVersion()
		addon.index, addon.manifest = BuildManifestTable( addonName )
		-- The AddOnVersion: directive values in the code and manifest must match!
		oldversion = AddonStub.manifest.addOnVersion
		if oldversion ~= version then
			error( strformat( "AddonStub:V%q: AddOnVersion numbers do not match (Manifest vs MINOR)!", tostring( oldversion ) ), 2 )
		end
		addon.addOnVersion = version
		_G[addonName] = addon

		return addon, version

	-- Reject all attempts to load older or duplicate versions of an add-on.
	else
		oldversion = addon.addOnVersion
		if oldversion == version then
			error( strformat( "AddonStub:New will not start up duplicate copies of the same add-on! %s V%q", addonName, 
								tostring( oldversion ) ), 2 )
		else
			error( strformat( "AddonStub:New will not start up older versions of the same add-on! %s V%q", addonName, 
								tostring( oldversion ) ), 2 )
		end
	end
end
