function SetPlayMode()
    GAMESTATE:SetCurrentPlayMode("PlayMode_Regular");
    GAMESTATE:SetCurrentStyle("Single");
    return "ScreenSelectPlayMode"
end;

--Adds commas to your score, apparently
function scorecap(n) -- credit http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(,-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end;

function GetChartType(player)
	if GAMESTATE:GetCurrentSteps(player) then
		local stepType = GAMESTATE:GetCurrentSteps(player):GetStepsType();
		local stepDescription = GAMESTATE:GetCurrentSteps(player):GetDescription();
		local stepLevel = GAMESTATE:GetCurrentSteps(player):GetMeter();

		if stepType ~= nil then
			if stepType == "StepsType_Pump_Single" then
				if string.find(stepDescription, "SP") then
					return "Single P.";
				else
					return "Single";
				end;
			elseif stepType == "StepsType_Pump_Halfdouble" then
				return "Half-Double";
			elseif stepType == "StepsType_Pump_Double" then
				--Check for StepF2 Double Performance tag
				if string.find(stepDescription, "DP") then
					return "Double P.";
				else
					return "Double";
				end;
			elseif stepType == "StepsType_Pump_Couple" then
				return "Couple";
			elseif stepType == "StepsType_Pump_Routine" then
				return "Routine";
			end;
		end;
	end;
end;
