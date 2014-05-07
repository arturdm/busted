return function()
  local loadOutputHandler = function(output, opath, options)
    local handler

    if output:match(".lua$") or output:match(".moon$") then
      handler = loadfile(path.normpath(path.join(opath, output)))
    else
      handler = require('src.outputHandlers.'..output)
    end

    return handler(options)
  end

  return loadOutputHandler
end
