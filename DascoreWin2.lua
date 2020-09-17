----------[Global variables]----------------------------------------------
local GG = Dascore			--Global package
local LL = {}							--Local package
DascoreWin2 = LL
GG.Win2 = LL 							--Local in global package

----------[Local variables]----------------------------------------------
--WINDOWS
LL.winRoot = "DascoreWin2Window"               --Window for extra scenario stats
LL.winChild = LL.winRoot .. "Options"             --Stat selection buttons (their frame window)
LL.winList = LL.winRoot .. "PlayerList"           --ListBox window for stat
LL.winTemplate = LL.winRoot .. "Template"		      --Template window for options(LL.Options.type is added to the end)
LL.winHeader = LL.winRoot .. "Header"             --Header sort button (their frame window)
LL.winTemplateHeader = LL.winRoot .. "TemplateSortButton" --Template for header sort buttons
LL.winHeaderUp = LL.winRoot .. "HeaderUp"         --Up arrow for header sort buttons
LL.winHeaderDown = LL.winRoot .. "HeaderDown"     --Down arrow for header sort buttons

--TEXTS
LL.winRootTitle = L"daScore"

--TABLES
LL.List = {}                                      --Options for how and what stats should be displayed.
LL.Options = {}                                   --Options for what label buttons should be displayed.
LL.playersData = {}                               --Listbox data
DascoreWin2WindowPlayerList = {}               --This has to be initialised here so that we can link to it.
LL.ListBoxData = DascoreWin2WindowPlayerList   --ListBox sort order info
--GG.SAVE.Scenario[#]		                          --Scenario results are saved to this table.
--GG.selected_scenario	                          --Currently selected saved scenario result index number.
--GG.SAVE.Options[LL.Options[1].save]             --Label button selection is stored here.

----------[Initialization]----------------------------------------------
function LL.OnInitialize()
	CreateWindow(LL.winRoot, false)
	LabelSetText(LL.winRoot .. "TitleBarText", LL.winRootTitle)
	WindowSetShowing(LL.winRoot, false)

  LL.ListSetOptions()   --These options define which stats are displayd in this window.
  LL.ListSetWidth()     --Sets column widths in listbox.

  LL.HeadersSetOptions()              --Init label buttons.
  LL.HeadersCreateLabelButtons()      --Create header label buttons according to options.
  LL.HeadersCreateSortButtons()       --Create header sort buttons according to options.
  GG.SAVE.Options[LL.Options[1].save] = nil --Clear selected label button.
  
--	GG.Func.OptionsSetWindowDimensions(LL.winRoot, LL.Options) --Adjust extra window according to displayd stats.
end

--Todo: options document
--[[
  Stats are display dynamically based on these options. It's possible to display stats from different log imports.
  To be able to display a custom stat then these steps have to be succesful.
    1. Create log-table for one scenario with a custom parser. (This can be a different addon completely.)
    2. Import that log-table to this addon. (This procedure is not really ready yet.)
    3. Add a row to LL.List table for every stat you wish to display.
    
    4. Nothing else! Just remember that for every scenario you wish to see these stats, then stats have to be
       imported at the time that scenario ends.
  
  LL.List[row]  : Stats are listed according to the order they are in this table. Maximum of 9 rows/"displayed stats".
  log           : (tablename) When logs are imported then they are saved with this table name.
  field         : (fieldname) When logs are imported then they are saved with this field name. 
  title         : This is displayed in the label button.
  width         : Columns are automaticly adjusted according to this value.
  
--]]
function LL.ListSetOptions()
  LL.List = {}
  table.insert(LL.List, { log = "dascore",        field = "z",              title = "Name", width = 160})  --This field has to be 1st!
  table.insert(LL.List, { log = "dascore",        field = "healbyyou",      title = "You healed others", width = 60})
  table.insert(LL.List, { log = "dascore",        field = "healtoyou",      title = "Others healed you", width = 60})
  table.insert(LL.List, { log = "dascore",        field = "damagetoyou",    title = "Others damaged you", width = 120})
  table.insert(LL.List, { log = "dascore",        field = "mitigatetoyou",  title = "You mitigated damage", width = 60})
  table.insert(LL.List, { log = "dascore",        field = "damagebyyou",    title = "You damaged others", width = 120})
  table.insert(LL.List, { log = "dascore",        field = "mitigatebyyou",  title = "Others mitigated damage", width = 60})
  --MAX 9 rows!
  
  --Add order number
  for k, v in ipairs(LL.List) do
    v.title = k .. ". " .. v.title
  end
end

function LL.HeadersSetOptions()
  LL.Options = {}
  for k, v in ipairs(LL.List) do
    LL.Options[k] = { type = "buttongroup", save = "buttongroup_header1", label = towstring(v.title) }
  end
end

----------[Eventhandlers for window]----------------------------------------------
--Only one eventhandler call for each event. Here we check the calling
--element name and choose what function to use.

function LL.OnShown()
    WindowClearAnchors(LL.winRoot)
    if DoesWindowExist("ScenarioSummaryWindowPlayerListBackground") then
      WindowAddAnchor(LL.winRoot, "topright", "ScenarioSummaryWindowBackground", "topleft", 0, 0)
    end
end

function LL.OnLButtonUp()
	--Close button
	if SystemData.MouseOverWindow.name == LL.winRoot .. "CloseButton" then
		WindowSetShowing(LL.winRoot, false)
		return
	end

 	--Label button selected
  if string.find(SystemData.MouseOverWindow.name, "^" .. LL.winChild .. "%d+") then
		GG.Func.OptionsToggle(LL.winChild, LL.Options)  --Toggle label button
    LL.SortOrderToggle()                            --Set sort flag
    LL.HeadersSortIcon()                            --Toggle sort button
    LL.Sort()                                       --Sort rows
  end

 	--Sort button selected
  if string.find(SystemData.MouseOverWindow.name, "^" .. LL.winHeader .. "%d+") then
    LL.HeadersButtonPressed()                       --Toggle label button
    LL.SortOrderToggle()                            --Set sort flag
    LL.HeadersSortIcon()                            --Toggle sort button
    LL.Sort()                                       --Sort rows
  end

end

function LL.OnRButtonUp()
end

----------[Player list window functions]----------------------------------------------
--This is called when ScenarioSummaryWindow is updated.
function LL.MainUpdated()
    LL.ListRefresh()   --Refresh extra window data and sort according to main window.
		LL.Sort()          --If custom sort selected then sort according to extra window.
end

--Update row colors
function LL.UpdatePlayerRow()
  if (LL.ListBoxData.PopulatorIndices ~= nil) then				
    for k, v in ipairs(LL.ListBoxData.PopulatorIndices) do
      local _RowColor, _rowName
      if(GG.SAVE.Scenario[GG.selected_scenario][v].realm == GameData.Realm.ORDER) then
        _RowColor = {r=12, g=47, b=158}
      else
        _RowColor = {r=158, g=12, b=13}
      end
      _rowName = LL.winList .. "Row" .. k .. "Background"
      --Update row color
      WindowSetTintColor(_rowName, _RowColor.r, _RowColor.g, _RowColor.b)
      WindowSetAlpha(_rowName, 0.2)
      --Highlight player selected in the original result window
      if (v == ScenarioSummaryWindow.SelectedPlayerDataIndex) then
          WindowSetShowing(LL.winList .. "Row" .. k .. "SelectionBorder", true)
      else				
          WindowSetShowing(LL.winList .. "Row" .. k .. "SelectionBorder", false)
      end      
    end
  end  
end


----------[Player list header functions]----------------------------------------------
function LL.HeadersCreateLabelButtons()
    GG.Func.OptionsHide(LL.winChild, LL.Options)
	  GG.Func.OptionsShow(LL.winRoot, LL.winChild, LL.winTemplate, LL.Options)
    WindowClearAnchors(LL.winChild .. "5")
    WindowAddAnchor(LL.winChild .. "5", "bottomleft", LL.winRoot .. "TitleBar", "topleft", 350, 20)
end

function LL.HeadersCreateSortButtons()
  for k, v in pairs(LL.List) do
		CreateWindowFromTemplate(LL.winHeader .. k, LL.winTemplateHeader, LL.winRoot)
		if k == 1 then --first option is name
			WindowAddAnchor(LL.winHeader .. k, "topleft", LL.winList .. "Row1Col" .. k, "bottomleft", 0, 0)
		else
			WindowAddAnchor(LL.winHeader .. k, "topright", LL.winList .. "Row1Col" .. k, "bottomright", 0, 0)
		end
    ButtonSetText(LL.winHeader .. k .. "Button",  L"<" .. towstring(k) .. L">" )
	end		
end

-- Displays the clicked sort button as pressed down and positions an arrow above it,
function LL.HeadersSortIcon()
  local _col, _window
  WindowSetShowing( LL.winHeaderUp, false )
  WindowSetShowing( LL.winHeaderDown, false )
  if GG.SAVE.Options[LL.Options[1].save] == nil then
    return
  end

  _col = tonumber(GG.SAVE.Options[LL.Options[1].save])
  if LL.sortOrder == "down" then
    _window = LL.winHeaderDown
  else
    _window = LL.winHeaderUp
  end
  
  WindowSetShowing(_window, true)
  WindowClearAnchors(_window)
  WindowAddAnchor(_window, "topright", LL.winHeader .. _col .."Button", "bottom", -18, 0 )
  
  --Hide main window sort arrows
  WindowSetShowing( "ScenarioSummaryWindowPlayerListHeaderUpArrow", false )
  WindowSetShowing( "ScenarioSummaryWindowPlayerListHeaderDownArrow", false )

end

--Update label button when sor button pressed.
function LL.HeadersButtonPressed()
  local _, _, _col = string.find(SystemData.MouseOverWindow.name, "^" .. LL.winHeader .. "(%d+)")
  GG.SAVE.Options[LL.Options[1].save] = tonumber(_col)  --Todo: make this session only save
  GG.Func.OptionsLoad(LL.winChild, LL.Options)
end

----------[Player list functions]----------------------------------------------
--Sets column widths in listbox according to options
function LL.ListSetWidth(colNum)
  local _col, _row, _width
  if colNum == nil then --If no col given then loop through all columns
    _col = 1
    while DoesWindowExist(LL.winList .. "Row1Col" .. _col) do
      LL.ListSetWidth(_col)
      _col = _col + 1
    end
    return
  end
  
  --Set width
  _row = 1
  while DoesWindowExist(LL.winList .. "Row" .. _row .. "Col" .. colNum) do
    _width = 0
    if LL.List[colNum] ~= nil then
      _width = LL.List[colNum].width
    end
    WindowSetDimensions(LL.winList .. "Row" .. _row .. "Col" .. colNum, _width, 26)
    _row = _row + 1
  end

end

--Get the data for extra window
function LL.ListRefresh()
	LL.playersData = {}
	for kPlayer, vPlayer in ipairs(GG.SAVE.Scenario[GG.selected_scenario]) do
    local _Player = {}
    for kCol, vCol in ipairs(LL.List) do
      if kCol == 1 then
        _Player["col" .. kCol] = vPlayer.name
      else
        if vPlayer[vCol.log] == nil then  --No such log exist for this scenario 
          _Player["col" .. kCol] = 0
        else
          _Player["col" .. kCol] = vPlayer[vCol.log][vCol.field]
        end
      end
    end
    table.insert(LL.playersData, _Player)
	end

  --We want to be in sync with the main window sort order.
	ListBoxSetDisplayOrder(LL.winList, ScenarioSummaryWindow.playerListOrder)

end

----------[Player list sorting functions]----------------------------------------------
--Clear custom sort order
function LL.SortReset()
  GG.SAVE.Options[LL.Options[1].save] = nil	--Clear custom sort order
  GG.Func.OptionsLoad(LL.winChild, LL.Options)
  LL.sortOrder = nil
  LL.sortOrderCol = nil
  WindowSetShowing( LL.winHeaderUp, false )
  WindowSetShowing( LL.winHeaderDown, false )
end

--Toggle sorting order flag
function LL.SortOrderToggle(order)
  local _col = tonumber(GG.SAVE.Options[LL.Options[1].save])
  if order ~= nil then
    LL.sortOrder = order
  elseif LL.sortOrderCol ~= _col then --new column
    LL.sortOrder = "up"
  elseif LL.sortOrder == "up" then
    LL.sortOrder = "down"
  elseif LL.sortOrder == "down" then
    LL.sortOrder = "up"
  else
    LL.sortOrder = "up"
  end
  LL.sortOrderCol = _col
end

--This function is used as the comparison function for 
--table.sort() on the player display order
--Todo: Sort also strings.
function LL.SortCompare( index1, index2 )
  local _player1, _player2, _col, _key, _val1, _val2
  if index2 == nil then
    return false
  end
  _player1 = GG.SAVE.Scenario[GG.selected_scenario][index1]
  _player2 = GG.SAVE.Scenario[GG.selected_scenario][index2]
  _col = GG.SAVE.Options[LL.Options[1].save]
  if _col == nil then
    return
  end
  _key = LL.List[_col].field
  --Check that log table exist
  if _player1[LL.List[_col].log] == nil then
    _val1 = 0
  else
    _val1 = _player1[LL.List[_col].log][_key]
  end
  if _player2[LL.List[_col].log] == nil then
    _val2 = 0
  else
    _val2 = _player2[LL.List[_col].log][_key]
  end
  --Check nil values
  if _val1 == nil then
    _val1 = 0
  end
  if _val2 == nil then
    _val2 = 0
  end
  --Compare
  if _val1 == _val2 then
    return ( index1 > index2 )
  else
    if LL.sortOrder == "down" then
      return ( _val1 < _val2 )
    else
      return ( _val1 > _val2 )
    end
  end
end

--Custom sort (Main window sort left on if no custom set.)
function LL.Sort()
    if GG.SAVE.Options[LL.Options[1].save] == nil then
      return  --No custom sort option selected.
    end
    table.sort( ScenarioSummaryWindow.playerListOrder, LL.SortCompare )
    ListBoxSetDisplayOrder( "ScenarioSummaryWindowPlayerList", ScenarioSummaryWindow.playerListOrder )
    ListBoxSetDisplayOrder( LL.winList, ScenarioSummaryWindow.playerListOrder )
end
