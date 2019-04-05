--[[
	PartyCastingBars
	 	Adds party member casting bars to their unit frames.
	
	By: AnduinLothar
	
	
	$Id: PartyCastingBars.lua 4157 2006-10-13 20:12:04Z geowar $
	$Rev: 4157 $
	$LastChangedBy: geowar $
	$Date: 2006-10-13 13:12:04 -0700 (Fri, 13 Oct 2006) $
	
]]--

--------------------------------------------------
-- Globals
--------------------------------------------------
PartyCastingBars = {};

PartyCastingBars.ColorResetting = {};
PartyCastingBars.ColorResetting["FRIENDLY"] = {};
PartyCastingBars.ColorResetting["HOSTILE"] = {};

PartyCastingBars.Bars = {};

PartyCastingBars.DefaultColors = {
	["FRIENDLY"] = {
		["CAST"] = {	--Light Blue
			r=0.0;
			g=0.7;
			b=1.0;		
		};
		["CHANNEL"] = {	--Green
			r=0.0;
			g=1.0;
			b=0.0;
		};
		["SUCCESS"] = {	--Green
			r=0.0;
			g=1.0;
			b=0.0;
		};
		["FAILURE"] = {	--Red
			r=1.0;
			g=0.0;
			b=0.0;
		};
	};
	["HOSTILE"] = {
		["CAST"] = {	--Orange
			r=1.0;
			g=0.5;
			b=0.1;
		};
		["CHANNEL"] = {	--Orange
			r=1.0;
			g=0.6;
			b=0.2;
		};
		["SUCCESS"] = {	--Green
			r=0.0;
			g=1.0;
			b=0.0;
		};
		["FAILURE"] = {	--Red
			r=1.0;
			g=0.0;
			b=0.0;
		};
	};	
};

PartyCastingBars.TIME_LEFT = "(%.1fs)";
PartyCastingBars.SPELL_AND_TARGET = "%s - %s";
PartyCastingBars.COMM_FORMAT = "%s,%s,%s"; -- spellname, targetname, hostile/friendly

--------------------------------------------------
-- Configuration Functions
--------------------------------------------------

PartyCastingBars_Colors = {
	["FRIENDLY"] = {
		["CAST"] = {	--Yellow
			r=1.0;
			g=0.7;
			b=0.0;		
		};
		["CHANNEL"] = {	--Green
			r=0.0;
			g=1.0;
			b=0.0;
		};
		["SUCCESS"] = {	--Green
			r=0.0;
			g=1.0;
			b=0.0;
		};
		["FAILURE"] = {	--Red
			r=1.0;
			g=0.0;
			b=0.0;
		};
	};
	["HOSTILE"] = {
		["CAST"] = {	--Orange
			r=1.0;
			g=0.5;
			b=0.1;
		};
		["CHANNEL"] = {	--Orange
			r=1.0;
			g=0.6;
			b=0.2;
		};
		["SUCCESS"] = {
			r=0.0;
			g=1.0;
			b=0.0;
		};
		["FAILURE"] = {
			r=1.0;
			g=0.0;
			b=0.0;
		};
	};
};

-- colorToString(Table{r,g,b,a}) From SeaString
local function colorToString(color)
	if (not color) then 
		return "FFFFFFFF";
	end
	return string.format("%.2X%.2X%.2X%.2X",
		(color.a or color.opacity or 1) * 255,
		(color.r or 0) * 255, 
		(color.g or 0) * 255, 
		(color.b or 0) * 255
	);
end

local function setBarColor()
	local r,g,b = ColorPickerFrame:GetColorRGB()
	local reaction = ColorPickerFrame.extraInfo.reaction
	local typeString = ColorPickerFrame.extraInfo.typeString
	local info = PartyCastingBars_Colors[reaction][typeString]
	info.r=r; info.g=g; info.b=b
	if (not ColorPickerFrame:IsShown()) then
		DEFAULT_CHAT_FRAME:AddMessage(PCB_COLOR_SET:format(reaction, typeString, colorToString(info), r, g, b) )
	end
end

local function cancelBarColorChange()
	local color = ColorPickerFrame.previousValues
	local reaction = ColorPickerFrame.extraInfo.reaction
	local typeString = ColorPickerFrame.extraInfo.typeString
	local info = PartyCastingBars_Colors[reaction][typeString]
	info.r=color.r; info.g=color.g; info.b=color.b
	if (not ColorPickerFrame:IsShown()) then
		DEFAULT_CHAT_FRAME:AddMessage(PCB_COLOR_SET:format(reaction, typeString, colorToString(info), info.r, info.g, info.b) )
	end
end

function PartyCastingBars.ResetBarColor(reaction, typeString)
	local default = PartyCastingBars.DefaultColors[reaction][typeString]
	local info = PartyCastingBars_Colors[reaction][typeString]
	info.r=default.r; info.g=default.g; info.b=default.b
	DEFAULT_CHAT_FRAME:AddMessage(PCB_COLOR_SET:format(reaction, typeString, colorToString(info), info.r, info.g, info.b) )
