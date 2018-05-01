ProfileSwitcher_SavedVariables_DB = {};
local L = LibStub("AceLocale-3.0"):GetLocale("ProfileSwitcher");
local UpdateTable = {};

local Main_Frame = CreateFrame("Frame", "MainPanel", InterfaceOptionsFramePanelContainer);
local Option_Frame = CreateFrame("Frame", "OptionPanel", Main_Frame);
-- Main Frame

local defaultValues_DB = {
	SavedProfiles = {},
	ChatMessagesOn = true,
	RaidProfileSwitchInCombat = false,
	RaidProfileBlockInCombat = true
}

local changeableValues_DB = {
	DebugMode = false,
	DebugLevel = 4
	-- debugging, false = deactivated
	-- 1 Options
	-- 2 Events+Method Names
	-- 4 Methods content
	-- combinable, so 7 = everything
}

local internValues_DB = {
	SavedCounter = 0, -- Counter for profiles
	SavedProfiles = {}, -- intern array to check raid profile against
	ChangeOnwElement = "", -- used if changeOwnElemnt == true
	RaidProfileExistOnIndex = 0, -- intern variables for the ddms
	inCombat = false, -- triggered by PLAYER_REGEN
	ddmItems = {},
	AvailableSelectedProfile = nil,
	SavedSelectedProfile = nil
}

local Main_Title = Main_Frame:CreateFontString("MainTitle", "OVERLAY", "GameFontHighlight");
local Option_Title = Option_Frame:CreateFontString("OptionTitle", "OVERLAY", "GameFontHighlight");

local Main_Text_Version = CreateFrame("SimpleHTML", "MainTextVersion", Main_Frame);
local Main_Text_Author = CreateFrame("SimpleHTML", "MainTextAuthor", Main_Frame); 
local intern_version = "1.1";
local intern_versionOutput = "|cFF00FF00Version|r  " .. intern_version
local intern_author = "Collabo93"
local intern_authorOutput = "|cFF00FF00Author|r   " .. intern_author

local Main_Text_From = CreateFrame("SimpleHTML", "MainTextFrom", Main_Frame);
local Main_Text_To = CreateFrame("SimpleHTML", "MainTextTo", Main_Frame);
local Main_Text_Available = CreateFrame("SimpleHTML", "MainTextAvailable", Main_Frame);
local Main_Text_Saved = CreateFrame("SimpleHTML", "MainTextSaved", Main_Frame);
local Option_Text_General = CreateFrame("SimpleHTML", "OptionTextGeneral", Option_Frame);
local Option_Text_Combat = CreateFrame("SimpleHTML", "OptionTextCombat", Option_Frame);
-- Text

local Option_cb_ChatMessagesOn = CreateFrame("CheckButton", "MainCbChatMessagesOn", Option_Text_General, "UICheckButtonTemplate");
local Option_cb_RaidProfilesSwitchInCombat = CreateFrame("CheckButton", "CheckButtonRaidProfilesSwitchInCombat", Option_Text_Combat, "UICheckButtonTemplate");
local Option_cb_RaidProfilesUpdateInCombat = CreateFrame("CheckButton", "CheckButtonRaidProfilesUpdateInCombat", Option_Text_Combat, "UICheckButtonTemplate");
-- Combo-box Options

local Main_btn_Save = CreateFrame("Button", "MainBtnSave", Main_Frame, "UIPanelButtonTemplate");
local Main_btn_Delete = CreateFrame("Button", "MainBtnDelete", Main_Frame, "UIPanelButtonTemplate");
local Main_btn_Reset = CreateFrame("Button", "MainBtnReset", Main_Frame, "UIPanelButtonTemplate");
local Main_btn_Reload = CreateFrame("Button", "MainBtnReload", Option_Frame, "UIPanelButtonTemplate");
-- Button

local Main_ddm_Available = CreateFrame("Button", "MainDdmAvailable", Main_Frame, "UIDropDownMenuTemplate");
local Main_ddm_Saved = CreateFrame("Button", "MainDdmSaved", Main_Frame, "UIDropDownMenuTemplate");
-- DropDownMenu

local Main_slider_Minimum = CreateFrame("Slider", "MainSliderMinimum", Main_Frame, "OptionsSliderTemplate");
local Main_slider_Maximum = CreateFrame("Slider", "MainSliderMaximum", Main_Frame, "OptionsSliderTemplate");
-- Sliders
---End Variables

local function ColorText(text, operation)
	local defaultColor = "#FFFFFF";
	if ( operation == "option" ) then
		cacheText = text:gsub("ProfileSwitcher:" , function(cap)
			cap = cap:sub(1, -1);
			local color = "|cff00FF7F" or defaultColor;
			return color..cap.."|r";
		end)
		return cacheText;
	elseif ( operation == "disable" ) then
		local color = "|cff888888" or defaultColor;
		return color..text;
	elseif ( operation == "green" ) then
		local color = "|cff00ff00" or defaultColor;
		return color..text;
	elseif ( operation == "red" ) then
		local color = "|cffff0000" or defaultColor;
		return color..text;
	elseif ( operation == "white" ) then
		local color = "|cffffffff" or defaultColor;
		return color..text;
	end
end
-- Color everything expcept sliders

local function Debug(methodName, methodContent, methodLevel)
	if ( changeableValues_DB.DebugMode == true ) then
		local DebugNameCache = nil;
		local DebugMethodContentCache = nil;
		local debugMethodNamePrint = true;
		local debugLevelCache = changeableValues_DB.DebugLevel;
		if ( debugLevelCache % 2 == 1 and methodLevel >= 1 ) then
			debugLevelCache = debugLevelCache - 1;
			if ( methodLevel == 1 ) then
				debugMethodNamePrint = true;
				print(ColorText("ProfileSwitcher: Debuging - Options", "option"));
				print("'defaultValues_DB.ChatMessagesOn' " .. tostring(defaultValues_DB.ChatMessagesOn));
				print("'defaultValues_DB.RaidProfileSwitchInCombat' " .. tostring(defaultValues_DB.RaidProfileSwitchInCombat));
				print("'defaultValues_DB.RaidProfileBlockInCombat' " .. tostring(defaultValues_DB.RaidProfileBlockInCombat));		
				local intern_CacheCountTable = #defaultValues_DB.SavedProfiles;
				if ( intern_CacheCountTable > 0 ) then
					for i = 1, intern_CacheCountTable, 1 do
						print("'ProfileSwitcher_Option_Variable_SavedProfiles' " .. internValues_DB.SavedProfiles[i][1]);
					end
				end
			end
		end
		if ( ( debugLevelCache == 2 or debugLevelCache == 6 ) and methodLevel >= 2 ) then
			if ( DebugNameCache ~= methodName ) then
				if ( debugMethodNamePrint == true ) then
					print(ColorText("ProfileSwitcher: Debuging - Method Names", "option"));
					debugMethodNamePrint = false;
				end
				print("'" ..  methodName .. "()'");
				DebugNameCache = methodName;
			end
		end
		if ( debugLevelCache >= 4 and methodLevel == 3 ) then
			debugMethodNamePrint = true;
			if ( DebugMethodContentCache ~= methodName ) then
				print(ColorText("ProfileSwitcher: Debuging - Method content", "option"));	
			end
			DebugMethodContentCache = methodName;
			print( "'" .. methodName .. "()' " .. tostring(methodContent));
		end		
	end
end

local function CountTable(t)
	Debug("CountTable", "", 2);
	local count = 0
	for _ in pairs(t) do 
		count = count + 1 
	end
	return count;
