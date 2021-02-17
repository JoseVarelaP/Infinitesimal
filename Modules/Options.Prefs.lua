return {
	LuaNoteSkins =
	{
		Default = "default",
		UserPref = true,
		OneInRow = true,
		Choices = NOTESKIN:GetNoteSkinNames(),
		Values = NOTESKIN:GetNoteSkinNames(),
		LoadFunction = function(self,list,pn)
			local CurNoteSkin = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin()
			for i,v2 in ipairs(self.Choices) do
				if string.lower(tostring(v2)) == string.lower(tostring(CurNoteSkin)) then
					list[i] = true return
				end
			end
			list[1] = true
		end,
		SaveFunction = function(self,list,pn)
			for i,v2 in ipairs(self.Choices) do
				if list[i] then
					GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred"):NoteSkin(v2)
				end
			end
		end,
	},
	BGAMode =
	{
		UserPref = true,
		Default = 0,
		Choices = { OptionNameString('On'), OptionNameString('20% Cover'), OptionNameString('40% Cover'), OptionNameString('60% Cover'), OptionNameString('80% Cover'), OptionNameString('Off') },
		Values = { 0, 0.2, 0.4, 0.6, 0.8, 1 },
		SaveFunction = function(self,list,pn)
			local PlayerMods = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
			for i,v2 in ipairs(self.Choices) do
				if list[i] then
					PlayerMods:Cover( self.Values[i], 1 )
				end
			end
		end,
	},
	SmartTimings =
	{
		SaveSelections = {"SmartJudgments",LoadModule("Options.SmartJudgeChoices.lua")},
		UserPref = false, -- for now
		Default = TimingModes[1],
		Choices = TimingModes,
		Values = TimingModes
	},
	ProMode =
	{
		UserPref = true,
		Default = "AllowW1_Never",
		Choices = { OptionNameString('Off'), OptionNameString('On') },
		Values = { "AllowW1_Never", "AllowW1_Everywhere" },
		SaveFunction = function(self,list,pn)
			for i,v2 in ipairs(self.Choices) do
				if list[i] then
					PREFSMAN:SetPreference("AllowW1", self.Values[i]);
				end
			end
		end,
	},
	DeviationDisplay =
    {
        UserPref = true,
        Default = false,
        Choices = { OptionNameString('Off'), OptionNameString('On') },
        Values = {false, true}
    },
	MeasureCounter =
    {
        UserPref = true,
        Default = false,
        Choices = { OptionNameString('Off'), OptionNameString('On') },
        Values = {false, true}
    },
}