end

for reaction, info in pairs(PartyCastingBars_Colors) do
	for typeString, typeInfo in pairs(info) do
		typeInfo.extraInfo = {typeString=typeString, reaction=reaction}
	end
end

function PartyCastingBars.OpenColorPicker(info)
	ColorPickerFrame.hasOpacity = nil;
	ColorPickerFrame.opacityFunc = nil;
	ColorPickerFrame.opacity = 1;
	ColorPickerFrame.previousValues = {r = info.r+0, g = info.g+0, b = info.b+0, opacity = 1};
	ColorPickerFrame.func = setBarColor;
	ColorPickerFrame.cancelFunc = cancelBarColorChange;
	ColorPickerFrame.extraInfo = info.extraInfo;
	-- This must come last, since it triggers a call to ColorPickerFrame.func()
	--ColorPickerFrame:SetColorRGB(info.r, info.g, info.b);
	ShowUIPanel(ColorPickerFrame);
	ColorPickerFrame:SetColorRGB(info.r, info.g, info.b);
end

--------------------------------------------------
-- Party Member Caching
--------------------------------------------------

PartyCastingBars.PartyMembers = {}
PartyCastingBars.HostilityCache = {}

function PartyCastingBars.CachePartyMembers()
	PartyCastingBars.PartyMembers = {}
	for i=1, 4 do
		local unit = "party"..i
		if (UnitExists(unit)) then
			local name = UnitName(unit)
			PartyCastingBars.PartyMembers[name] = i
			PartyCastingBars.HostilityCache[name] = UnitCanAttack("player", unit)
		end
	end
	if (UnitInRaid("player")) then
		for i=1, 40 do
			local unit = "raid"..i
			if (UnitExists(unit)) then
				local name = UnitName(unit)
				PartyCastingBars.HostilityCache[name] = UnitCanAttack("player", unit)
			end
		end
	end
end


--------------------------------------------------
-- Color Management
--------------------------------------------------

function PartyCastingBars.GetColorArgs(database)
	return database.r, database.g, database.b
end

--------------------------------------------------
-- Events
--------------------------------------------------

function PartyCastingBars.EventFrameOnLoad(frame)
	frame:RegisterEvent("VARIABLES_LOADED")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
	frame:RegisterEvent("PLAYER_TARGET_CHANGED")
	frame:RegisterEvent("UNIT_SPELLCAST_SENT")
	frame:RegisterEvent("CHAT_MSG_ADDON")
end

function PartyCastingBars.EventFrameOnEvent(event, newarg1, newarg2, newarg3, newarg4)
	if ( event == "VARIABLES_LOADED" ) then
		PartyCastingBars.RegisterConfig()
		
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		PartyCastingBars.CachePartyMembers()
		
	elseif ( event == "PARTY_MEMBERS_CHANGED" ) then
		PartyCastingBars.CachePartyMembers()
		
	elseif ( event == "PLAYER_TARGET_CHANGED" ) then
		if (UnitExists("target")) then
			PartyCastingBars.HostilityCache[UnitName("target")] = UnitCanAttack("player", "target")
		end
		
	elseif ( event == "UNIT_SPELLCAST_SENT" ) then
		-- "player", spell, rank, target
		if (newarg2 and newarg4) then
			if (PartyCastingBars.HostilityCache[newarg4]) then
				ChatThrottleLib:SendAddonMessage("ALERT", "PartyCastingBars", format(PartyCastingBars.COMM_FORMAT, newarg2, newarg4, "hostile"), "PARTY");
			else
				ChatThrottleLib:SendAddonMessage("ALERT", "PartyCastingBars", format(PartyCastingBars.COMM_FORMAT, newarg2, newarg4, "friendly"), "PARTY");
			end
		end
		
	elseif ( event == "CHAT_MSG_ADDON" ) then
		-- prefix, msg, method, sender
		if (newarg1 == "PartyCastingBars") then
			local partyNum = PartyCastingBars.PartyMembers[newarg4]
			if (partyNum) then
				local _, _, spellName, targetName, relationship = strfind(newarg2, "^(.+),(.+),(.+)$")
				if (spellName and targetName and relationship) then
					local frame = getglobal("PartyMemberFrame"..partyNum.."CastingBarFrame")
					frame.targetName = targetName
					frame.hostileCast = (relationship == "hostile")
					PartyCastingBars.OnEvent(frame, "UNIT_SPELLCAST_TARGET_CHANGED", "party"..partyNum, spellName)
				end
			end
		end
		
	end
end

--------------------------------------------------
-- Bar Scripts
--------------------------------------------------