end

local function ProfileExists(RaidProfiles)
	Debug("ProfileExists", "", 2);
	local raidprofilexists = false;
	internValues_DB.ddmItems = nil;
	internValues_DB.ddmItems = {};
	for i=1, GetNumRaidProfiles(), 1 do
		internValues_DB.ddmItems[i] = GetRaidProfileName(i);
		if ( internValues_DB.ddmItems[i] == RaidProfiles ) then
			raidprofilexists = true;		
		end
	end
	if ( raidprofilexists == true ) then
		Debug("ProfileExists", RaidProfiles .. " exists", 3);
	else
		Debug("ProfileExists", "doesn't exists", 3);
	end
	return raidprofilexists;
end
--Fills internValues_DB.ddmItems with raidprofiles and checks if raidprofil exists

local function UpdateComboBoxes()
	Debug("UpdateComboBoxes", "", 2);
	
	if ( defaultValues_DB.ChatMessagesOn == true ) then
		Option_cb_ChatMessagesOn:SetChecked(true);
		Debug("UpdateComboBoxes", "ChatMessagesOn - checked", 3);
	else 
		Option_cb_ChatMessagesOn:SetChecked(false);
		Debug("UpdateComboBoxes", "ChatMessagesOn - unchecked", 3);
	end
	
	if ( defaultValues_DB.RaidProfileSwitchInCombat == true ) then
		Option_cb_RaidProfilesSwitchInCombat:SetChecked(true);
		Debug("UpdateComboBoxes", "RaidProfileSwitchInCombat - checked", 3);
	else
		Option_cb_RaidProfilesSwitchInCombat:SetChecked(false);
		Debug("UpdateComboBoxes", "RaidProfileSwitchInCombat - unchecked", 3);
	end
	
	if ( defaultValues_DB.RaidProfileBlockInCombat == true ) then
		Option_cb_RaidProfilesUpdateInCombat:SetChecked(true);
		Debug("UpdateComboBoxes", "RaidProfileBlockInCombat - checked", 3);
	else
		Option_cb_RaidProfilesUpdateInCombat:SetChecked(false);
		Debug("UpdateComboBoxes", "RaidProfileBlockInCombat - unchecked", 3);
	end
end
-- Updating all displayed elements

local function DisableSliders(Minimum, Maximum)
	Debug("DisableSliders", "", 2);
	Main_slider_Minimum:Disable();
	Main_slider_Maximum:Disable();
	Main_btn_Save:Disable();
	Main_btn_Delete:Disable();
	if ( CountTable(defaultValues_DB.SavedProfiles) == 0 ) then
		MainBtnReset:Disable();
	end
	
	getglobal(Main_slider_Minimum:GetName() .. 'Low'):SetText(ColorText(Minimum, "disable"));
	getglobal(Main_slider_Minimum:GetName() .. 'High'):SetText(ColorText(Maximum, "disable"));
	getglobal(Main_slider_Maximum:GetName() .. 'Low'):SetText(ColorText(Minimum, "disable"));
	getglobal(Main_slider_Maximum:GetName() .. 'High'):SetText(ColorText(Maximum, "disable"));
	getglobal(Main_slider_Minimum:GetName() .. 'Text'):SetText(ColorText(math.floor(Main_slider_Minimum:GetValue()), "disable"));
	getglobal(Main_slider_Maximum:GetName() .. 'Text'):SetText(ColorText(math.floor(Main_slider_Maximum:GetValue()), "disable"));	
end

local function EnableSliders(Minimum, Maximum)
	Main_slider_Minimum:Enable();
	Main_slider_Maximum:Enable();

	Main_slider_Minimum:SetMinMaxValues(Minimum, Maximum);
	Main_slider_Maximum:SetMinMaxValues(Minimum, Maximum);
	
	getglobal(Main_slider_Minimum:GetName() .. 'Low'):SetText(ColorText(Minimum, "white"));
	getglobal(Main_slider_Minimum:GetName() .. 'High'):SetText(ColorText(Maximum, "white"));
	getglobal(Main_slider_Maximum:GetName() .. 'Low'):SetText(ColorText(Minimum, "white"));
	getglobal(Main_slider_Maximum:GetName() .. 'High'):SetText(ColorText(Maximum, "white"));
	getglobal(Main_slider_Minimum:GetName() .. 'Text'):SetText(ColorText(math.floor(Main_slider_Minimum:GetValue()), "white"));
	getglobal(Main_slider_Maximum:GetName() .. 'Text'):SetText(ColorText(math.floor(Main_slider_Maximum:GetValue()), "white"));
end

local function MinMaxInArray(MinMax)
	Debug("MinMaxInArray", "", 2);
	if ( internValues_DB.SavedProfiles[MinMax] ~= nil ) then
		if ( internValues_DB.SavedProfiles[MinMax][0] == true ) then
			Debug("MinMaxInArray", true, 3);
			return true;
		else
			Debug("MinMaxInArray", false, 3);
			return false;
		end
	end
end
--Minimum Maximum check, true if exists

local function ElementIsInArray(Minimum, Maximum)
	Debug("ElementIsInArray","", 2)
	for i = (tonumber(Minimum)), (tonumber(Maximum)), 1 do
		if ( internValues_DB.SavedProfiles[i] ~= nil ) then	
			if ( internValues_DB.SavedProfiles[i][0] == true ) then
				Debug("ElementIsInArray", ("Index " .. i .. " internValues_DB.SavedProfiles[i][1]"));
				return internValues_DB.SavedProfiles[i][1];
			end
		else
			Debug("ElementIsInArray",nil, 3)
		end
	end
	return nil;
end
-- Check if no Raid Profiles are in a specific Group Size

local function ElementChangeOwnElement(Minimum, Maximum, raidProfilOnLoad)
	Debug("ElementChangeOwnElement", "", 2)
	local OwnElement = true;
	for i = (tonumber(Minimum)), (tonumber(Maximum)), 1 do
		if ( internValues_DB.SavedProfiles[i] ~= nil ) then
			if ( internValues_DB.SavedProfiles[i][0] == true ) then
				if ( internValues_DB.SavedProfiles[i][1] ~= raidProfilOnLoad ) then
					internValues_DB.ChangeOnwElement = internValues_DB.SavedProfiles[i][1];
					OwnElement = false;
				end
			end
		else
			OwnElement = nil;
		end
	end
	Debug("ElementChangeOwnElement", OwnElement, 3)
	return OwnElement;
end
-- true if Raid Profile gets resized in own area

