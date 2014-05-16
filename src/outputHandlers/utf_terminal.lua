local ansicolors = require 'ansicolors'
local s = require 'say'
require('src.languages.en')

return function(options)
  -- options.language, options.deferPrint, options.suppressPending, options.verbose
  local handler = { }
  local tests = 0
  local successes = 0
  local failures = 0
  local pendings = 0

  local success_string =  ansicolors('%{green}●')
  local failure_string =  ansicolors('%{red}●')
  local pending_string = ansicolors('%{yellow}●')
  local running_string = ansicolors('%{blue}○')

  local failureInfos = { }
  local pendingInfos = { }

  local pendingDescription = function(pending)
    local name = pending.name or ''
    local string = '\n\n' .. ansicolors('%{yellow}' .. s('output.pending')) .. ' → ' .. 
      ansicolors('%{cyan}' .. pending.debug.short_src) .. ' @ ' .. 
      ansicolors('%{cyan}' .. pending.debug.currentline)  .. 
      '\n' .. ansicolors('%{bright}' .. name)

    return string
  end

  local failureDescription = function(failure)
    print('hi')
    local string =  '\n\n' .. ansicolors('%{red}' .. s('output.failure')) .. ' → ' .. 
    ansicolors('%{cyan}' .. failure.debug.short_src) .. ' @ ' .. 
    ansicolors('%{cyan}' .. failure.debug.currentline) .. 
    '\n' .. ansicolors('%{bright}' .. failure.name) .. 
    '\n' .. failure.message

    if options.verbose then
      string = string .. failure.debug.trace
    end

    return string
  end

  local status_string = function(successes, failures, pendings, ms)
    local success_str = s('output.success_plural')
    local failure_str = s('output.failure_plural')
    local pending_str = s('output.pending_plural')

    if successes == 0 then
      success_str = s('output.success_zero')
    elseif successes == 1 then
      success_str = s('output.success_single')
    end

    if failures == 0 then
      failure_str = s('output.failure_zero')
    elseif failures == 1 then
      failure_str = s('output.failure_single')
    end

    if pendings == 0 then
      pending_str = s('output.pending_zero')
    elseif pendings == 1 then
      pending_str = s('output.pending_single')
    end

    local formatted_time = ('%.6f'):format(ms):gsub('([0-9])0+$', '%1')

    return ansicolors('%{green}' .. successes) .. ' ' .. success_str .. ' / ' .. 
      ansicolors('%{red}' .. failures) .. ' ' .. failure_str .. ' / ' .. 
      ansicolors('%{yellow}' .. pendings) .. ' ' .. pending_str .. ' : ' .. 
      ansicolors('%{bright}' .. formatted_time) .. ' ' .. s('output.seconds')
  end

  handler.testStart = function(name, parent)
    tests = tests + 1

    if not options.deferPrint then
      io.write(running_string)
    end
  end

  handler.testEnd = function(name, parent, status)
    if not options.deferPrint then
      io.write('\08')
    end

    local string = success_string

    if status then
      successes = successes + 1
    else
      string = failure_string
      failures = failures + 1
    end

    if not options.deferPrint then
      io.write(string)
      io.flush()
    end
  end

  handler.pending = function(element, parent, message, debug)
    if not options.suppressPending and not options.deferPrint then
      pendings = pendings + 1
      io.write(pending_string)

      table.insert(pendingInfos, { name = element.name, debug = element.trace })
    end
  end

  handler.fileStart = function(name, parent)
  end

  handler.fileEnd = function(name, parent)
  end

  handler.suiteStart = function(name, parent)
  end

  handler.suiteEnd = function(name, parent)
    -- print an extra newline of defer print
    if not options.deferPrint then
      print('')
    end

    print(status_string(successes, failures, pendings, 0, {}))

    if #failureInfos > 0 then
      print('')
      print(ansicolors('%{red}Errors:'))
    end

    for i, pending in pairs(pendingInfos) do
      print(pendingDescription(pending))
    end

    for i, err in pairs(failureInfos) do
      print(failureDescription(err))
    end

  end

  handler.error = function(element, parent, message, debug)
    table.insert(failureInfos, { name = element.name, message = message, debug = debug })
  end

  return handler
end
