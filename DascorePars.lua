----------[Global variables]----------------------------------------------
local GG = Dascore			--Global package
local LL = {}							--Local package
DascorePars = LL
GG.Pars = LL							--Local in global package
GG.ParserDebug = LL.ParserDebug --Debugging command for troubleshooting this parser.
--Can be used within game with: Dascore.ParserDebug(source, class, target, str)
 
----------[Local variables]----------------------------------------------
LL.maxRows = 10000
--TABLES
LL.SearchStrings = {}     --Search strings for the parser
LL.Stats = {}             --Parsed combat events are collected to this table
--GG.ExportLog            --Finalized stats will be stored to this global table for waiting to be imported.
                          --More document about this structure can be found before function LL.ParserCreateExport.

----------[Parse functions]----------------------------------------------
function LL.ParserInit()
  LL.SearchStrings = {}
  table.insert(LL.SearchStrings, { class = "heal", str = "^(Your) (.-) critically heals (.-) for (%d+) points." })
  table.insert(LL.SearchStrings, { class = "heal", str = "^(.-)'s (.-) critically heals (.-) for (%d+) points." })
  table.insert(LL.SearchStrings, { class = "heal", str = "^(Your) (.-) heals (.-) for (%d+) points." })
  table.insert(LL.SearchStrings, { class = "heal", str = "^(.-)'s (.-) heals (.-) for (%d+) points." })
  table.insert(LL.SearchStrings, { class = "damage", str = "^(Your) (.-) critically hits (.-) for (%d+) damage. %((%d+) mitigated%)" })
  table.insert(LL.SearchStrings, { class = "damage", str = "^(Your) (.-) critically hits (.-) for (%d+) damage." })
  table.insert(LL.SearchStrings, { class = "damage", str = "^(.-)'s (.-) critically hits (.-) for (%d+) damage. %((%d+) mitigated%)" })
  table.insert(LL.SearchStrings, { class = "damage", str = "^(.-)'s (.-) critically hits (.-) for (%d+) damage." })
  table.insert(LL.SearchStrings, { class = "damage", str = "^(Your) (.-) hits (.-) for (%d+) damage. %((%d+) mitigated%)" })
  table.insert(LL.SearchStrings, { class = "damage", str = "^(Your) (.-) hits (.-) for (%d+) damage." })
  table.insert(LL.SearchStrings, { class = "damage", str = "^(.-)'s (.-) hits (.-) for (%d+) damage. %((%d+) mitigated%)" })
  table.insert(LL.SearchStrings, { class = "damage", str = "^(.-)'s (.-) hits (.-) for (%d+) damage." })
end

--Create timestamp before and after scenario
function LL.ParserGetTimestamp(event)
  local _lastEntry = TextLogGetNumEntries("Combat") - 1
  local _timestamp = TextLogGetEntry("Combat", _lastEntry)
  local _timeNow = GG.Func.TimestampToNumber(_timestamp)
  
  if event == "begin" then
    GG.SAVE.timestampBegin = _timeNow
  elseif event == "end" then
    GG.SAVE.timestampEnd = _timeNow
  end
end

--Calls parsing and exporting functions thus resulting ready export table.
function LL.ParserSave()
  if GG.SAVE.timestampBegin == nil then
    return
  end
  if GG.SAVE.timestampEnd == nil then
    return
  end
  if GG.SAVE.timestampBegin > GG.SAVE.timestampEnd then --day changed
    GG.SAVE.timestampEnd = GG.SAVE.timestampEnd + 240000
  end
  
  LL.ParserChat(LL.maxRows)
  LL.ParserCreateExport()
end