function PartyCastingBars.OnLoad(bar)
	-- Modified from CastingBarFrame_OnLoad
	bar:RegisterEvent("UNIT_SPELLCAST_START");
	bar:RegisterEvent("UNIT_SPELLCAST_STOP");
	bar:RegisterEvent("UNIT_SPELLCAST_FAILED");
	bar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
	bar:RegisterEvent("UNIT_SPELLCAST_DELAYED");
	bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START");
	bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE");
	bar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");
	--bar:RegisterEvent("PLAYER_ENTERING_WORLD");
	
	bar:RegisterForDrag("LeftButton");
	
	bar.partyFrame = bar:GetParent();
	bar.unit = bar:GetParent().unit or bar:GetParent():GetAttribute("unit");
	bar.showTradeSkills = true;
	bar.casting = nil;
	bar.channeling = nil;
	bar.holdTime = 0;
	bar.showCastbar = true;

	local barIcon = getglobal(bar:GetName().."Icon");
	barIcon:Hide();
	
	bar:SetScale(1.1)
	local text = getglobal(bar:GetName().."Text")
	text:ClearAllPoints()
	text:SetPoint("CENTER", bar, "CENTER", 0, 0)
	text:SetAlpha(0) -- CACHER LE TEXTE DU SORT
	bar.barText = text
	
	local border = getglobal(bar:GetName().."Border")
	border:SetTexture("Interface\\Tooltips\\UI-StatusBar-Border")
	border:SetWidth(132)
	border:SetHeight(18)
	border:ClearAllPoints()
	border:SetPoint("CENTER", bar, "CENTER", 0, 0)
	bar.border = border
	
	local flash = getglobal(bar:GetName().."Flash")
	flash:SetTexture("Interface\\AddOns\\PartyCastingBars\\Skin\\ArcaneBarFlash")
	flash:SetWidth(222)
	flash:SetHeight(34)
	flash:ClearAllPoints()
	flash:SetPoint("CENTER", bar, "CENTER", 0, 0)
	bar.barFlash = flash
	
	local icon = getglobal(bar:GetName().."Icon")
	icon:Show();
	bar.barIcon = icon
	
	local spark = getglobal(bar:GetName().."Spark")
	flash:ClearAllPoints()
	flash:SetPoint("CENTER", bar, "CENTER", 0, 0)
	bar.barSpark = spark
	
	bar.barTime = getglobal(bar:GetName().."Time")
	
	tinsert(PartyCastingBars.Bars, bar)
end

function PartyCastingBars.GetTimeLeft(bar)
	local min, max = bar:GetMinMaxValues();
	local current_time;
	if ( bar.channeling ) then
		current_time = bar:GetValue() - min;
	else
		current_time = max - bar:GetValue();
	end
	return format(PartyCastingBars.TIME_LEFT, math.max(current_time,0));
end

function PartyCastingBars.OnEvent(bar, event, unit, spellName)
	--Modified from CastingBarFrame_OnEvent to handle colors, interuptions, frame shortcuts and possible target text
	--[[
	if ( newevent == "PLAYER_ENTERING_WORLD" ) then
		local nameChannel  = UnitChannelInfo(bar.unit);
		local nameSpell  = UnitCastingInfo(bar.unit);
		if ( nameChannel ) then
			event = "UNIT_SPELLCAST_CHANNEL_START";
			unit = bar.unit;
		elseif ( nameSpell ) then
			event = "UNIT_SPELLCAST_START";
			unit = bar.unit;
		end
	end
	]]
	
	if ( unit ~= bar.unit ) then
		return;
	end

	local barSpark = bar.barSpark;
	local barText = bar.barText;
	local barFlash = bar.barFlash;
	local barIcon = bar.barIcon;

	if ( event == "UNIT_SPELLCAST_START" ) then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(bar.unit);
		if ( not name or (not bar.showTradeSkills and isTradeSkill)) then
			bar:Hide();
			return;
		end
		
		bar.hostileCast = bar.nextHostileCast;
		bar.targetName = bar.nextTargetName;
		
		if (bar.hostileCast) then
			bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["CAST"]));
		else
			bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["CAST"]));
		end
		barSpark:Show();
		bar.startTime = startTime / 1000;
		bar.maxValue = endTime / 1000;

		-- startTime to maxValue		no endTime
		bar:SetMinMaxValues(bar.startTime, bar.maxValue);
		bar:SetValue(bar.startTime);
		if (bar.targetName) then
--			barText:SetText(format(PartyCastingBars.SPELL_AND_TARGET, text, bar.targetName))
		else
