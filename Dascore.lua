--[[
	This addon is for Warhammer Online. It saves and displays Scenario results.
	It also supports importing custom stats. Default customs stats are included,
	but other addons can create their own stats and display them with this addon.
--]]

----------[Global variables]----------------------------------------------
--ATTN: At this stage this addon is NOT SUPPOSE BE WORKING DURING SCENARIOS.
local GG = {}
Dascore = GG		--Global package

--TABLES
--GG.SAVE = DascoreSavedVariables	--These values are saved between game sessions.
--GG.SAVE.Scenario[#]		--Scenario results are saved to this table.
--GG.SAVE.Options				--Option settings are stored here.
--GG.selected_scenario	--Currently selected saved scenario result index number.
--GG.ExportLog          --Custom log stats ready to be imported.
--GG.SafeToUpdate()			--(function) Checks is it safe to use scenario stats.

----------[Initialization]----------------------------------------------
function GG.OnInitialize()
  RegisterEventHandler(SystemData.Events.SCENARIO_BEGIN , "Dascore.SCENARIO_BEGIN")
  RegisterEventHandler(SystemData.Events.SCENARIO_END , "Dascore.SCENARIO_END")
  RegisterEventHandler(SystemData.Events.R_BUTTON_UP_PROCESSED,"Dascore.R_BUTTON_UP_PROCESSED")
  RegisterEventHandler(SystemData.Events.L_BUTTON_UP_PROCESSED,"Dascore.L_BUTTON_UP_PROCESSED")
	
	GG.Hooks()
				
	if DascoreSavedVariables == nil then
		GG.Reset()
	end
	GG.SAVE = DascoreSavedVariables
	GG.CheckLegacyImport()
	
	EA_ChatWindow.Print(L"daScore-addon loaded")
	
--There is optional support for LibSlash-addon in the Dascore_LibSlash.mod file.
--If LibSlash-addon is found then also the /dascore command becomes available.

end

----------[Eventhandlers for global events]----------------------------------------------
function GG.SCENARIO_BEGIN()
  if GG.SAVE.Options.Autosave_eos == true then
		--This addon can't be used during scenarios so hide the windows.
		WindowSetShowing(GG.Win1.winRoot, false)
		WindowSetShowing(GG.Win2.winRoot, false)
		GG.selected_scenario = nil 									--Free scenario results database for system.
		if GG.SAVE.Options.Savelog_default == true then
			GG.Pars.ParserGetTimestamp("begin") 			--Set begin timestamp for combat log parsing.
		end
	end
end

function GG.SCENARIO_END()
  if GG.SAVE.Options.Autosave_eos == true then
  	GG.Resu.ScenarioSave()											--Save default scenario results.
		if GG.SAVE.Options.Savelog_default == true then
			GG.Pars.ParserGetTimestamp("end")	 				--Set begin timestamp for combat log parsing.
			GG.Pars.ParserSave()											--Parse combat events and create export table.
			GG.Resu.ImportLog(1, "dascore", GG.ExportLog)	--Import "default log" stats from export table.
		end
  end
end

function GG.R_BUTTON_UP_PROCESSED()
	if GG.SafeToUpdate(1) == false then
		return
	end
	if SystemData.MouseOverWindow.name == "EA_Window_OverheadMapMapScenarioQueue" then
    GG.ScenarioQueueButton()
	end
end

function GG.L_BUTTON_UP_PROCESSED()
	if GG.SafeToUpdate() == false then
		return
	end
	if string.find(SystemData.MouseOverWindow.name, "ScenarioSummaryWindowClose") then
		WindowSetShowing(GG.Win2.winRoot, false)
		return
	end
	if string.find(SystemData.MouseOverWindow.name, "^ScenarioSummaryWindowPlayerListHeader") then
		GG.Win2.SortReset()	--Clear custom sort order
	end
	if string.find(SystemData.MouseOverWindow.name, "^ScenarioSummaryWindow") then
		GG.Win2.MainUpdated()
	end
end

----------[Hooks]----------------------------------------------
function GG.Hooks()
	GG.Hook_GameData_GetScenarioPlayers = GameData.GetScenarioPlayers
	GameData.GetScenarioPlayers = GG.GetScenarioPlayers
end

--Original function would retrieve an empty results set since we are not in scenario.
function GG.GetScenarioPlayers(...)
	d("calling FixScenarioStats")
	if GG.SafeToUpdate() == true then
		return GG.FixScenarioStatsTemporaryFix(GG.SAVE.Scenario[GG.selected_scenario])
	else
		return GG.Hook_GameData_GetScenarioPlayers(...)
  end
end

--Temporary fix for new mitigation & MMR stats
function GG.FixScenarioStatsTemporaryFix(stats)
	d("calling FixScenarioStatsTemporaryFix")
	local stats_copy = {}
	GG.Func.CopyTable(stats, stats_copy)
	for k, v in ipairs(stats_copy) do
		--old stats = new stat in that position
		--solokills = protection
		--experience = objectivescore
		--renown = mmr
		d("stats[" .. k .."]: ", v, "------------------------")

		if(v["protection"]  ~= nil ) then
			d("adding protection")
			v["old_solokills"]=v["solokills"]
			v["solokills"]=v["protection"]
		end

		if(v["objectivescore"] ~= nil ) then
			d("adding objectivescore")
			v["old_experience"]=v["experience"]
			v["experience"]=v["objectivescore"]
		end

		if(v["mmr"] ~= nil ) then
			d("adding mmr")
			v["old_renown"]=v["renown"]
			v["renown"]=v["mmr"]
		end
	end
	d(stats_copy)
	return stats_copy
end

----------[Scenario queue button functions]----------------------------------------------
--Add button to the scenario queue context menu
function GG.ScenarioQueueButton()
	local _Data = GetScenarioQueueData()
	if _Data == nil or _Data.totalQueuedScenarios == 0 then
		--If scenario queue is empty then we have to first empty the list from old entries.
		EA_Window_ContextMenu.CreateContextMenu("EA_Window_OverheadMapMapScenarioQueue" )
	end
	
	if (EA_Window_ContextMenu.activeWindow == "EA_Window_OverheadMapMapScenarioQueue") then
		EA_Window_ContextMenu.AddMenuItem(L"daScore", GG.Win1.Show, false, true) 
		EA_Window_ContextMenu.Finalize()
	end
end

----------[Misc functions]----------------------------------------------
--ATTN: At this stage this addon is NOT SUPPOSE BE WORKING DURING SCENARIOS.
--Scenario results window is only updated if "not in scenario" and
--"results list window is open".
function GG.SafeToUpdate(onlyOpenWin)
	if GameData.Player.isInScenario == false then
		if onlyOpenWin ~= nil		--Asking if safe to open results list window
		or WindowGetShowing(GG.Win1.winRoot) == true then
			return true
		end
	end
	return false
end

function GG.CheckLegacyImport()
	if GG.SAVE.Options.Import_done == true then
		return
	end
	if Scoreboard == nil then
		GG.SAVE.Options.Import_done = true
	end
	if GG.SAVE.Options.Import_scoreboard ~= nil then
		if ScoreboardSavedVariables ~= nil then
			GG.Func.CopyTable(ScoreboardSavedVariables.Scenario, GG.SAVE.Scenario)
		end
		EA_ChatWindow.Print(L"daScore-addon: Old results imported from Scoreboard to daScore.")
		GG.SAVE.Options.Import_done = true
	elseif GG.SAVE.Options.Import_disable ~= nil then
		EA_ChatWindow.Print(L"daScore-addon: Old results will never be imported from Scoreboard.")
		GG.SAVE.Options.Import_done = true
	end
end

function GG.Reset()
	DascoreSavedVariables = {}
	DascoreSavedVariables.Scenario = {}
	DascoreSavedVariables.Options = {}
	DascoreSavedVariables.Options.Autosave_eos = true
	DascoreSavedVariables.Options.Savelog_default = true
	DascoreSavedVariables.Options.Highlight_player = true
	DascoreSavedVariables.Options.Delete_rmb = false
	DascoreSavedVariables.Options.Import_done = false
end

--[[
	Here are documentation about naming methods used in this addon and other things.
	
	Naming methods:
		Filenames								= AddonPack .lua .xml					(starts with addon name then package name, capitalized)
		Global package 					= GG													(word "GG")
		Local package	 					= LL													(word "LL")
		Local package in global = GG.Name											(sub object in global, capitalized)
		Tables				 					= TableName										(all words capitalized)
		Variables			 					= variableName								(first word lowercase, rest of words capitalized)
		function locals 				= _variableName, _TableName 	(start with underscore)
		function imports				= variableName, TableName 		(same as normal)
		XML main windows	  		= AddonPackWindow							(starts with addon name then package name then word "Window", capitalized)
		XML sub elements				= AddonPackWindowElementName	(starts with main window then element name, capitalized)
		
	Other notes:
		-Each file contains specific function groups. ("general functions", "one window", "one task")
		-Main file should have all things related to main programs general functions. (eventhandlers, hooks, outside addon declarations)
--]]