--This function should help developers and end users to test parsing.
--First three parameters will dump parsed chat row to debug window any parsed line that meets the criteria (and logic).
--Last parameter dumps chat row to debug window if that string is found in the line.
--Combining these two ranges it's possible to see what rows are parsed and which are missing.
--source = combat event source (eg. Your or PlayerName)
--class =  custom class (eg. heal)
--target = combat event target (eg. you or Playername)
--str = Plain search string
function LL.ParserDebug(source, class, target, str)
  local _DebugPar = {}
  if source == nil then
    _DebugPar.source = ""
  else
    _DebugPar.source = source
  end
  if class == nil then
    _DebugPar.class = ""
  else
    _DebugPar.class = class
  end
  if target == nil then
    _DebugPar.target = ""
  else
    _DebugPar.target = target
  end
  if str == "" then 
    _DebugPar.str = nil
  else
    _DebugPar.str = str
  end
  LL.ParserChat(LL.maxRows, _DebugPar)
end

--Parse Combat chat log
function LL.ParserChat(numRows, DebugPar)
  LL.Stats = {} --Empty previous collection
  
  local _rowStart = 1
  local _rowTotal = TextLogGetNumEntries("Combat") - 1
  if _rowTotal > numRows then --Just in case given rows are more than log rows.
    _rowStart = _rowTotal - numRows
  end

  for iRow=_rowStart, _rowTotal do
    local _logTime, _logFilter, _logText = TextLogGetEntry("Combat", iRow)

    --Only process the given time period
    local _timestamp = GG.Func.TimestampToNumber(_logTime)
    if GG.SAVE.timestampBegin == nil
    or GG.SAVE.timestampEnd   == nil
    or GG.SAVE.timestampBegin >= _timestamp
    or GG.SAVE.timestampEnd   <= _timestamp then
        continue
    end

    if DebugPar ~= nil 
    and DebugPar.str ~= nil then
      if string.find(tostring(_logText), DebugPar.str) ~= nil then
        d(_logText)
      end
    end

    --Check if current chat row matches one of the search strings
    for k, v in ipairs(LL.SearchStrings) do
      local _, _, _source, _ability, _target, _val, _val2 = string.find(tostring(_logText), v.str)
      if _ ~= nil then
        if _ability ~= "Bolster" then --Todo: filter this better (boster)
          LL.ParserCollect(LL.Stats, _logText, _source, v.class, _target, tonumber(_val), DebugPar)
          if _val2 ~= nil then  --Todo: filter this better (mitigated)
            LL.ParserCollect(LL.Stats, _logText, _source, "mitigate", _target, tonumber(_val2), DebugPar)
          end
        end
        break
      end
    end
  end
end

--Create internal table for parsing use only. This table is not in the format
--required by the import function!
function LL.ParserCollect(Stats, logText, source, class, target, val, DebugPar)

  if DebugPar ~= nil then
    if string.len(DebugPar.source .. DebugPar.class .. DebugPar.target) > 0 then
      if  (  DebugPar.source == source
          or string.len(DebugPar.source) == 0 )
      and (  DebugPar.class == class
          or string.len(DebugPar.class) == 0 )
      and (  DebugPar.target == target
          or string.len(DebugPar.target) == 0 ) then
        d(logText)
        d(source .. ", " .. class .. ", " .. target .. ", " .. val)
      end
    end
  end
  
  if Stats == nil then
    Stats = {}
  end
  if Stats[source] == nil then
    Stats[source] = {}
  end
  if Stats[source][class] == nil then
    Stats[source][class] = {}
  end
  if Stats[source][class][target] == nil then
    Stats[source][class][target] = {}
  end
  if Stats[source][class][target].value == nil then
    Stats[source][class][target].value = 0
  end
  Stats[source][class][target].value = Stats[source][class][target].value + val
end