local function UpdateSliders(option, index)
	Debug("UpdateSliders", "", 2);
	local intern_CacheColorSliders = nil
	if ( internValues_DB.SavedSelectedProfile ~= nil ) then
		intern_CacheColorSliders = internValues_DB.SavedSelectedProfile;
	else
		intern_CacheColorSliders = internValues_DB.AvailableSelectedProfile;
	end
	if ( option == "Minimum" ) then
		if ( ( math.floor(Main_slider_Minimum:GetValue()) ) <= ( math.floor(Main_slider_Maximum:GetValue()) ) ) then
			Debug("UpdateSliders", "Minimum <= Maximum", 3);
			if ( MinMaxInArray(math.floor(Main_slider_Minimum:GetValue())) == false ) then
				getglobal(Main_slider_Minimum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Minimum:GetValue())), "green" ));
			elseif ( ElementChangeOwnElement( (math.floor(Main_slider_Minimum:GetValue())), (math.floor(Main_slider_Maximum:GetValue())), intern_CacheColorSliders ) == true ) then
				getglobal(Main_slider_Minimum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Minimum:GetValue())), "green" ));
			else
				getglobal(Main_slider_Minimum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Minimum:GetValue())), "red" ));
			end
		else
			Debug("UpdateSliders", "Minimum > Maximum", 3);
			Main_slider_Minimum:SetValue(math.floor(Main_slider_Maximum:GetValue()));
			if ( MinMaxInArray(math.floor(Main_slider_Minimum:GetValue())) == false ) then
				getglobal(Main_slider_Minimum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Minimum:GetValue())  ), "green" ));
			elseif ( ElementChangeOwnElement( (math.floor(Main_slider_Minimum:GetValue())), (math.floor(Main_slider_Maximum:GetValue())), intern_CacheColorSliders ) == true ) then				
				getglobal(Main_slider_Minimum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Minimum:GetValue()) ), "green" ));
			else
				getglobal(Main_slider_Minimum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Minimum:GetValue())  ), "red" ));
			end
		end
	elseif ( option == "Maximum" ) then
		if ( ( math.floor(Main_slider_Maximum:GetValue()) ) >= ( math.floor(Main_slider_Minimum:GetValue()) ) ) then
			Debug("UpdateSliders", "Minimum <= Maximum", 3);
			if ( MinMaxInArray(math.floor(Main_slider_Maximum:GetValue())) == false ) then
				getglobal(Main_slider_Maximum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Maximum:GetValue())), "green" ));
			elseif ( ElementChangeOwnElement( (math.floor(Main_slider_Maximum:GetValue())), (math.floor(Main_slider_Maximum:GetValue())), intern_CacheColorSliders ) == true ) then
				getglobal(Main_slider_Maximum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Maximum:GetValue())), "green" ));
			else
				getglobal(Main_slider_Maximum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Maximum:GetValue())), "red" ));
			end
		else
			Debug("UpdateSliders", "Minimum > Maximum", 3);
			Main_slider_Maximum:SetValue(math.floor(Main_slider_Minimum:GetValue()));
			if ( MinMaxInArray(math.floor(Main_slider_Maximum:GetValue())) == false ) then
				getglobal(Main_slider_Maximum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Maximum:GetValue()) ), "green" ));
			elseif ( ElementChangeOwnElement( (math.floor(Main_slider_Minimum:GetValue())), (math.floor(Main_slider_Maximum:GetValue())), intern_CacheColorSliders ) == true ) then
				getglobal(Main_slider_Maximum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Maximum:GetValue()) ), "green" ));
			else
				getglobal(Main_slider_Maximum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Maximum:GetValue()) ), "red" ));
			end
		end
	elseif ( option == "ddmProfiles" ) then
		if ( MinMaxInArray(math.floor(Main_slider_Minimum:GetValue())) == false ) then	
			getglobal(Main_slider_Minimum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Minimum:GetValue())), "green" ));
		else
			getglobal(Main_slider_Minimum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Minimum:GetValue())), "red" ));
		end
		if ( MinMaxInArray(math.floor(Main_slider_Maximum:GetValue())) == false ) then
			getglobal(Main_slider_Maximum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Maximum:GetValue())), "green" ));
		else
			getglobal(Main_slider_Maximum:GetName() .. 'Text'):SetText( ColorText((math.floor(Main_slider_Maximum:GetValue())), "red" ));
		end
	elseif ( option == "ddmSelectedProfiles" ) then
		local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo("SortGroup");
		local exists, result = pcall(SortGroup_Method_GetAutoActivate);
		if ( enabled == true and exists == true ) then
			if ( SortGroup_Method_GetAutoActivate() == true and defaultValues_DB.SavedProfiles[index].Minimum < 6 ) then
				defaultValues_DB.SavedProfiles[index].Minimum = 6;
			end
		end
		MainSliderMinimum:SetValue( defaultValues_DB.SavedProfiles[index].Minimum );
		MainSliderMaximum:SetValue( defaultValues_DB.SavedProfiles[index].Maximum );
		getglobal(Main_slider_Minimum:GetName() .. 'Text'):SetText( ColorText(defaultValues_DB.SavedProfiles[index].Minimum, "green" ));
		getglobal(Main_slider_Maximum:GetName() .. 'Text'):SetText( ColorText(defaultValues_DB.SavedProfiles[index].Maximum, "green" ));
	end
end
-- Method to only color sliders

local function RaidProfilOnLoadExists(raidProfilOnLoad)
	Debug("RaidProfilOnLoadExists", "", 2);
	local intern_CacheCountTable = CountTable(defaultValues_DB.SavedProfiles);
	if ( intern_CacheCountTable > 0 ) then
		for i = 1, intern_CacheCountTable, 1 do
			if ( defaultValues_DB.SavedProfiles[i] ~= nil ) then
				if ( defaultValues_DB.SavedProfiles[i].RaidProfileName == raidProfilOnLoad ) then
					internValues_DB.RaidProfileExistOnIndex = i;
					Debug("RaidProfilOnLoadExists", i .. " exists", 3);
					return true;
				else	
					Debug("RaidProfilOnLoadExists", i .. " doesn't exist", 3);
				end
			end
		end
	end
	return false;
end
--  Checks if RaidProfil is in List

local function SaveOptions()
	Debug("SaveOptions", "", 2);
	ProfileSwitcher_SavedVariables_DB = defaultValues_DB;
end

local function fillArray()
	Debug("fillArray", "", 2);
	local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo("SortGroup");
	local exists, result = pcall(SortGroup_Method_GetAutoActivate);
	for i = 1, 40, 1 do
		internValues_DB.SavedProfiles[i] = {};
		if ( enabled == true and exists == true ) then
			if ( SortGroup_Method_GetAutoActivate() == true and i <= 5 ) then
				internValues_DB.SavedProfiles[i][0] = true;
				internValues_DB.SavedProfiles[i][1] = SortGroup_Method_GetProfile();
				--Debug("fillArray", ("Index " .. i .. " true - Profile: "..internValues_DB.SavedProfiles[i][1]), 3);
			else
				internValues_DB.SavedProfiles[i][0] = false;
				internValues_DB.SavedProfiles[i][1] = "";
				--Debug("fillArray", ("Index " .. i .. " false - Profile: empty"), 3);
			end
		else
			internValues_DB.SavedProfiles[i][0] = false;
			internValues_DB.SavedProfiles[i][1] = "";
			--Debug("fillArray", ("Index " .. i .. " false - Profile: empty"), 3);
		end
	end
	local intern_CacheCountTable = CountTable(defaultValues_DB.SavedProfiles);
	if ( intern_CacheCountTable > 0 ) then
		for i = 1, intern_CacheCountTable, 1 do
			for c = (tonumber(defaultValues_DB.SavedProfiles[i].Minimum)), (tonumber(defaultValues_DB.SavedProfiles[i].Maximum)), 1 do
				if ( c > 5 or enabled == false or ( enabled == true and SortGroup_Method_GetAutoActivate() == false ) ) then
					if ( internValues_DB.SavedProfiles[c] ~= nil ) then
						internValues_DB.SavedProfiles[c][0] = true;
						internValues_DB.SavedProfiles[c][1] = defaultValues_DB.SavedProfiles[i].RaidProfileName;
					elseif ( internValues_DB.SavedProfiles[c] == nil ) then
						Debug("fillArray", nil, 3);
					end
					if ( internValues_DB.SavedProfiles[c][0] == true ) then
						Debug("fillArray", ("Index " .. c .. " true - Profile: "..internValues_DB.SavedProfiles[c][1]), 3);
					end
				end
			end
		end
	end
	--SaveOptions();
