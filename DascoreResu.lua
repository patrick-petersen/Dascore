----------[Global variables]----------------------------------------------
local GG = Dascore			--Global package
local LL = {}							--Local package
DascoreResu = LL
GG.Resu = LL 							--Local in global package

----------[Local variables]----------------------------------------------
--TABLES
--GG.SAVE.Scenario[#]		--Scenario results are saved to this table.
--GG.selected_scenario	--Currently selected saved scenario result index number.

----------[Scenario results data functions]----------------------------------------------
--Save currently open scenario results.
--At SCENARIO_END event some of the data is already gone from the system. That's why we get it from the ScenarioSummaryWindow.
function LL.ScenarioSave()
	table.insert(GG.SAVE.Scenario, 1, {}) --Put the new result on top of the save table.
	GG.Func.CopyTable(ScenarioSummaryWindow.playersData, GG.SAVE.Scenario[1]) --Save scenario data.
  LL.AddCareerId(1)
	GG.SAVE.Scenario[1].player = GameData.Player.name
	GG.SAVE.Scenario[1].server = GameData.Account.ServerName
	GG.SAVE.Scenario[1].name = LabelGetText("ScenarioSummaryWindowScenarioName")
	GG.SAVE.Scenario[1].date = GG.Func.CreateDate()
	GG.SAVE.Scenario[1].orderPoints = LabelGetText("ScenarioSummaryWindowOrderPoints")
	GG.SAVE.Scenario[1].destructionPoints = LabelGetText("ScenarioSummaryWindowDestructionPoints")
	
	GG.Win1.RefreshList() --Refresh the results list to show this new entry.

	EA_ChatWindow.Print(L"Scenario results saved: " .. LL.CreateTitle(1))
end

--CareerId is not stored in ScenarioSummaryWindow.playersData, but created by GameData.GetScenarioPlayers.
--CareerId is used to create CareerIconId which is then saved to ScenarioSummaryWindow.playersData.
--Here we reverse the process and create CareerId from CareerIconId.
function LL.AddCareerId(index)
  	for k,v in pairs(GG.SAVE.Scenario[index]) do
   		if type (GG.SAVE.Scenario[index][k]) == "table" then
        if v.careerIcon ~= nil then
          GG.SAVE.Scenario[index][k].careerId = LL.GetCareerId(v.careerIcon)
        end
      end
    end
end

function LL.GetCareerId(CareerIconId)
  for k, v in pairs(Icons.careers) do
    if v == CareerIconId  then
      return k
    end
  end
end

function LL.ScenarioDelete(index)
  if index == nil then
    return
  end
	table.remove(GG.SAVE.Scenario, index)
end

function LL.CreateTitle(index)
	local player = GG.SAVE.Scenario[index].player
	local name = GG.SAVE.Scenario[index].name
	local date = GG.SAVE.Scenario[index].date
	return player .. L":" .. name .. L" (" .. date .. L")"
end

----------[Importing functions]----------------------------------------------
--Import external logs data to scenario data
function LL.ImportLog(scenario, logName, ImportLog)
  if scenario == nil --Normally we do this with the newest scenario (=1)
  or logName == nil
  or ImportLog == nil then
    return
  end
  logName = string.lower(logName)
  
	for kScenario, vPlayer in ipairs(GG.SAVE.Scenario[scenario]) do
    local _name = GG.Func.GetName(vPlayer.name)
    if ImportLog[_name] ~= nil then
      vPlayer[logName] = {}
      for kStat, vValue in pairs(ImportLog[_name]) do
        vPlayer[logName][kStat] = vValue
      end
    end
  end
end

----------[Scenario results window functions]----------------------------------------------
--Load selected scenario data and display it on the scenario results screen.
function LL.ScenarioLoad(index)
  ScenarioSummaryWindow.SelectedPlayerDataIndex = 0 --Clear highlighted player selection.
  GG.selected_scenario = index             --This value is used by the GetScenarioPlayers-hook.
 	WindowSetShowing("ScenarioSummaryWindow", true)
  WindowClearAnchors("ScenarioSummaryWindow")
  WindowAddAnchor("ScenarioSummaryWindow", "left", "Root", "left", 0, 0)
  ScenarioSummaryWindow.OnPlayerListUpdated()    --Show player data.
	ScenarioSummaryWindow.OnUpdateScenarioPoints() --Show total kills and damage.
	LabelSetText( "ScenarioSummaryWindowScenarioName", LL.CreateTitle(index) )
	LabelSetText( "ScenarioSummaryWindowOrderPoints", towstring(GG.SAVE.Scenario[index].orderPoints)  )
	LabelSetText( "ScenarioSummaryWindowDestructionPoints", towstring(GG.SAVE.Scenario[index].destructionPoints) )
  if GG.SAVE.Options.Highlight_player == true then
    LL.HighlightPlayer(GG.SAVE.Scenario[index].player)
  end
end

--Highlights the player who played the scenario in scenario summary window.
function LL.HighlightPlayer(name)
  for k, v in ipairs( ScenarioSummaryWindow.playersData ) do
		if name == v.name then	--v.name is in format name^M  M=gender
			ScenarioSummaryWindow.SelectedPlayerDataIndex = k
		end
	end
  ScenarioSummaryWindow.UpdatePlayerRow()    --Show player data.
end
