----------[Global variables]----------------------------------------------
local GG = Dascore			--Global package
local LL = {}							--Local package
DascoreWin1 = LL
GG.Win1 = LL 							--Local in global package

----------[Local variables]----------------------------------------------
--WINDOWS
LL.winRoot = "DascoreWin1Window"               --Window for list of saved scenarios.
LL.winList = LL.winRoot .. "List"                 --Listbox window for list of saved scenarios.
LL.winChild =  LL.winRoot .. "Options"            --Options (their frame window)
LL.winTemplate = "DascoreWin1WindowTemplate"		--Template window for options(LL.Options.type is added to the end)

--TEXTS
LL.listTitle = L"daScore"
LL.optionsTitle = L"daScore (options)"

--TABLES
LL.Listdata = {}				--Listbox data
LL.Options = {}					--Options for what options should be displayed and how their settings are stored.
--GG.SAVE.Scenario[#]		--Scenario results are saved to this table.
--GG.SAVE.Options				--Option settings are stored here.

----------[Initialization]----------------------------------------------
function LL.OnInitialize()
	CreateWindow(LL.winRoot, false)
	LabelSetText(LL.winRoot .. "TitleBarText", LL.listTitle )
	ButtonSetText(LL.winRoot .. "OptionsButton", L"O" )
	ButtonSetText(LL.winRoot .. "ExtraButton", L"E" )
  ButtonSetTextColor(LL.winRoot .. "ExtraButton", Button.ButtonState.NORMAL, 150, 0, 0)
  ButtonSetTextColor(LL.winRoot .. "ExtraButton", Button.ButtonState.HIGHLIGHTED, 150, 0, 0)

	LL.SetOptions()					--Sets what options to display in options window.
	LL.RefreshList()				--Refresh and show data of saved scenarios.
end


--[[
	To add new options:
		1. Check that there is room in options window. 
		2. Add a new option line below.
	LL.Options[row]	: Options are listed according to the order they are in this table.
	type				 		: Option is displayed based on this type.
	save				 		: Field name used in GG.SAVE which options value is saved. Eg. GG.SAVE.Options.Autosave_eos
	label				 		: Displayed in the options label.
--]]
function LL.SetOptions()
	LL.Options = {}
	table.insert(LL.Options, { type = "checkbox", save = "Autosave_eos", label = L"Autosave (end of scenario)" })
	table.insert(LL.Options, { type = "checkbox", save = "Savelog_default", label = L"Autosave also: daScore log" })
	table.insert(LL.Options, { type = "checkbox", save = "Highlight_player", label = L"Highlight player" })
	table.insert(LL.Options, { type = "checkbox", save = "Delete_rmb", label = L"RMB deletes a result row" })
	if GG.SAVE.Options.Import_done ~= true then	--Import version 1.0 logs
		table.insert(LL.Options, { type = "buttongroup", save = "Import_scoreboard", label = L"Import Scoreboard logs" })
		table.insert(LL.Options, { type = "buttongroup", save = "Import_disable", label = L"Never import Scoreboard logs" })
	end
end

----------[Eventhandlers for window]----------------------------------------------
--Only one eventhandler call for each event. Here we check the calling
--element name and choose what function to use.

--Refresh results list everytime window is opened.
function LL.OnShown()
	LL.RefreshList()
	LL.OptionsWindowToggle(true) --hide options
end

function LL.OnLButtonUp()
	--Close button
	if SystemData.MouseOverWindow.name == LL.winRoot .. "CloseButton" then
		WindowSetShowing(LL.winRoot, false)
		return
	end

	--Options button
	if SystemData.MouseOverWindow.name == LL.winRoot .. "OptionsButton" then
		LL.OptionsWindowToggle()
		return
	end

	--Extra button
	if SystemData.MouseOverWindow.name == LL.winRoot .. "ExtraButton" then
		--Todo: Show this "better" when no results have been yet selected.
		WindowSetShowing(GG.Win2.winRoot, true)
		return
	end
  
	--Result list row selected
  if string.find(SystemData.MouseOverWindow.name, "^" .. LL.winList .. "Row") then
    LL.ShowScore()
		WindowSetShowing(GG.Win2.winRoot, true)
		GG.Win2.MainUpdated()
  end
	
	--Option Checkbox selected
  if string.find(SystemData.MouseOverWindow.name, "^" .. LL.winChild .. "%d" .. "Checkbox") then
		GG.Func.OptionsToggle(LL.winChild, LL.Options)
  end
	
 	--Import button selected
  if string.find(SystemData.MouseOverWindow.name, "^" .. LL.winChild .. "%d+" .. "Buttongroup") then
		GG.Func.OptionsToggle(LL.winChild, LL.Options)  --Toggle import button
		GG.CheckLegacyImport()		--Check what to do with import.
		LL.RefreshList()					--Refresh saved results list.
		LL.OptionsWindowToggle()	--Open saved results list.
		LL.SetOptions()						--Hide import buttons from now on.
  end

end

function LL.OnRButtonUp()
	--Result list row selected
  if string.find(SystemData.MouseOverWindow.name, "^" .. LL.winList .. "Row") then
    if GG.SAVE.Options.Delete_rmb == true then  
      LL.DeleteScore()
			LL.RefreshList()
    end
  end
end

----------[Window functions]----------------------------------------------
--Toggle between list of saved scenarios and options
function LL.OptionsWindowToggle(hide)
	if LabelGetText(LL.winRoot .. "TitleBarText") == LL.optionsTitle
	or hide == true then
		LabelSetText(LL.winRoot .. "TitleBarText", LL.listTitle )
    ButtonSetTextColor(LL.winRoot .. "OptionsButton", Button.ButtonState.NORMAL, 150, 0, 0)
    ButtonSetTextColor(LL.winRoot .. "OptionsButton", Button.ButtonState.HIGHLIGHTED, 150, 0, 0)
		WindowSetShowing(LL.winList, true)
		GG.Func.OptionsHide(LL.winChild, LL.Options)
	else
		LabelSetText(LL.winRoot .. "TitleBarText", LL.optionsTitle )
    ButtonSetTextColor(LL.winRoot .. "OptionsButton", Button.ButtonState.NORMAL, 255, 255, 255)
    ButtonSetTextColor(LL.winRoot .. "OptionsButton", Button.ButtonState.HIGHLIGHTED, 255, 255, 255)
		WindowSetShowing(LL.winList, false)
	  GG.Func.OptionsShow(LL.winRoot, LL.winChild, LL.winTemplate, LL.Options)
	end
		
end

----------[Result list functions]----------------------------------------------
function LL.Show()
	--There can be problems if this addon is active during scenarios.
	if GG.SafeToUpdate(1) == true then
		WindowSetShowing(LL.winRoot, true)
	end
end

--Refresh results list.
function LL.RefreshList()
  local _DisplayOrder = {}
	LL.Listdata = {}
	for k, v in ipairs(GG.SAVE.Scenario) do
		table.insert(_DisplayOrder, k)
		table.insert(LL.Listdata, { Title = GG.Resu.CreateTitle(k) })
	end
	ListBoxSetDisplayOrder(LL.winList, _DisplayOrder)
end

--Open a scenario results window when a row is clicked.
function LL.ShowScore()
	local _index = ListBoxGetDataIndex(LL.winList, WindowGetId(SystemData.MouseOverWindow.name))
	GG.Resu.ScenarioLoad(_index)
end

--Delete a scenario result when a row is clicked.
function LL.DeleteScore()
	local _index = ListBoxGetDataIndex(LL.winList, WindowGetId(SystemData.MouseOverWindow.name))
	GG.Resu.ScenarioDelete(_index)
end