--			barText:SetText(text);
		end
		barIcon:SetTexture(texture);
		bar:SetAlpha(1.0);
		bar.holdTime = 0;
		bar.casting = 1;
		bar.channeling = nil;
		bar.fadeOut = nil;
		if ( bar.showCastbar ) then
			bar:Show();
		end
				
		return;

	elseif ( event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" ) then
		if ( not bar:IsVisible() ) then
			bar:Hide();
		end
		if ( bar:IsShown() ) then
			local min, max = bar:GetMinMaxValues();
			local currTimeLeft = max - bar:GetValue();
			if (currTimeLeft > 0.1 and not bar.channeling) then
				-- use interupted event handler
				event = "UNIT_SPELLCAST_INTERRUPTED";
			else
				barSpark:Hide();
				barFlash:SetAlpha(0.0);
				barFlash:Show();
				bar:SetValue(bar.maxValue);
				if ( event == "UNIT_SPELLCAST_STOP" ) then
					if (bar.casting) then
						if (bar.hostileCast) then
							bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["SUCCESS"]));
						else
							bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["SUCCESS"]));
						end
					end
					bar.casting = nil;
				else
					bar.channeling = nil;
				end
				bar.flash = 1;
				bar.fadeOut = 1;
				bar.holdTime = 0;
			end
			
			bar.targetName = nil;
			bar.hostileCast = nil;
		end
	end
	
	if ( event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" ) then
		if ( bar:IsShown() and not bar.channeling ) then
			bar:SetValue(bar.maxValue);
			if (bar.hostileCast) then
				bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["FAILURE"]));
			else
				bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["FAILURE"]));
			end
			barSpark:Hide();
			--[[
			if ( event == "UNIT_SPELLCAST_FAILED" ) then
				barText:SetText(FAILED);
			else
				barText:SetText(INTERRUPTED);
			end
			]]--
			bar.casting = nil;
			bar.channeling = nil;
			bar.fadeOut = 1;
			bar.holdTime = GetTime() + CASTING_BAR_HOLD_TIME;
			
			bar.targetName = nil;
			bar.hostileCast = nil;
		end
	elseif ( event == "UNIT_SPELLCAST_TARGET_CHANGED" ) then
		-- Fake event, generated by chat comm
		if ( not spellName ) then
			return;
		end
		if ( bar:IsShown() ) then
			local min, max = bar:GetMinMaxValues();
			local currTimeLeft = max - bar:GetValue();
			
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill; 
			if ( bar.casting ) then
				name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(bar.unit);
			elseif ( bar.channeling ) then
				name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(bar.unit);
			end
			
			if (spellName == name and currTimeLeft > 0.1) then
				-- Spell start event was already recieved, update the current spell
				if ( bar.casting ) then
					if (bar.hostileCast) then
						bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["CAST"]));
					else
						bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["CAST"]));
					end
				elseif ( bar.channeling ) then
					if (bar.hostileCast) then
						bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["CHANNEL"]));
					else
						bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["CHANNEL"]));
					end
				end
				
				if (bar.targetName) then
--					barText:SetText(format(PartyCastingBars.SPELL_AND_TARGET, text, bar.targetName));
				else
--					barText:SetText(text);
				end
				return;
			end
		end
		
		bar.nextHostileCast = bar.hostileCast;
		bar.nextTargetName = bar.targetName;
		
	elseif ( event == "UNIT_SPELLCAST_DELAYED" ) then
		if ( bar:IsShown() ) then
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitCastingInfo(bar.unit);
			if ( not name or (not bar.showTradeSkills and isTradeSkill)) then
				-- if there is no name, there is no bar
				bar:Hide();
				return;
			end
			bar.startTime = startTime / 1000;
			bar.maxValue = endTime / 1000;
			bar:SetMinMaxValues(bar.startTime, bar.maxValue);
		end
	elseif ( event == "UNIT_SPELLCAST_CHANNEL_START" ) then
		local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(bar.unit);
		if ( not name or (not bar.showTradeSkills and isTradeSkill)) then
			-- if there is no name, there is no bar
			bar:Hide();
			return;
		end
		
		bar.hostileCast = bar.nextHostileCast;
		bar.targetName = bar.nextTargetName;

		if (bar.hostileCast) then
			bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["CHANNEL"]));
		else
			bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["CHANNEL"]));
		end
		barSpark:Show();
		bar.startTime = startTime / 1000;
		bar.endTime = endTime / 1000;
		bar.duration = bar.endTime - bar.startTime;
		bar.maxValue = bar.startTime;

		-- startTime to endTime		no maxValue
		bar:SetMinMaxValues(bar.startTime, bar.endTime);
		bar:SetValue(bar.endTime);
		if (bar.targetName) then
--			barText:SetText(format(PartyCastingBars.SPELL_AND_TARGET, text, bar.targetName))
		else
--			barText:SetText(text);
		end
		barIcon:SetTexture(texture);
		bar:SetAlpha(1.0);
		bar.holdTime = 0;
		bar.casting = nil;
		bar.channeling = 1;
		bar.fadeOut = nil;
		if ( bar.showCastbar ) then
			bar:Show();
		end
	elseif ( event == "UNIT_SPELLCAST_CHANNEL_UPDATE" ) then
		if ( bar:IsShown() ) then
			local name, nameSubtext, text, texture, startTime, endTime, isTradeSkill = UnitChannelInfo(bar.unit);
			if ( not name or (not bar.showTradeSkills and isTradeSkill)) then
				-- if there is no name, there is no bar
				bar:Hide();
				return;
			end
			bar.startTime = startTime / 1000;
			bar.endTime = endTime / 1000;
			bar.maxValue = bar.startTime;
			bar:SetMinMaxValues(bar.startTime, bar.endTime);
		end
	end

end

