local moonscript = require 'moonscript'
local line_tables = require 'moonscript.line_tables'
local util = require 'moonscript.util'

local rewrite_linenumber = function(fname, lineno)
  local tbl = line_tables[fname]
  if fname and tbl then
    for i = lineno,0,-1 do
      if tbl[i] then
        return lookup_line(fname, tbl[i])
      end
    end
  end
end

local rewrite_traceback = function(err, trace)
  local lines = {}
  local j = 0

  local rewrite_one = function(line)
    if line == nil then
      return ""
    end

    local fname, lineno = line:match('[^"]+"([^:]+)".:(%d+):')

    if fname and lineno then
      local new_lineno = rewrite_linenumber(fname, tonumber(lineno))
      if new_lineno then
        line = line:gsub(':' .. lineno .. ':', ':' .. new_lineno .. ':')
      end
    end
    return line
  end

  for line in trace:gmatch("[^\r\n]+") do
    j = j + 1
    lines[j] = rewrite_one(line)
  end

  return rewrite_one(err), table.concat(lines, trace:match("[\r\n]+"))
end

local ret = {}

ret.match = function(busted, filename)
  local path, name, ext = filename:match("(.-)([^\\/\\\\]-%.?([^%.\\/]*))$")
  if ext == "moon" then
    return true
  end
  return false
end


ret.load = function(busted, filename)
  local file

  local success, err = pcall(function()
    file, err = moonscript.loadfile(filename)

    if not file then
      busted.publish({ "error", 'file' }, filename, nil, nil, err)
    end
  end)

  if not success then
    busted.publish({ "error", 'file' }, filename, nil, nil, err)
  end

  busted.debugInfo = ret.debugInfo

  return file
end

ret.debugInfo = function(busted, filename, level)
  local info = debug.getinfo(level, 'Sl')
  info.traceback = rewrite_traceback(message, debug.traceback(level))
  info.linedefined = rewrite_linenumber(filename, info.currentline)
  return info
end

return ret