----------[Exporting functions]----------------------------------------------
--Creates the table that can be imported to the main program.
--[[
This table is structured like this:
  MyPackage.LogExport.Playername.statname = numbervalue

  MyPackage = name of your program package
    (eg. MySuperCombatLog)
    [This is not the name of the "Scenario Results"-addons import package!]

  LogExport = main table name
    (eg. MyExportLog)
    
  Playername = Sub-table with table key name equal to the player's name who the stats belong to.
    (eg. IHiilWithTLC)
    [Be careful since GameData.Player.name contains the gender also (=Name^M).
    This gender need to be removed before assigning it to this table name.]
    
  statsname = Value is stored with this name.
    (eg. damageMitigated)
    
  numbervalue = This is the actual value that will be displayed. Only numbers allowed for now.
    (eg. 1000)

Playername and statsname will first be lower-cased in the import program. So you can use your
own variable naming method.
--]]
function LL.ParserCreateExport()
  GG.ExportLog = {}
  local _ExportLog = GG.ExportLog
  local _ParseData = LL.Stats
  local _statNameYourHeals = "healbyyou"
  local _statNameOtherHeals = "healtoyou"
  local _statNameYourDamage = "damagebyyou"
  local _statNameOtherDamage = "damagetoyou"
  local _statNameYourMitigate = "mitigatebyyou"
  local _statNameOtherMitigate = "mitigatetoyou"
  
  local _player = GG.Func.GetName(GameData.Player.name) --Name^M -> Name
  
  --Your heals
  for kSource, vClass in pairs(_ParseData) do
    if kSource == "Your"
    and vClass["heal"] ~= nil then
      for kTarget, vValue in pairs(vClass["heal"]) do
        if _ExportLog[kTarget] == nil then
          _ExportLog[kTarget] = {}
        end
        _ExportLog[kTarget][_statNameYourHeals] = vValue.value
      end
    end
  end
  
  --Others healing you
  for kSource, vClass in pairs(_ParseData) do
    if vClass["heal"] ~= nil then
      for kTarget, vValue in pairs(vClass["heal"]) do
        if kTarget == "you" then
          if _ExportLog[kSource] == nil then
            _ExportLog[kSource] = {}
          end
          _ExportLog[kSource][_statNameOtherHeals] = vValue.value
        end
      end
    end
  end

  --Your damage
  for kSource, vClass in pairs(_ParseData) do
    if kSource == "Your"
    and vClass["damage"] ~= nil then
      for kTarget, vValue in pairs(vClass["damage"]) do
        if _ExportLog[kTarget] == nil then
          _ExportLog[kTarget] = {}
        end
        _ExportLog[kTarget][_statNameYourDamage] = vValue.value
      end
    end
  end

  --Others damaging you
  for kSource, vClass in pairs(_ParseData) do
    if vClass["damage"] ~= nil then
      for kTarget, vValue in pairs(vClass["damage"]) do
        if kTarget == "you" then
          if _ExportLog[kSource] == nil then
            _ExportLog[kSource] = {}
          end
          _ExportLog[kSource][_statNameOtherDamage] = vValue.value
        end
      end
    end
  end

  --Your damage mitigated
  for kSource, vClass in pairs(_ParseData) do
    if kSource == "Your"
    and vClass["mitigate"] ~= nil then
      for kTarget, vValue in pairs(vClass["mitigate"]) do
        if _ExportLog[kTarget] == nil then
          _ExportLog[kTarget] = {}
        end
        _ExportLog[kTarget][_statNameYourMitigate] = vValue.value
      end
    end
  end

  --Others damage mitigated
  for kSource, vClass in pairs(_ParseData) do
    if vClass["mitigate"] ~= nil then
      for kTarget, vValue in pairs(vClass["mitigate"]) do
        if kTarget == "you" then
          if _ExportLog[kSource] == nil then
            _ExportLog[kSource] = {}
          end
          d(kSource)
          d(vValue.value)
          _ExportLog[kSource][_statNameOtherMitigate] = vValue.value
        end
      end
    end
  end
  
  --Convert "Your/you" to player name
  for kSource, v in pairs(_ExportLog) do
    if kSource == "Your"
    or kSource == "you" then
      if _ExportLog[_player] == nil then
        _ExportLog[_player] = {}
      end
      for k, v2 in pairs(v) do
        _ExportLog[_player][k] = v2
      end
    end
  end
  _ExportLog["Your"] = nil
  _ExportLog["you"] = nil
  
end