local Scoring = LoadModule("Config.Load.lua")("ScoringSystem", "Save/OutFoxPrefs.ini") or "Old"
local ClassicGrades = LoadModule("Config.Load.lua")("ClassicGrades", "Save/OutFoxPrefs.ini") and Scoring == "Old"
local SongIsChosen = false

local t = Def.ActorFrame {}

local function CreateFakePSSObject(onlineScoreData)
    local pss = setmetatable({
        GetGrade = function(this)
            return "Grade_Tier05"
        end,
        GetScore = function(this)
            if Scoring == "New" then
                return math.ceil(onlineScoreData.score * 1000001)
            end

            return onlineScoreData.score
        end,
        GetTapNoteScore = function(this, tns)
            local count = onlineScoreData.tapnote_data[tns] or 0
            return count
        end,
        GetMaxCombo = function(this)
            -- Online data doesn't track the max combo value, so we'll just improvise-
            return 10
        end
    },{})

    return pss
end

-- Let's keep a buffer of the online data we have received.
-- Format for this will be:
-- [ChartKey] = {data}
local chartKeyOnlineInfo = {}

for pn in ivalues(GAMESTATE:GetHumanPlayers()) do
    -- Player 2's panel is slightly adjusted, so we need to correct
    -- the positioning of actors so that they fit in properly
    local CorrectionX = pn == PLAYER_2 and -15 or 0
    local isOnlineViewNow = false
    
    t[#t+1] = Def.ActorFrame {
        Def.ActorFrame {
            CurrentChartChangedMessageCommand=function(self, params) if SongIsChosen and params.Player == pn then self:playcommand("Refresh") end end,
            
            SongChosenMessageCommand=function(self)
                SongIsChosen = true
                -- Clean the chartkey table.
                chartKeyOnlineInfo = {}
                self:stoptweening():easeoutexpo(0.5)
                :x(358 * (pn == PLAYER_2 and 1 or -1))
                self:playcommand("Refresh")
            end,
            SongUnchosenMessageCommand=function(self)
                SongIsChosen = false
                self:stoptweening():easeoutexpo(0.5):x(0)
            end,

            RefreshCommand=function(self)
                Song = GAMESTATE:GetCurrentSong()
                Chart = GAMESTATE:GetCurrentSteps(pn)

                -- Personal best score
                if PROFILEMAN:IsPersistentProfile(pn) then
                    ProfileScores = PROFILEMAN:GetProfile(pn):GetHighScoreList(Song, Chart):GetHighScores()

                    if ProfileScores[1] ~= nil then
                        local ProfileScore = ProfileScores[1]:GetScore()
                        local ProfileDP = round(ProfileScores[1]:GetPercentDP() * 100, 2) .. "%"

                        self:GetChild("PersonalGrade"):Load(THEME:GetPathG("", "LetterGrades/" .. (ClassicGrades and "" or "New/") ..
                            LoadModule("PIU/Score.Grading.lua")(ProfileScores[1]))):visible(true)
                        self:GetChild("PersonalScore"):settext(ProfileDP .. "\n" .. ProfileScore)
                    else
                        self:GetChild("PersonalGrade"):visible(false)
                        self:GetChild("PersonalScore"):settext("")
                    end
                else
                    self:GetChild("PersonalGrade"):visible(false)
                    self:GetChild("PersonalScore"):settext("")
                end

                -- Machine best score
                local MachineHighScores = PROFILEMAN:GetMachineProfile():GetHighScoreList(Song, Chart):GetHighScores()
                if MachineHighScores[1] ~= nil then
                    local MachineScore = MachineHighScores[1]:GetScore()
                    local MachineDP = round(MachineHighScores[1]:GetPercentDP() * 100, 2) .. "%"
                    local MachineName = MachineHighScores[1]:GetName()

                    self:GetChild("MachineScore"):GetChild("Grade"):Load(THEME:GetPathG("", "LetterGrades/" .. (ClassicGrades and "" or "New/") ..
                            LoadModule("PIU/Score.Grading.lua")(MachineHighScores[1]))):visible(true)
                    self:GetChild("MachineScore"):GetChild("Score"):settext(MachineName .. "\n" .. MachineDP .. "\n" .. MachineScore)
                else
                    self:GetChild("MachineScore"):GetChild("Grade"):visible(false)
                    self:GetChild("MachineScore"):GetChild("Score"):settext("")
                end

                if not NETMAN and NETMAN:IsConnectionEstablished() then return end

                self:playcommand("Tween")
                -- If we already have the online data cached, then just use that.
                local chartkey = GAMESTATE:GetCurrentSteps(pn):GetChartKey()
                if chartKeyOnlineInfo[chartkey] then
                    self:playcommand("UpdateOnlineInfo",{data = chartKeyOnlineInfo[chartkey]})
                    return
                end

                -- Let's fetch the best score, and put it on a special handle where the Machine Best area is.
                NETMAN:FuncHighScoresForChart{
                    ChartKey = chartkey,
                    Timing = "Original",
                    Rate = GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate(),
                    PlayerNumber = pn,
                    OnResponse = function (data)
                        if not data.response.scores or #data.response.scores == 0 then
                            self:GetChild("OnlineScore"):GetChild("Grade"):visible(false)
                            self:GetChild("OnlineScore"):GetChild("Score"):settext("")
                            return
                        end

                        chartKeyOnlineInfo[GAMESTATE:GetCurrentSteps(pn):GetChartKey()] = onlinescore

                        self:playcommand("UpdateOnlineInfo",{data = data.response.scores[1]})
                    end,
                    OnFail = function () end
                }

            end,

            UpdateOnlineInfoCommand=function(self,params)
                local onlineScore = params.data
                local score = CreateFakePSSObject(onlineScore)

                self:GetChild("OnlineScore"):GetChild("Grade"):Load(THEME:GetPathG("", "LetterGrades/" .. (ClassicGrades and "" or "New/") ..
                    LoadModule("PIU/Score.Grading.lua")(score))):visible(true)

                local scoreName = onlineScore.username
                local dp = round(onlineScore.score * 100, 2) .. "%"
                local scr = round(score:GetScore()*1000000, 2)
                self:GetChild("OnlineScore"):GetChild("Score"):settext(scoreName .. "\n" .. dp .. "\n" .. scr)
            end,

            Def.Sprite {
                -- Texture=THEME:GetPathG("", "UI/ScoreDisplay"),
                InitCommand=function(self)
                    self:Load(THEME:GetPathG("", "UI/ScoreDisplay" .. ToEnumShortString(pn)))
                    :xy(0, 0):zoom(0.75)
                end,
            },
            
            Def.Sprite {
                Name="PersonalGrade",
                InitCommand=function(self)
                    self:xy(-40 + CorrectionX, -35):zoom(0.2)
                end,
            },

            Def.BitmapText {
                Name="PersonalScore",
                Font="Common normal",
                InitCommand=function(self)
                    self:xy(90 + CorrectionX, -35):zoom(1):halign(1)
                    :diffuse(Color.White):vertspacing(-6):shadowlength(1)
                end,
            },
            
            Def.ActorFrame{
                Name="MachineScore",
                TweenCommand=function(self)    
                    isOnlineViewNow = not isOnlineViewNow
                    self:stoptweening():linear(0.2):diffusealpha( isOnlineViewNow and 0 or 1 )
                    :sleep(1):queuecommand("Tween")
                end,
                Def.Sprite {
                    Name="Grade",
                    InitCommand=function(self)
                        self:xy(-40 + CorrectionX, 60):zoom(0.2)
                    end,
                },

                Def.BitmapText {
                    Name="Score",
                    Font="Common normal",
                    InitCommand=function(self)
                        self:xy(90 + CorrectionX, 60):zoom(1):halign(1)
                        :diffuse(Color.White):vertspacing(-6):shadowlength(1)
                    end,
                },
            },

            Def.ActorFrame{
                Name="OnlineScore",
                Condition=NETMAN and NETMAN:IsConnectionEstablished(),
                TweenCommand=function(self)
                    self:stoptweening():linear(0.2):diffusealpha( isOnlineViewNow and 1 or 0 )
                    :sleep(1):queuecommand("Tween")
                end,
                Def.Sprite {
                    Name="Grade",
                    InitCommand=function(self)
                        self:xy(-40 + CorrectionX, 60):zoom(0.2)
                    end,
                },

                Def.BitmapText {
                    Name="Score",
                    Font="Common normal",
                    InitCommand=function(self)
                        self:xy(90 + CorrectionX, 60):zoom(1):halign(1)
                        :diffuse(Color.White):vertspacing(-6):shadowlength(1)
                    end,
                },
            }
        }
    }
end

return t
