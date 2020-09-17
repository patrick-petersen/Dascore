----------[Global variables]----------------------------------------------
local GG = Dascore			--Global package
local LL = {}							--Local package
DascoreFunc = LL
GG.Func = LL							--Local in global package

----------[Local variables]----------------------------------------------
LL.titlebar = "TitleBar"
LL.titlebartext = "TitleBarText"

----------[Window functions]----------------------------------------------
--Adjust window dimensions according to number of Options.
function LL.OptionsSetWindowDimensions(winRoot, Options)
	local _height = 0
	for k, v in pairs(Options) do
		_height = k * 40
	end		
	_height = _height + 85
	WindowSetDimensions(winRoot, 500, _height)
end

----------[Option window functions]----------------------------------------------
--Create Options windows dynamically based on Options-table.
function LL.OptionsShow(winRoot, winChild, template, Options, offsetX, offsetY)
	if offsetX == nil then
		offsetX = 30
	end
	if offsetY == nil then
		offsetY = 20
	end
	for k, v in pairs(Options) do
		CreateWindowFromTemplate(winChild .. k, template .. v.type, winRoot)
		if k == 1 then --first option anchored to the titlebar
			WindowAddAnchor(winChild .. k, "bottomleft", winRoot .. LL.titlebar, "topleft", offsetX, offsetY)
		else
			WindowAddAnchor(winChild .. k, "bottomleft", winChild .. k-1, "topleft", 0, 10)
		end
		if v.type == "checkbox" then
			LabelSetText (winChild .. k .. "Label",  v.label)
		end
		if v.type == "buttongroup" then
			ButtonSetText (winChild .. k .. "Buttongroup",  v.label)
		end
	end		
	LL.OptionsLoad(winChild, Options)
end

--Hide Options windows dynamically based on Options-table.
function LL.OptionsHide(winChild, Options)
	for k, v in pairs(Options) do
		if DoesWindowExist(winChild .. k) == true then
			DestroyWindow(winChild .. k)
		end
	end		
end

--Load saved Options dynamically based on Options-table.
function LL.OptionsLoad(winChild, Options)
	for k, v in pairs(Options) do
		if v.type == "checkbox" then
			if GG.SAVE.Options[v.save] == nil then
				GG.SAVE.Options[v.save] = false
			end
			ButtonSetPressedFlag(winChild .. k .. "Checkbox", GG.SAVE.Options[v.save])
		end
		if v.type == "buttongroup" then
			ButtonSetPressedFlag(winChild .. k .. "Buttongroup", GG.SAVE.Options[v.save] == k)
		end
		
	end
end

--Toggle Options
function LL.OptionsToggle(winChild, Options)
  local _, _, _row, _rowtype = string.find(SystemData.MouseOverWindow.name, "^" .. winChild .. "(%d+)(.+)")
  _row = tonumber(_row)
	_rowtype = string.lower(_rowtype)
  if Options[_row] == nil
  or Options[_row].type ~= _rowtype  then
    return
  end
	if _rowtype == "checkbox" then
		if GG.SAVE.Options[Options[_row].save] == true then
			GG.SAVE.Options[Options[_row].save] = false
		else
			GG.SAVE.Options[Options[_row].save] = true
		end
	end
	if _rowtype == "buttongroup" then
		if GG.SAVE.Options[Options[_row].save] == _row then 	--unselect
			GG.SAVE.Options[Options[_row].save] = nil
		else
			GG.SAVE.Options[Options[_row].save] = _row
		end
	end
	LL.OptionsLoad(winChild, Options)
end

----------[Misc functions]----------------------------------------------
--Create a copy of a table. Also copies unlimited nested tables.
function LL.CopyTable(source, target)
  if source == nil then
    return
  end
	for k,v in pairs(source) do
		if type (v) == "table" then
			target[k] = {}
			LL.CopyTable(source[k], target[k])
		else
			target[k] = v
		end
	end
end

function LL.NumToWstring(number)
  if number == nil then
    return L"0"
  else
    return towstring(number)
  end
end

function LL.CreateDate()
	local lastEntry = TextLogGetNumEntries("Chat") - 1
	local lastTime = TextLogGetEntry("Chat", lastEntry)
	local hours,mins,secs = lastTime:match(L"([0-9]+):([0-9]+):([0-9]+)")
	local td = Calendar.todaysYear .. "-" .. Calendar.todaysMonth .. "-" .. Calendar.todaysDay
	td = td .. " " .. WStringToString(hours) .. ":" .. WStringToString(mins)

	return towstring(td)
end

--In scenario results player names also include gender (Name^M). Sometimes
--we need to get rid of the gender to be able to compare names.
function LL.GetName(name)
  local _, _, _nameFormatted = string.find(tostring(name), "(.+)%^.")   --NAME^M -> NAME
  if _ == nil then
		_nameFormatted = tostring(name)		 																	--NAME -> NAME
  end
	
	--Capitalize
	_nameFormatted = string.lower(_nameFormatted)													--NAME -> name
	local _begin = string.upper(string.match(_nameFormatted, "(.)")) 			--name -> n -> N
	local _end = string.match(_nameFormatted, ".(.*)") 										--name -> ame
	_nameFormatted = _begin .. _end																				--N + ame -> Name
	
  return _nameFormatted
end

--[hh:mm:ss] -> hhmmss (also string to number)
function LL.TimestampToNumber(timestamp)
    local _, _, _hours, _mins, _secs = string.find(tostring(timestamp), "(%d+):(%d+):(%d+)")
    return tonumber(_hours .. _mins .. _secs)
end