function PartyCastingBars.OnUpdate(bar)
	if ( PartyCastingBars.draggable ) then
		return;
	end
	if ( bar.casting ) then
		local status = GetTime();
		if ( status > bar.maxValue ) then
			status = bar.maxValue;
		end
		if ( status == bar.maxValue ) then
			bar:SetValue(bar.maxValue);
			if (bar.hostileCast) then
				bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["SUCCESS"]));
			else
				bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["SUCCESS"]));
			end
			bar.barSpark:Hide();
			bar.barFlash:SetAlpha(0.0);
			bar.barFlash:Show();
			bar.casting = nil;
			bar.flash = 1;
			bar.fadeOut = 1;
			return;
		end
		bar:SetValue(status);
		bar.barFlash:Hide();
		local sparkPosition = ((status - bar.startTime) / (bar.maxValue - bar.startTime)) * bar:GetWidth();
		if ( sparkPosition < 0 ) then
			sparkPosition = 0;
		end
		bar.barSpark:SetPoint("CENTER", bar, "LEFT", sparkPosition, 0);
--		bar.barTime:SetText(PartyCastingBars.GetTimeLeft(bar));
	elseif ( bar.channeling ) then
		local time = GetTime();
		if ( time > bar.endTime ) then
			time = bar.endTime;
		end
		if ( time == bar.endTime ) then
			if (bar.hostileCast) then
				bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["HOSTILE"]["SUCCESS"]));
			else
				bar:SetStatusBarColor(PartyCastingBars.GetColorArgs(PartyCastingBars_Colors["FRIENDLY"]["SUCCESS"]));
			end
			bar.barSpark:Hide();
			bar.barFlash:SetAlpha(0.0);
			bar.barFlash:Show();
			bar.channeling = nil;
			bar.flash = 1;
			bar.fadeOut = 1;
			return;
		end
		local barValue = bar.startTime + (bar.endTime - time);
		bar:SetValue( barValue );
		bar.barFlash:Hide();
		local sparkPosition = ((barValue - bar.startTime) / (bar.endTime - bar.startTime)) * bar:GetWidth();
		bar.barSpark:SetPoint("CENTER", bar, "LEFT", sparkPosition, 0);
--		bar.barTime:SetText(PartyCastingBars.GetTimeLeft(bar));
	elseif ( GetTime() < bar.holdTime ) then
		return;
	elseif ( bar.flash ) then
		local alpha = bar.barFlash:GetAlpha() + CASTING_BAR_FLASH_STEP;
		if ( alpha < 1 ) then
			bar.barFlash:SetAlpha(alpha);
		else
			bar.barFlash:SetAlpha(1.0);
			bar.flash = nil;
		end
	elseif ( bar.fadeOut ) then
		local alpha = bar:GetAlpha() - CASTING_BAR_ALPHA_STEP;
		if ( alpha > 0 ) then
			bar:SetAlpha(alpha);
		else
			bar.fadeOut = nil;
			bar:Hide();
		end
	end
end

function PartyCastingBars.OnDragStart(bar, button)
	if (not PartyCastingBars.draggable) then
		return;
	end
	bar:StartMoving();
end

function PartyCastingBars.OnDragStop(bar)
	bar:StopMovingOrSizing();
end

function PartyCastingBars.OnMouseUp(bar)
	bar:StopMovingOrSizing();
end

function PartyCastingBars.OnHide(bar)
	bar:StopMovingOrSizing();
end

--------------------------------------------------
-- Master Enable
--------------------------------------------------

function PartyCastingBars.EnableToggle(value)
	if (value) then
		if (PartyCastingBars_Enabled) then
			--Do nothing
		else
			for i, barFrame in ipairs(PartyCastingBars.Bars) do
				barFrame:SetScript("OnEvent", PartyCastingBars.OnEvent);
				barFrame:SetScript("OnUpdate", PartyCastingBars.OnUpdate);
			end
			PartyCastingBars_Enabled = true;
		end
	else
		if (PartyCastingBars_Enabled) then
			for i, barFrame in ipairs(PartyCastingBars.Bars) do
				barFrame:SetScript("OnEvent", nil);
				barFrame:SetScript("OnUpdate", nil);
				barFrame:Hide();
			end
			PartyCastingBars_Enabled = false;
		else
			--Do nothing
		end
	end
end

--------------------------------------------------
-- Icon Enable
--------------------------------------------------

function PartyCastingBars.EnableIcons(value)
	if (value) then
		if (PartyCastingBars_IconsEnabled) then
			--Do nothing
		else
			for i, barFrame in ipairs(PartyCastingBars.Bars) do
				barFrame.barIcon:Show();
			end
			PartyCastingBars_IconsEnabled = true;
		end
	else
		if (PartyCastingBars_IconsEnabled) then
			for i, barFrame in ipairs(PartyCastingBars.Bars) do
				barFrame.barIcon:Hide();
			end
			PartyCastingBars_IconsEnabled = false;
		else
			--Do nothing
		end
	end
end

--------------------------------------------------
-- Bar Parenting
--------------------------------------------------