end
-- Update Array with updated RaidProfil List

local function DeleteNotExistingProfiles()
	Debug("DeleteNotExistingProfiles", "", 2);
	local intern_CacheCountTable = CountTable(defaultValues_DB.SavedProfiles);
	if ( intern_CacheCountTable > 0 ) then
		for i = 1, intern_CacheCountTable, 1 do
			if ( defaultValues_DB.SavedProfiles[i] ~= nil ) then
				if ( ProfileExists(defaultValues_DB.SavedProfiles[i].RaidProfileName) == false ) then
					if ( defaultValues_DB.ChatMessagesOn == true ) then
						print( ColorText(L["ProfileSwitcher_Deleted_RaidProfile_doesnt_Exist_Output"]:gsub("'replacement'", (defaultValues_DB.SavedProfiles[i].RaidProfileName)), "option") );
					end
					Debug("DeleteNotExistingProfiles", (defaultValues_DB.SavedProfiles[i].RaidProfileName .. " deleted"), 3 );
					table.remove(defaultValues_DB.SavedProfiles, i);	
					DisableSliders("1", "40");
					UIDropDownMenu_SetText(Main_ddm_Available, "");
					UIDropDownMenu_SetText(Main_ddm_Saved, "");	
				end
			end
		end
	end
	fillArray();
end
-- not existing RaidProfiles get deleted from list

local function ExecuteSwitchRaidProfiles(profile)
	Debug("ExecuteSwitchRaidProfiles", "", 2);
	Debug("ExecuteSwitchRaidProfiles", "to profile: " .. profile, 3);
	CompactUnitFrameProfiles.selectedProfile = profile;
	SaveRaidProfileCopy(profile);
	SetCVar("activeCUFProfile", profile);
	UIDropDownMenu_SetSelectedValue(CompactUnitFrameProfilesProfileSelector, profile);
	UIDropDownMenu_SetText(CompactUnitFrameProfilesProfileSelector, profile);	
	UIDropDownMenu_SetSelectedValue(CompactRaidFrameManagerDisplayFrameProfileSelector, profile);
	UIDropDownMenu_SetText(CompactRaidFrameManagerDisplayFrameProfileSelector, profile);		
	CompactUnitFrameProfiles_ApplyCurrentSettings();
	--CompactUnitFrameProfiles_UpdateCurrentPanel();
	CompactUnitFrameProfiles_HidePopups();
	
	--CompactUnitFrameProfiles_ActivateRaidProfile(profile);
	-- seems to taint the blizzard ddms
	--CompactUnitFrameProfiles_ActivateRaidProfile(profile);
end

local function SwitchRaidProfiles()
	Debug("SwitchRaidProfiles", "", 2);
	if ( internValues_DB.inCombat == false or defaultValues_DB.RaidProfileSwitchInCombat == true ) then
		DeleteNotExistingProfiles();
		local intern_CacheMember = tonumber(GetNumGroupMembers());
		if ( intern_CacheMember == 0 ) then
			intern_CacheMember = 1;
		end
		if ( HasLoadedCUFProfiles() == true ) then
			if ( internValues_DB.SavedProfiles[intern_CacheMember][0] == true and internValues_DB.SavedProfiles[intern_CacheMember][1] ~= nil ) then
				if ( GetActiveRaidProfile() ~= internValues_DB.SavedProfiles[intern_CacheMember][1] ) then	
					ExecuteSwitchRaidProfiles(internValues_DB.SavedProfiles[intern_CacheMember][1]);
					if ( defaultValues_DB.ChatMessagesOn == true ) then
						print( ColorText(L["ProfileSwitcher_RaidProfil_changed_Output"]:gsub("'replacement'", (internValues_DB.SavedProfiles[intern_CacheMember][1])), "option") );
					end
					Debug("SwitchRaidProfiles", "true", 3);
				end	
			end
		end
	end
end
-- Possible switch by Group_Roster, OK button, COMPACT_UNIT_FRAME_PROFILES_LOADED, PLAYER_REGEN_ENABLED, cbAutoActivate or ddmProfiles
-- Cancel Button caused taint 


local function resetRaidContainer()	
	Debug("resetRaidContainer", "", 2);
	if ( defaultValues_DB.RaidProfileBlockInCombat == true ) then	
		Debug("resetRaidContainer", "active", 3);		
		local old_CompactRaidFrameContainer_TryUpdate = CompactRaidFrameContainer_TryUpdate
		CompactRaidFrameContainer_TryUpdate = function(self)	
			if ( internValues_DB.inCombat == true ) then
				UpdateTable[self:GetName()] = "CompactRaidFrameContainer_TryUpdate"
			else
				old_CompactRaidFrameContainer_TryUpdate(self)
			end
		end
		
		local old_CompactRaidGroup_UpdateUnits = CompactRaidGroup_UpdateUnits
		CompactRaidGroup_UpdateUnits = function(self)
			if ( internValues_DB.inCombat == true ) then
				UpdateTable[self:GetName()] = "CompactRaidGroup_UpdateUnits"
			else
				old_CompactRaidGroup_UpdateUnits(self)
			end
		end
	end
end
---Functions end

local function frameEvent()
	Debug("frameEvent", "", 2);
	Main_Frame:RegisterEvent("COMPACT_UNIT_FRAME_PROFILES_LOADED");
	Main_Frame:RegisterEvent("PLAYER_ENTERING_WORLD");
	Main_Frame:RegisterEvent("PLAYER_LOGOUT");
	Main_Frame:RegisterEvent("PLAYER_REGEN_DISABLED");
	Main_Frame:RegisterEvent("PLAYER_REGEN_ENABLED");
	Main_Frame:RegisterEvent("GROUP_ROSTER_UPDATE");
	Main_Frame:SetScript("OnEvent", 
		function(self, event, ...)	
			if ( event == "PLAYER_LOGOUT" ) then 
				Debug("PLAYER_LOGOUT", "", 2);			
				SaveOptions();
				Main_Frame:UnregisterEvent(event);
			elseif ( event == "PLAYER_REGEN_DISABLED" ) then
				Debug("PLAYER_REGEN_DISABLED", "", 2);			
				internValues_DB.inCombat = true;
			elseif ( event == "PLAYER_REGEN_ENABLED" ) then
				Debug("PLAYER_REGEN_ENABLED", "", 2);
				internValues_DB.inCombat = false;
				
				for k, v in pairs(UpdateTable) do
					UpdateTable[k] = nil
					_G[v](_G[k])
				end
				
				SwitchRaidProfiles();
			elseif ( event == "GROUP_ROSTER_UPDATE" ) then
				Debug("GROUP_ROSTER_UPDATE", "", 2);
				SwitchRaidProfiles();
			elseif ( event == "COMPACT_UNIT_FRAME_PROFILES_LOADED" ) then
				Debug("COMPACT_UNIT_FRAME_PROFILES_LOADED", "", 2)
				if ( CountTable(ProfileSwitcher_SavedVariables_DB) == 0 ) then
					ProfileSwitcher_SavedVariables_DB = nil;
					ProfileSwitcher_SavedVariables_DB = defaultValues_DB;
					Debug("COMPACT_UNIT_FRAME_PROFILES_LOADED", "new db", 3)
				end
				
				if ( ProfileSwitcher_SavedVariables_DB.SavedProfiles == nil ) then
					ProfileSwitcher_SavedVariables_DB.SavedProfiles = {};
				end
				
				defaultValues_DB.SavedProfiles = ProfileSwitcher_SavedVariables_DB.SavedProfiles;
				defaultValues_DB.ChatMessagesOn = ProfileSwitcher_SavedVariables_DB.ChatMessagesOn;
				defaultValues_DB.RaidProfileSwitchInCombat = ProfileSwitcher_SavedVariables_DB.RaidProfileSwitchInCombat;
				defaultValues_DB.RaidProfileBlockInCombat = ProfileSwitcher_SavedVariables_DB.RaidProfileBlockInCombat;
				
				DeleteNotExistingProfiles();
				fillArray();
				SwitchRaidProfiles();
				
				
				UpdateComboBoxes();
				DisableSliders("1", "40");
				
				resetRaidContainer();
				
				Main_Frame:UnregisterEvent(event);	
			elseif ( event == "PLAYER_ENTERING_WORLD" and HasLoadedCUFProfiles() == true and internValues_DB.inCombat == false) then	
				Debug("PLAYER_ENTERING_WORLD", "", 2);		
				SwitchRaidProfiles();
			end
		end);
