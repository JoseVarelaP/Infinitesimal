local bPlayer = Var "Player";

local function getNumberOfElements(t)
	local count = 0;
	if t then
		for index in pairs(t) do
			count = count + 1;
		end;
	end;
	return count;
end

	-- K-Pump scoring system - SheepyChris
local TapNoteScorePoints = {
	TapNoteScore_CheckpointHit = 1000;	-- HOLD PERFECT
	TapNoteScore_W1 = 1200;				-- SUPERB
	TapNoteScore_W2 = 1000;				-- PERFECT
	TapNoteScore_W3 = 500;				-- GREAT
	TapNoteScore_W4 = 100;				-- GOOD
	TapNoteScore_W5 = -200;				-- BAD
	TapNoteScore_Miss = -500;			-- MISS
	TapNoteScore_CheckpointMiss = -300;	-- HOLD MISS
	TapNoteScore_None =	0;
	TapNoteScore_HitMine = 0;
	TapNoteScore_AvoidMine = 0;
};

local PlayerScore = 300000;
local LevelConstant = 1;
local GradeBonus = 300000;
local CurrentCombo = 0;

return Def.ActorFrame {
	InitCommand=function(self)
		local StepData = GAMESTATE:GetCurrentSteps(bPlayer);
		local StepLevel = StepData:GetMeter();
		local StepType = StepData:GetStepsType();
		local Window = tonumber(string.format("%.6f", PREFSMAN:GetPreference("TimingWindowSecondsW5")));
		
		-- level constant: the multipler utilized to increase scores with more difficult charts and doubles
		if (StepType == "StepsType_Pump_Double" or 
			StepType == "StepsType_Pump_Halfdouble" or 
			StepType == "StepsType_Pump_Routine") then
			if StepLevel > 10 then
				LevelConstant = (StepLevel / 10) * 1.2
			else
				LevelConstant = 1.2
			end;
		else
			if StepLevel > 10 then
				LevelConstant = StepLevel / 10
			end;
		end;
		
		if Window == 0.129166 then -- VJ
			LevelConstant = LevelConstant * 1.2
		end
	end;
	JudgmentMessageCommand=function(self,params)
		local Notes = {};
		local Holds = {};
		local iStepsCount = 0;
		local TapNote = params.TapNote;
		local TapNoteScore = params.TapNoteScore;
		
		local Player = params.Player;
		local State = GAMESTATE:GetPlayerState(Player);
		
		local CSS = STATSMAN:GetCurStageStats();
		local PSS = CSS:GetPlayerStageStats(Player);
		
		local iGreats 	= 	PSS:GetTapNoteScores("TapNoteScore_W3");
		local iGoods 	= 	PSS:GetTapNoteScores("TapNoteScore_W4");
		local iBads 	= 	PSS:GetTapNoteScores("TapNoteScore_W5");
		local iMisses 	= 	PSS:GetTapNoteScores("TapNoteScore_Miss") +
							PSS:GetTapNoteScores("TapNoteScore_CheckpointMiss");
		
		-- now we can safely calculate the number of arrows in this tapnote
		Holds = params.Holds;
		Notes = params.Notes;
		iStepsCount = getNumberOfElements(Holds) + getNumberOfElements(Notes);
		
		-- this engine is so unbelievably broken that I had to rewrite the combo system.
		-- shoutouts to all of the devs that have only cared about dance for years!
		if TapNote and TapNote:GetTapNoteType() ~= "TapNoteType_HoldTail" then -- more hacks, hooray!
			CurrentCombo = CurrentCombo;
		else
			if (TapNoteScore <= "TapNoteScore_W3" and TapNoteScore >= "TapNoteScore_W1") or TapNoteScore == "TapNoteScore_CheckpointHit" then
				CurrentCombo = CurrentCombo + 1;
			else
				CurrentCombo = 0;
			end;
		end;
		
		-- grade bonus: remove the previous value and reevaluate it
		PlayerScore = PlayerScore - GradeBonus;

		if iMisses > 0 then
			GradeBonus = 0;
		elseif iBads > 0 or iGoods > 0 then
			GradeBonus = 100000;
		elseif iGreats > 0 then
			GradeBonus = 150000;
		end;

		-- combo score: self explanatory tbh
		local ComboScore = 0;
		if CurrentCombo > 50 and TapNoteScore <= "TapNoteScore_W3" then
			ComboScore = 1000;
		end;

		-- note score: same with here I guess
		local NoteScore = TapNoteScorePoints[TapNoteScore] + ComboScore;
		if iStepsCount > 2 then
			NoteScore = NoteScore * 1.5;
		elseif iStepsCount >= 4 then
			NoteScore = NoteScore * 2;
		end;

		-- !!! hack: removes extra combo/score count from the end of hold arrows !!!
		if TapNote and TapNote:GetTapNoteType() ~= "TapNoteType_HoldTail" then
			PlayerScore = PlayerScore + GradeBonus;
		else
			PlayerScore = PlayerScore + (NoteScore * LevelConstant) + GradeBonus;
		end;
		
		-- we don't want negative scores
		if PlayerScore < 0 then
			PlayerScore = 0;
		end;
		
		PSS:SetScore(PlayerScore - (PlayerScore % 100));
		--SCREENMAN:SystemMessage(PlayerScore-(PlayerScore%100).." - "..NoteScore-ComboScore.." - "..ComboScore.." - "..CurrentCombo.." - "..LevelConstant.." - "..GradeBonus);
	end;
};