function PartyCastingBars.SetParents(value)
	PartyCastingBars_Parented = (value);
	for i, barFrame in ipairs(PartyCastingBars.Bars) do
		barFrame:SetParent(value and barFrame.partyFrame or UIParent);
	end
end

--------------------------------------------------
-- Bar Scaling
--------------------------------------------------

function PartyCastingBars.SetScales(value)
	for i, barFrame in ipairs(PartyCastingBars.Bars) do
		barFrame:SetScale(value);
	end
end

--------------------------------------------------
-- Draggable Mode
--------------------------------------------------

function PartyCastingBars.EnableDragging(value)
	PartyCastingBars.draggable = (value);
	for i, barFrame in ipairs(PartyCastingBars.Bars) do
		if (PartyCastingBars.draggable) then
			barFrame:Show();
			barFrame.barText:SetText(PCB_DRAGGABLE.." #"..i);
			barFrame.barSpark:Hide();
			barFrame.barTime:SetText(format(PartyCastingBars.TIME_LEFT, 15));
			barFrame.barTime:Show();
			barFrame.barIcon:SetTexture("Interface\\Icons\\Spell_Holy_PowerWordShield");
			barFrame:SetAlpha(1);
			barFrame:EnableMouse(1);
		else
			barFrame:Hide();
			barFrame:EnableMouse();
		end
	end
end

--------------------------------------------------
-- Reset Bars
--------------------------------------------------

function PartyCastingBars.ResetBarLocations()
	for i, barFrame in ipairs(PartyCastingBars.Bars) do
		barFrame:ClearAllPoints();
		barFrame:SetPoint("TOPLEFT", barFrame.partyFrame, "TOPRIGHT", 7, 2);
	end
end

--------------------------------------------------
-- Khaos Config
--------------------------------------------------