end

local function checkBoxEvent()
	Debug("checkBoxEvent", "", 2);

	Option_cb_ChatMessagesOn:SetScript("OnClick",
		function()
			Debug("Option_cb_ChatMessagesOn", "", 2);
			if ( internValues_DB.inCombat == false ) then
				if ( Option_cb_ChatMessagesOn:GetChecked() == true ) then
					defaultValues_DB.ChatMessagesOn = true;
					print(ColorText(L["ProfileSwitcher_chat_Messages_On_Output"], "option"));
				elseif ( Option_cb_ChatMessagesOn:GetChecked() == false ) then
					defaultValues_DB.ChatMessagesOn = false;
				end
				SaveOptions();
				Debug("checkBoxEvent", "", 1);
			else
				if ( defaultValues_DB.ChatMessagesOn == true ) then
					print(ColorText(L["ProfileSwitcher_in_combat_options_Output"], "option"));
				end
			end
			UpdateComboBoxes();
		end);
	Option_cb_ChatMessagesOn:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:AddLine(L["ProfileSwitcher_Option_cb_ChatMessagesOn_Text"] .."\n\n" .. ColorText(L["ProfileSwitcher_Option_cb_ChatMessagesOn_ToolTip"], "white") , nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Option_cb_ChatMessagesOn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	--Combobox defaultValues_DB.ChatMessagesOn

	
	Option_cb_RaidProfilesSwitchInCombat:SetScript("OnClick",
		function()
			Debug("Option_cb_RaidProfilesSwitchInCombat", "", 2);
			if ( internValues_DB.inCombat == false ) then
				if ( Option_cb_RaidProfilesSwitchInCombat:GetChecked() == true ) then
					defaultValues_DB.RaidProfileSwitchInCombat = true;
				elseif ( Option_cb_RaidProfilesSwitchInCombat:GetChecked() == false ) then
					defaultValues_DB.RaidProfileSwitchInCombat = false;
				end
				SaveOptions();
				Debug("Option_cb_RaidProfilesSwitchInCombat", "", 1);
			else
				
				if ( defaultValues_DB.ChatMessagesOn == true  ) then
					print(ColorText(L["ProfileSwitcher_in_combat_options_Output"], "option"));
				end
			end
			UpdateComboBoxes();
		end);
	Option_cb_RaidProfilesSwitchInCombat:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:AddLine(L["ProfileSwitcher_Option_cb_RaidProfilesSwitchInCombat_Text"] .."\n\n" .. ColorText(L["ProfileSwitcher_Option_cb_RaidProfilesSwitchInCombat_ToolTip"], "white") , nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Option_cb_RaidProfilesSwitchInCombat:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	--Combobox defaultValues_DB.RaidProfileSwitchInCombat
	
	Option_cb_RaidProfilesUpdateInCombat:SetScript("OnClick",
		function()
			Debug("Option_cb_RaidProfilesUpdateInCombat", "", 2);
			if ( internValues_DB.inCombat == false ) then
				if ( Option_cb_RaidProfilesUpdateInCombat:GetChecked() == true ) then
					defaultValues_DB.RaidProfileBlockInCombat = true;
				elseif ( Option_cb_RaidProfilesUpdateInCombat:GetChecked() == false ) then
					defaultValues_DB.RaidProfileBlockInCombat = false;
				end
				resetRaidContainer();
				SaveOptions();
				Debug("Option_cb_RaidProfilesUpdateInCombat", "", 1);
			else
				if ( defaultValues_DB.ChatMessagesOn == true  ) then
					print(ColorText(L["ProfileSwitcher_in_combat_options_Output"], "option"));
				end
			end
			UpdateComboBoxes();
		end);
	Option_cb_RaidProfilesUpdateInCombat:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:AddLine(L["ProfileSwitcher_Option_cb_RaidProfilesUpdateInCombat_Text"] .."\n\n" .. ColorText(L["ProfileSwitcher_Option_cb_RaidProfilesUpdateInCombat_ToolTip"], "white") , nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Option_cb_RaidProfilesUpdateInCombat:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	--Combobox defaultValues_DB.Option_cb_RaidProfilesUpdateInCombat
end
--ComboBox Events

local function buttonEvent()
	Debug("buttonEvent", "", 2);
	Main_btn_Save:SetScript("OnClick",
		function()
			Debug("Main_btn_Save", "", 2);
			if ( math.floor(Main_slider_Minimum:GetValue()) <= math.floor(Main_slider_Maximum:GetValue()) ) then
				if ( internValues_DB.AvailableSelectedProfile ~= nil and internValues_DB.AvailableSelectedProfile ~= "" ) then
					if ( RaidProfilOnLoadExists(internValues_DB.AvailableSelectedProfile) == false ) then
						if ( ElementIsInArray( (math.floor(Main_slider_Minimum:GetValue())), (math.floor(Main_slider_Maximum:GetValue())) ) == nil ) then
							local number = CountTable(defaultValues_DB.SavedProfiles) + 1;
							defaultValues_DB.SavedProfiles[number] = {}
							defaultValues_DB.SavedProfiles[number].RaidProfileName = internValues_DB.AvailableSelectedProfile;
							defaultValues_DB.SavedProfiles[number].Minimum = math.floor(Main_slider_Minimum:GetValue());
							defaultValues_DB.SavedProfiles[number].Maximum =  math.floor(Main_slider_Maximum:GetValue());
							fillArray();
							SaveOptions();
							if ( defaultValues_DB.ChatMessagesOn == true ) then
								local intern_CachePrint1 = L["ProfileSwitcher_RaidProfile_Saved_Output"]:gsub("'replacement'", internValues_DB.AvailableSelectedProfile):gsub("'replacement2'", math.floor(Main_slider_Minimum:GetValue()));
								print( ColorText(intern_CachePrint1:gsub("'replacement3'", math.floor(Main_slider_Maximum:GetValue())), "option") );
							end
							UIDropDownMenu_SetText(Main_ddm_Available, "");
							UIDropDownMenu_SetText(Main_ddm_Saved, "");	
							DisableSliders("1", "40");
						elseif ( defaultValues_DB.ChatMessagesOn == true ) then
							local intern_CachePrint2 =  ElementIsInArray( (math.floor(Main_slider_Minimum:GetValue())), (math.floor(Main_slider_Maximum:GetValue())) );
							print( ColorText(L["ProfileSwitcher_already_in_use_Output"]:gsub("'replacement'", intern_CachePrint2), "option") );
						end
					elseif ( defaultValues_DB.ChatMessagesOn == true ) then
						local intern_CachePrint3 =  ElementIsInArray( (math.floor(Main_slider_Minimum:GetValue())), (math.floor(Main_slider_Maximum:GetValue())) );
						print( ColorText(L["ProfileSwitcher_already_in_use_Output"]:gsub("'replacement'", intern_CachePrint3), "option") );
					end
				elseif ( internValues_DB.SavedSelectedProfile ~= nil and internValues_DB.SavedSelectedProfile ~= "" ) then
					RaidProfilOnLoadExists(internValues_DB.SavedSelectedProfile);
					if ( ElementChangeOwnElement( (math.floor(Main_slider_Minimum:GetValue())), (math.floor(Main_slider_Maximum:GetValue())), internValues_DB.SavedSelectedProfile ) == true ) then					
						defaultValues_DB.SavedProfiles[internValues_DB.RaidProfileExistOnIndex].RaidProfileName = internValues_DB.SavedSelectedProfile;
						defaultValues_DB.SavedProfiles[internValues_DB.RaidProfileExistOnIndex].Minimum = math.floor(Main_slider_Minimum:GetValue());
						defaultValues_DB.SavedProfiles[internValues_DB.RaidProfileExistOnIndex].Maximum =  math.floor(Main_slider_Maximum:GetValue());
						fillArray();
						SaveOptions();
						if ( defaultValues_DB.ChatMessagesOn == true ) then
							local cache4PrintPage2_AdditionalSwitchbtnSave = L["ProfileSwitcher_RaidProfile_Saved_Output"]:gsub("'replacement'", internValues_DB.SavedSelectedProfile):gsub("'replacement2'", math.floor(Main_slider_Minimum:GetValue()));
							print( ColorText(cache4PrintPage2_AdditionalSwitchbtnSave:gsub("'replacement3'", math.floor(Main_slider_Maximum:GetValue())), "option") );
						end
						UIDropDownMenu_SetText(Main_ddm_Available, "");
						Main_btn_Save:Disable();
					elseif ( defaultValues_DB.ChatMessagesOn == true ) then
						print( ColorText(L["ProfileSwitcher_already_in_use_Output"]:gsub("'replacement'", internValues_DB.ChangeOnwElement), "option") );
					end
				end
				if ( CountTable(defaultValues_DB.SavedProfiles) > 0 ) then
					Main_btn_Reset:Enable();
				else
					Main_btn_Reset:Disable();
				end
				SwitchRaidProfiles();
			elseif ( SortGroup_Variable_Page3_ChatMessagesWarnings == true ) then
				print( ColorText(L["ProfileSwitcher_RaidProfil_Save_Error_Output"]) );
			end
		end);
	
	Main_btn_Delete:SetScript("OnClick",
		function()
			Debug("Main_btn_Delete", "", 2);
			if ( internValues_DB.RaidProfileExistOnIndex == 0 and internValues_DB.SavedCounter == 1 ) then
				if ( defaultValues_DB.ChatMessagesOn == true ) then
					print( ColorText(L["ProfileSwitcher_Deleted_RaidProfile_Output"]:gsub("'replacement'", internValues_DB.SavedSelectedProfile), "option") );
				end
				defaultValues_DB.SavedProfiles = nil;
				defaultValues_DB.SavedProfiles = {};
			else
				RaidProfilOnLoadExists(internValues_DB.SavedSelectedProfile);
				if ( defaultValues_DB.ChatMessagesOn == true ) then
					print( ColorText(L["ProfileSwitcher_Deleted_RaidProfile_Output"]:gsub("'replacement'", internValues_DB.SavedSelectedProfile), "option") );
				end
				table.remove(defaultValues_DB.SavedProfiles, internValues_DB.RaidProfileExistOnIndex);
			end
			internValues_DB.SavedCounter = internValues_DB.SavedCounter -1;
			UIDropDownMenu_SetText(Main_ddm_Saved, "");	
			if ( CountTable(defaultValues_DB.SavedProfiles) > 0 ) then
				Main_btn_Reset:Enable();
			else
				Main_btn_Reset:Disable();
			end
			DisableSliders("1", "40");
			fillArray();
			SaveOptions();
		end);
		
	Main_btn_Reset:SetScript("OnClick",
		function()
			Debug("Main_btn_Reset", "", 2);
			StaticPopupDialogs["Show_Dialog_Reset"] = {
				text = L["ProfileSwitcher_Reset_RaidProfile_Dialog"],
				button1 = L["ProfileSwitcher_Reset_RaidProfile_Dialog_Yes"],
				button2 = L["ProfileSwitcher_Reset_RaidProfile_Dialog_No"],
				OnAccept = function()
					Debug("Main_btn_Reset", "Yes", 3);
					defaultValues_DB.SavedProfiles = nil;
					defaultValues_DB.SavedProfiles = {};	
					UIDropDownMenu_SetText(Main_ddm_Available, "");
					UIDropDownMenu_SetText(Main_ddm_Saved, "");
					Main_btn_Reset:Disable();
					DisableSliders("1", "40");
					fillArray();
					SaveOptions();	
					if ( defaultValues_DB.ChatMessagesOn == true ) then
						print( ColorText(L["ProfileSwitcher_Reset_RaidProfile_Dialog_accepted_Output"], "option") );
					end
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}		
			StaticPopup_Show ("Show_Dialog_Reset");
		end);
		
	Main_btn_Reload:SetScript("OnClick",
		function()
			ReloadUI();
	end);
end

local function SliderEvent()
	Debug("SliderEvent", "", 2);
	Main_slider_Minimum:SetScript("OnValueChanged",
		function()
			if ( (internValues_DB.AvailableSelectedProfile ~= nil and internValues_DB.SavedSelectedProfile == nil) or  (internValues_DB.AvailableSelectedProfile == nil and internValues_DB.SavedSelectedProfile ~= nil) ) then				
				UpdateSliders("Minimum");
				Debug("SliderEvent", "Minimum Slider " .. Main_slider_Minimum:GetValue(), 3);
				if ( internValues_DB.SavedSelectedProfile ~= nil ) then
					RaidProfilOnLoadExists(internValues_DB.SavedSelectedProfile);
					if ( defaultValues_DB.SavedProfiles[internValues_DB.RaidProfileExistOnIndex].Minimum ==  math.floor(Main_slider_Minimum:GetValue()) and defaultValues_DB.SavedProfiles[internValues_DB.RaidProfileExistOnIndex].Maximum ==  math.floor(Main_slider_Maximum:GetValue())) then
						Main_btn_Save:Disable();
					else
						Main_btn_Save:Enable();
					end
				end
			end
		end);
		
	Main_slider_Maximum:SetScript("OnValueChanged",
		function()
			if ( (internValues_DB.AvailableSelectedProfile ~= nil and internValues_DB.SavedSelectedProfile == nil) or  (internValues_DB.AvailableSelectedProfile == nil and internValues_DB.SavedSelectedProfile ~= nil) ) then
				UpdateSliders("Maximum");
				Debug("SliderEvent", "Maximum Slider " .. Main_slider_Maximum:GetValue(), 3);
				if ( internValues_DB.SavedSelectedProfile ~= nil ) then
					RaidProfilOnLoadExists(internValues_DB.SavedSelectedProfile);
					if ( defaultValues_DB.SavedProfiles[internValues_DB.RaidProfileExistOnIndex].Minimum ==  math.floor(Main_slider_Minimum:GetValue()) and defaultValues_DB.SavedProfiles[internValues_DB.RaidProfileExistOnIndex].Maximum ==  math.floor(Main_slider_Maximum:GetValue())) then
						Main_btn_Save:Disable();
					else
						Main_btn_Save:Enable();
					end
				end
			end	
		end);
end
---End Events


local function createFrame()	
	Debug("createFrame", "", 2);
	
	Main_Frame.name = "ProfileSwitcher";
	Main_Title:SetFont("Fonts\\FRIZQT__.TTF", 18);
	Main_Title:SetTextColor(1, 0.8, 0);
    Main_Title:SetPoint("TOPLEFT", 12, -18);
    Main_Title:SetText("ProfileSwitcher");
	InterfaceOptions_AddCategory(Main_Frame);
	
	Option_Frame.name = L["ProfileSwitcher_Option_Frame_Text"];
	Option_Title:SetFont("Fonts\\FRIZQT__.TTF", 18);
	Option_Title:SetTextColor(1, 0.8, 0);
    Option_Title:SetPoint("TOPLEFT", 12, -18);
    Option_Title:SetText(L["ProfileSwitcher_Option_Frame_Text"].."|r");
	Option_Frame.parent = Main_Frame.name;
	InterfaceOptions_AddCategory(Option_Frame);
end

local function createText()
	Debug("createText", "", 2);
	
	Main_Text_Version:SetPoint("TOPLEFT", 20, -45);
	Main_Text_Version:SetFontObject(GameFontHighlightSmall);
	Main_Text_Version:SetText(intern_versionOutput);
	Main_Text_Version:SetSize(string.len(intern_versionOutput), 10);
	
	Main_Text_Author:SetPoint("TOPLEFT", 20, -55);
	Main_Text_Author:SetFontObject(GameFontHighlightSmall);
	Main_Text_Author:SetText(intern_authorOutput);
	Main_Text_Author:SetSize(string.len(intern_authorOutput), 10);
	
	Main_Text_From:SetPoint("TOPLEFT", Main_slider_Minimum, 0, 30);
	Main_Text_From:SetFontObject(GameFontHighlightMedium);
	Main_Text_From:SetText("|cFF00FF00" .. L["ProfileSwitcher_Main_Text_From_Text"]);
	Main_Text_From:SetSize(string.len(L["ProfileSwitcher_Main_Text_From_Text"]), 20);
	
	Main_Text_To:SetPoint("TOPLEFT", Main_slider_Maximum, 140-(string.len(L["ProfileSwitcher_Main_Text_To_Text"])), -30);
	Main_Text_To:SetFontObject(GameFontHighlightMedium);
	Main_Text_To:SetText("|cFF00FF00" .. L["ProfileSwitcher_Main_Text_To_Text"]);
	Main_Text_To:SetSize(string.len(L["ProfileSwitcher_Main_Text_To_Text"]), 20);
	
	Main_Text_Available:SetPoint("TOPLEFT", Main_ddm_Available, 20, 20);
	Main_Text_Available:SetFontObject(GameFontHighlightMedium);
	Main_Text_Available:SetText(L["ProfileSwitcher_Main_Text_Available_Text"]);
	Main_Text_Available:SetSize(string.len(L["ProfileSwitcher_Main_Text_Available_Text"]), 20);
	
	Main_Text_Saved:SetPoint("TOPLEFT", Main_ddm_Saved, 20, 20);
	Main_Text_Saved:SetFontObject(GameFontHighlightMedium);
	Main_Text_Saved:SetText(L["ProfileSwitcher_Main_Text_Saved_Text"]);
	Main_Text_Saved:SetSize(string.len(L["ProfileSwitcher_Main_Text_Saved_Text"]), 20);
	
	Option_Text_General:SetPoint("TOPLEFT", 40, -80);
	Option_Text_General:SetFontObject(GameFontHighlightMedium);
	Option_Text_General:SetText(L["ProfileSwitcher_Option_Text_General_Text"]);
	Option_Text_General:SetSize(string.len(L["ProfileSwitcher_Option_Text_General_Text"]), 20);
	
	Option_Text_Combat:SetPoint("TOPLEFT", 40, -170);
	Option_Text_Combat:SetFontObject(GameFontHighlightMedium);
	Option_Text_Combat:SetText(L["ProfileSwitcher_Option_Text_Combat_Text"]);
	Option_Text_Combat:SetSize(string.len(L["ProfileSwitcher_Option_Text_Combat_Text"]), 20);
end

local function createCheckbox()	
	Debug("createCheckbox", "", 2);
	
	Option_cb_ChatMessagesOn:SetPoint("TOPLEFT", 15, -20);
	Option_cb_RaidProfilesSwitchInCombat:SetPoint("TOPLEFT", 15, -20);	
	Option_cb_RaidProfilesUpdateInCombat:SetPoint("TOPLEFT", 15, -50);
	
	getglobal(Option_cb_ChatMessagesOn:GetName() .. 'Text'):SetText(ColorText(L["ProfileSwitcher_Option_cb_ChatMessagesOn_Text"], "white"));
	getglobal(Option_cb_RaidProfilesSwitchInCombat:GetName() .. 'Text'):SetText(ColorText(L["ProfileSwitcher_Option_cb_RaidProfilesSwitchInCombat_Text"], "white"));
	getglobal(Option_cb_RaidProfilesUpdateInCombat:GetName() .. 'Text'):SetText(ColorText(L["ProfileSwitcher_Option_cb_RaidProfilesUpdateInCombat_Text"], "white"));
end

local function createButton()
	Debug("createButton", "", 2);
	
	Main_btn_Save:SetSize(120, 24);
	Main_btn_Save:SetText(L["ProfileSwitcher_Main_btn_Save_Text"]);
	Main_btn_Save:SetPoint("TOPLEFT", Main_Title, 300, -260);
	
	Main_btn_Delete:SetSize(120, 24);
	Main_btn_Delete:SetText(L["ProfileSwitcher_Main_btn_Delete_Text"]);
	Main_btn_Delete:SetPoint("TOPLEFT", Main_Title, 450, -260);
	
	Main_btn_Reset:SetSize(120, 24);
	Main_btn_Reset:SetText(L["ProfileSwitcher_Main_btn_Reset_Text"]);
	Main_btn_Reset:SetPoint("TOPLEFT", Main_Title, 450, -300);
	
	Main_btn_Reload:SetSize(120, 24);
	Main_btn_Reload:SetText(L["ProfileSwitcher_Main_btn_Reload_Text"]);
	Main_btn_Reload:SetPoint("TOPLEFT", 450, -300);
end

local function createDropDownMenu()
	Debug("createDropDownMenu", "", 2);
	
	Main_ddm_Available.text = _G["MainDdmAvailable"];
	Main_ddm_Available.text:SetText("Empty ddm");
	Main_ddm_Available:SetPoint("TOPLEFT",Main_Title, 25, -140);		
	Main_ddm_Available.info = {};
	Main_ddm_Available.initialize = function(self, level)
		if ( internValues_DB.inCombat == false and level == 1 ) then
			wipe(self.info);
			DeleteNotExistingProfiles();
			ProfileExists();
			local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo("SortGroup");
			local exists, result = pcall(SortGroup_Method_GetAutoActivate);
			for i, value in pairs(internValues_DB.ddmItems) do
				if ( RaidProfilOnLoadExists(value) == false ) then
					self.info.text = value;
					self.info.value = i;
					DisableSliders("1", "40");
					UIDropDownMenu_SetText(Main_ddm_Saved, "");
					UIDropDownMenu_SetText(Main_ddm_Available, "");
					self.info.func = function(item)
						self.selectedID = item:GetID();
						self.text:SetText(item);
						self.value = i;
						internValues_DB.AvailableSelectedProfile = value;
						UIDropDownMenu_SetText(Main_ddm_Saved, "");
						UIDropDownMenu_SetText(Main_ddm_Available, internValues_DB.AvailableSelectedProfile);					
						internValues_DB.SavedSelectedProfile = nil;
						Main_slider_Minimum:Enable();
						Main_slider_Maximum:Enable();
						Main_btn_Save:Enable();
						if ( enabled == true and exists == true ) then
							if ( SortGroup_Method_GetAutoActivate() == true and SortGroup_Method_GetProfile() == value ) then
								DisableSliders("1", "5");
								getglobal(Main_slider_Minimum:GetName() .. 'Text'):SetText(ColorText("1", "disable"));
								getglobal(Main_slider_Maximum:GetName() .. 'Text'):SetText(ColorText("5", "disable"));
							elseif ( SortGroup_Method_GetAutoActivate() == true ) then							
								EnableSliders("6", "40");
								UpdateSliders("ddmProfiles");
							else
								EnableSliders("1", "40");
								UpdateSliders("ddmProfiles");	
							end
						else
							EnableSliders("1", "40");
							UpdateSliders("ddmProfiles");							
						end
						--UpdateSliders("ddmProfiles");
					end
					--
					self.info.checked = i == self.text:GetText();
					UIDropDownMenu_AddButton(self.info, level);
					if ( internValues_DB.AvailableSelectedProfile == self.info.text ) then
						UIDropDownMenu_SetSelectedID(Main_ddm_Available, i)
					end
				end
			end
		else
			if ( defaultValues_DB.ChatMessagesOn == true ) then
				print(ColorText(L["ProfileSwitcher_in_combat_options_Output"], "option"));
			end
		end
	end
	Main_ddm_Available:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self,"ANCHOR_RIGHT");
			GameTooltip:AddLine(L["ProfileSwitcher_Main_Text_Available_Text"] .. "\n\n" .. ColorText(L["ProfileSwitcher_Main_ddm_Available_ToolTip"], "white"), nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Main_ddm_Available:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	
	
	Main_ddm_Saved.text = _G["MainDdmSaved"];
	Main_ddm_Saved.text:SetText("Empty ddm");
	Main_ddm_Saved:SetPoint("TOPLEFT",Main_Title, 425, -140);		
	Main_ddm_Saved.info = {};
	Main_ddm_Saved.initialize = function(self, level)
		if ( internValues_DB.inCombat == false and level == 1 ) then
			wipe(self.info);
			DeleteNotExistingProfiles()
			internValues_DB.SavedCounter = 0;
			DisableSliders("1", "40");
			UIDropDownMenu_SetText(Main_ddm_Saved, "");
			UIDropDownMenu_SetText(Main_ddm_Available, "");
			local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo("SortGroup");
			local exists, result = pcall(SortGroup_Method_GetAutoActivate);
			for i = 1, (CountTable(defaultValues_DB.SavedProfiles)), 1 do
				self.info.text = defaultValues_DB.SavedProfiles[i].RaidProfileName;
				self.info.value = i;
				internValues_DB.SavedCounter = internValues_DB.SavedCounter + 1;
				self.info.func = function(item)
					self.selectedID = item:GetID();
					self.text:SetText(item);
					self.value = i;
					internValues_DB.SavedSelectedProfile = defaultValues_DB.SavedProfiles[i].RaidProfileName;
					UIDropDownMenu_SetText(Main_ddm_Saved, internValues_DB.SavedSelectedProfile);
					UIDropDownMenu_SetText(Main_ddm_Available, "");
					Main_btn_Delete:Enable();
					--Main_btn_Save:Enable();
					Main_slider_Minimum:Enable();
					Main_slider_Maximum:Enable();
					internValues_DB.AvailableSelectedProfile = nil;
					if ( enabled == true and exists == true ) then
						if ( SortGroup_Method_GetAutoActivate() == true ) then
							EnableSliders("6", "40");
						else 
							EnableSliders("1", "40");	
						end
					else
						EnableSliders("1", "40");		
					end
					UpdateSliders("ddmSelectedProfiles",i);
				end
				self.info.checked = i == self.text:GetText();
				UIDropDownMenu_AddButton(self.info, level);
				if ( Main_ddm_Saved == self.info.text ) then
					UIDropDownMenu_SetSelectedID(Main_ddm_Saved, i)
				end
			end
		else
			if ( defaultValues_DB.ChatMessagesOn == true ) then
				print(ColorText(L["ProfileSwitcher_in_combat_options_Output"], "option"));
			end
		end
	end
	Main_ddm_Saved:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self,"ANCHOR_RIGHT");
			GameTooltip:AddLine(L["ProfileSwitcher_Main_Text_Saved_Text"] .. "\n\n" .. ColorText(L["ProfileSwitcher_Main_ddm_Saved_ToolTip"], "white"), nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Main_ddm_Saved:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
end
--DropDownMenu creating, include items

local function createSliders()
	Debug("createSliders", "", 2);
	MainSliderMinimum:SetSize(150, 17);
	MainSliderMinimum:SetPoint("TOPLEFT", Main_Title, 230, -120);
	MainSliderMinimum:SetOrientation('HORIZONTAL');
	MainSliderMinimum:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal");
	MainSliderMinimum:SetMinMaxValues(1,40);
	MainSliderMinimum:SetValue(1);
	getglobal(Main_slider_Minimum:GetName() .. 'Low'):SetText('1');
	getglobal(Main_slider_Minimum:GetName() .. 'High'):SetText('40');
	getglobal(Main_slider_Minimum:GetName() .. 'Text'):SetText(Main_slider_Minimum:GetValue());
	MainSliderMinimum:SetBackdrop({
		bgFile = "Interface\\Buttons\\UI-SliderBar-Background", 
		edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
		tile = true, tileSize = 8, edgeSize = 8, 
		insets = { left = 3, right = 3, top = 6, bottom = 6 }})
	MainSliderMinimum:SetValueStep(1);
	
	MainSliderMaximum:SetSize(150, 17);
	MainSliderMaximum:SetPoint("TOPLEFT", Main_Title, 230, -170);
	MainSliderMaximum:SetOrientation('HORIZONTAL');
	MainSliderMaximum:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal");
	MainSliderMaximum:SetMinMaxValues(1,40);
	MainSliderMaximum:SetValue(40);
	getglobal(Main_slider_Maximum:GetName() .. 'Low'):SetText('1');
	getglobal(Main_slider_Maximum:GetName() .. 'High'):SetText('40');
	getglobal(Main_slider_Maximum:GetName() .. 'Text'):SetText(Main_slider_Maximum:GetValue());
	MainSliderMaximum:SetBackdrop({
		bgFile = "Interface\\Buttons\\UI-SliderBar-Background", 
		edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
		tile = true, tileSize = 8, edgeSize = 8, 
		insets = { left = 3, right = 3, top = 6, bottom = 6 }})
	MainSliderMaximum:SetValueStep(1);
end
--- End Creating


local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "ProfileSwitcher" then
		Debug("StartAddon", "", 2);
		createFrame();
		createText();
		createCheckbox();
		createButton();
		createDropDownMenu();
		createSliders();
		frameEvent();	
		checkBoxEvent();
		buttonEvent();
		SliderEvent();
		self:UnregisterEvent("ADDON_LOADED");
	end
end)