function PartyCastingBars.RegisterConfig()
	--------------------------------------------------
	-- Configuration Functions
	--------------------------------------------------
	
	if (not PartyCastingBars_Colors) then PartyCastingBars_Colors = {} end;
	if (not PartyCastingBars_Colors["FRIENDLY"]) then PartyCastingBars_Colors["FRIENDLY"] = {} end;
	if (not PartyCastingBars_Colors["HOSTILE"]) then PartyCastingBars_Colors["HOSTILE"] = {} end;
	
	if ( Khaos ) then 
		-- Khaos will save our vars, not the toc!
		PartyCastingBars_Enabled = true;
		PartyCastingBars_IconsEnabled = true;
		-- W0000!
		local optionSet = {};
		local commandSet = {};
		local configurationSet = {
			id="PartyCastingBars";
			text=PCB_SECTION_TEXT;
			helptext=PCB_SECTION_TIP;
			difficulty=1;
			options=optionSet;
			commands=commandSet;
			default=false;
			callback=PartyCastingBars.EnableToggle;
		};
	
		-- Register Basics
		table.insert(
			optionSet,
			{
				id="Header";
				text=PCB_HEADER_TEXT;
				helptext=PCB_HEADER_TIP;
				difficulty=1;
				type=K_HEADER;
			}
		);
		table.insert(
			optionSet,
			{
				id="ShowSpellIcon";
				text=PCB_SHOW_ICON_TEXT;
				helptext=PCB_SHOW_ICON_TIP;
				difficulty=1;
				callback=function(state)
					PartyCastingBars.EnableIcons(state.checked)
				end;
				feedback=function(state)
					if ( state.checked ) then
						return PCB_SHOWNICONFEEDBACK_NEGATIVE;
					else
						return PCB_SHOWNICONFEEDBACK_POSITIVE;
					end
				end;
				check=true;
				type=K_TEXT;
				setup= {						
				};
				default={
					checked=true;
				};
				disabled={
					disabled=false;
				};					
			}
		);
		table.insert(
			optionSet,
			{
				id="PartyMemberFrameParents";
				text=PCB_PARTYMEMBERFRAME_PARENT_TEXT;
				helptext=PCB_PARTYMEMBERFRAME_PARENT_TIP;
				difficulty=3;
				callback=function(state)
					PartyCastingBars.SetParents(state.checked)
				end;
				feedback=function(state)
					if ( state.checked ) then
						return PCB_PARTYMEMBERFRAME_PARENT_NEGATIVE;
					else
						return PCB_PARTYMEMBERFRAME_PARENT_POSITIVE;
					end
				end;
				check=true;
				type=K_TEXT;
				setup= {						
				};
				default={
					checked=true;
				};
				disabled={
					disabled=true;
				};					
			}
		);
		table.insert(
			optionSet,
			{
				id="Draggable";
				text=PCB_DRAGGABLE_TEXT;
				helptext=PCB_DRAGGABLE_TIP;
				difficulty=3;
				callback=function(state)
					PartyCastingBars.EnableDragging(state.checked)
				end;
				feedback=function(state)
					if ( state.checked ) then
						return PCB_DRAGGABLE_NEGATIVE;
					else
						return PCB_DRAGGABLE_POSITIVE;
					end
				end;
				check=true;
				type=K_TEXT;
				setup= {						
				};
				default={
					checked=false;
				};
				disabled={
					disabled=false;
				};					
			}
		);
		table.insert(
			optionSet,
			{
				id="Scale";
				text=PCB_SCALE_TEXT;
				helptext=PCB_SCALE_TIP;
				difficulty=3;
				check=true;
				type=K_SLIDER;
				callback=function(state)
					PartyCastingBars.SetScales(state.slider)
				end;
				feedback=function(state)
					if ( state.checked ) then
						return format(PCB_SCALE_POSITIVE, state.slider);
					else
						return PCB_SCALE_NEGATIVE;
					end
				end;
				setup = {
					sliderMin = .5;
					sliderMax = 2;
					sliderStep = .1;
					sliderText = PCB_SCALE;
				};
				default = {
					checked = false;
					slider = 0.7;
				};
				disabled = {
					checked = false;
					slider = 1;
				};
				dependencies = {
					Scale = {checked=true;};
				};
			}
		);
		table.insert(
			optionSet,
			{
				id="ResetLocations";
				text=PCB_RESET_TEXT;
				helptext=PCB_RESET_TIP;
				difficulty=3;
				callback=PartyCastingBars.ResetBarLocations;
				feedback=function(state)
					return PCB_LOCATIONS_RESET;
				end;
				type=K_BUTTON;
				setup = {
					buttonText=PCB_RESETTEXT;
				};
			}
		);
	
		-- Register for each cast type
		
		local reaction = "FRIENDLY"
		
		table.insert(
			optionSet,
			{
				id=reaction.."Header";
				text=getglobal("PCB_HEADER_"..reaction.."_TEXT");
				helptext=getglobal("PCB_HEADER_"..reaction.."_TIP");
				difficulty=3;
				type=K_HEADER;
			}
		);
		
		for i, castType in ipairs({"CAST","CHANNEL","SUCCESS","FAILURE"}) do 
			local typeString = castType;
			local niceType = Sea.string.capitalizeWords(castType);
			local colorChangeFeedback = function(state)
				return format(PCB_COLOR_CHANGED, colorToString(state.color), typeString );
			end;
			local colorResetFeedback = function(state)
				return format(PCB_COLOR_RESET, colorToString(state.color), typeString );
			end;
			table.insert(
				optionSet,
				{
					id=reaction..typeString.."ColorSetter";
					text=getglobal("PCB_"..typeString.."COLOR_"..reaction.."_SET");
					helptext=getglobal("PCB_"..typeString.."COLOR_SET_TIP");
					difficulty=3;
					callback=function(state)
						if (PartyCastingBars.ColorResetting[reaction][typeString]) then
							state.color = PartyCastingBars.DefaultColors[reaction][typeString];
							PartyCastingBars.ColorResetting[reaction][typeString] = false;
						end
						getglobal("PartyCastingBars_"..reaction)[typeString] = state.color;
					end;
					feedback=colorChangeFeedback;
					type=K_COLORPICKER;
					setup= {
						hasOpacity=false;
					};
					default={
						color=PartyCastingBars.DefaultColors[reaction][castType];
					};
					disabled={
						color=PartyCastingBars.DefaultColors[reaction][castType];
					};					
				}
			);
			table.insert(
				optionSet,
				{
					id=reaction.. typeString.."Reset";
					text=getglobal("PCB_"..typeString.."COLOR_RESET");
					helptext=getglobal("PCB_"..typeString.."COLOR_RESET_TIP");
					difficulty=3;
					callback=function(state)
						PartyCastingBars.ColorResetting[reaction][typeString] = true;
						-- The khaos config's color has to be reset too or else it will just get refreshed
						-- with its state and override any values we change here.
					end;
					feedback=colorResetFeedback;
					type=K_BUTTON;
					setup = {
						buttonText=PCB_RESETTEXT;
					};
				}
			);
		end
		
		local reaction = "HOSTILE"
		
		table.insert(
			optionSet,
			{
				id=reaction.."Header";
				text=getglobal("PCB_HEADER_"..reaction.."_TEXT");
				helptext=getglobal("PCB_HEADER_"..reaction.."_TIP");
				difficulty=3;
				type=K_HEADER;
			}
		);
			
		for i, castType in ipairs({"CAST","CHANNEL","SUCCESS","FAILURE"}) do 
			local typeString = castType;
			local colorChangeFeedback = function(state)
				return format(PCB_COLOR_CHANGED, colorToString(state.color), typeString );
			end;
			local colorResetFeedback = function(state)
				return format(PCB_COLOR_RESET, colorToString(state.color), typeString );
			end;
			table.insert(
				optionSet,
				{
					id=reaction..typeString.."ColorSetter";
					text=getglobal("PCB_"..typeString.."COLOR_"..reaction.."_SET");
					helptext=getglobal("PCB_"..typeString.."COLOR_SET_TIP");
					difficulty=3;
					callback=function(state)
						if (PartyCastingBars.ColorResetting[reaction][typeString]) then
							state.color = PartyCastingBars.DefaultColors[reaction][typeString];
							PartyCastingBars.ColorResetting[reaction][typeString] = false;
						end
						getglobal("PartyCastingBars_"..reaction)[typeString] = state.color;
					end;
					feedback=colorChangeFeedback;
					type=K_COLORPICKER;
					setup= {
						hasOpacity=false;
					};
					default={
						color=PartyCastingBars.DefaultColors[reaction][castType];
					};
					disabled={
						color=PartyCastingBars.DefaultColors[reaction][castType];
					};					
				}
			);
			table.insert(
				optionSet,
				{
					id=reaction..typeString.."Reset";
					text=getglobal("PCB_"..typeString.."COLOR_RESET");
					helptext=getglobal("PCB_"..typeString.."COLOR_RESET_TIP");
					difficulty=3;
					callback=function(state)
						PartyCastingBars.ColorResetting[reaction][typeString] = true;
						-- The khaos config's color has to be reset too or else it will just get refreshed
						-- with its state and override any values we change here.
					end;
					feedback=colorResetFeedback;
					type=K_BUTTON;
					setup = {
						buttonText=PCB_RESETTEXT;
					};
				}
			);
		end
		
		Khaos.registerOptionSet(
			"combat",
			configurationSet
		);			
	else
		
		-- Command System FTW
		PartyCastingBars.EnableToggle(PartyCastingBars_Enabled);
		PartyCastingBars.EnableIcons(PartyCastingBars_IconsEnabled);
		PartyCastingBars.SetParents(PartyCastingBars_Parented);
	
		SlashCmdList["PARTYCASTINGBARS"] = function(msg) 
			local cmd, reaction, typeString = (" "):split(strupper(msg))
			if (cmd == "ENABLE") then
				PartyCastingBars.EnableToggle(true);
				DEFAULT_CHAT_FRAME:AddMessage(PCB_ENABLED,0,1,0);
			elseif (cmd == "DISABLE") then
				PartyCastingBars.EnableToggle(false);
				DEFAULT_CHAT_FRAME:AddMessage(PCB_DISABLED,1,0,0);
			elseif (cmd == "ICON") then
				PartyCastingBars.EnableIcons(not PartyCastingBars_IconsEnabled);
				if (PartyCastingBars_IconsEnabled) then
					DEFAULT_CHAT_FRAME:AddMessage(PCB_SHOWNICONFEEDBACK_POSITIVE,0,1,1);
				else
					DEFAULT_CHAT_FRAME:AddMessage(PCB_SHOWNICONFEEDBACK_NEGATIVE,1,1,0);
				end
			elseif (cmd == "DRAG") then
				PartyCastingBars.EnableDragging(not PartyCastingBars.draggable);
				if (PartyCastingBars.draggable) then
					DEFAULT_CHAT_FRAME:AddMessage(PCB_DRAGGABLE_POSITIVE,0,1,1);
				else
					DEFAULT_CHAT_FRAME:AddMessage(PCB_DRAGGABLE_NEGATIVE,1,1,0);
				end
			elseif (cmd == "PARENT") then
				PartyCastingBars.SetParents(not PartyCastingBars_Parented);
				if (PartyCastingBars_Parented) then
					DEFAULT_CHAT_FRAME:AddMessage(PCB_PARTYMEMBERFRAME_PARENT_POSITIVE,0,1,1);
				else
					DEFAULT_CHAT_FRAME:AddMessage(PCB_PARTYMEMBERFRAME_PARENT_NEGATIVE,1,1,0);
				end
			elseif (cmd == "SET" and reaction and typeString 
			and PartyCastingBars_Colors[reaction] 
			and PartyCastingBars_Colors[reaction][typeString]) then
			
				PartyCastingBars.OpenColorPicker(PartyCastingBars_Colors[reaction][typeString])
				
			elseif (cmd == "RESET" and reaction and typeString
			and PartyCastingBars.DefaultColors[reaction] 
			and PartyCastingBars.DefaultColors[reaction][typeString]) then
			
				PartyCastingBars.ResetBarColor(reaction, typeString)
				
			elseif (cmd == "HELP") then
				DEFAULT_CHAT_FRAME:AddMessage(PCB_HELP1);
				--DEFAULT_CHAT_FRAME:AddMessage(PCB_HELP2);
				DEFAULT_CHAT_FRAME:AddMessage("|c00995555--------|r");
				DEFAULT_CHAT_FRAME:AddMessage(PCB_HELP3);
				DEFAULT_CHAT_FRAME:AddMessage(PCB_HELP4);
				DEFAULT_CHAT_FRAME:AddMessage(PCB_HELP5);
				DEFAULT_CHAT_FRAME:AddMessage(PCB_HELP6);
				DEFAULT_CHAT_FRAME:AddMessage(PCB_HELP7);
			else
				DEFAULT_CHAT_FRAME:AddMessage(PCB_INVALID_COMMAND,.5,.5,.5);
			end
		end;
		
	 	SLASH_PARTYCASTINGBARS1 = "/partycastingbars";
	 	SLASH_PARTYCASTINGBARS2 = "/pcb";
	 	
	end
end

