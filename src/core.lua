return function()
  local mediator = require 'mediator'()

  local busted = {}
  busted.version = '2.0-1'

  local root = require 'src.context'()
  busted.context = root.ref()

  local environment = require 'src.environment'(busted.context)

  busted.executors = {}
  local executors = {}

  busted.getTrace = function(busted, filename, level) return debug.getinfo(level) end

  function busted.publish(...)
    mediator:publish(...)
  end

  function busted.subscribe(...)
    mediator:subscribe(...)
  end

  function busted.getFileName(element)
    local current, parent = element, busted.context.parent(element)
    while parent do
      filename = parent.name
      parent = busted.context.parent(parent)
    end
    return current.name
  end

  function busted.safe(descriptor, run, element, setenv)
    if setenv and type(run) == 'function' then environment.wrap(run) end
    busted.context.push(element)
    local trace, message

    local ret = {xpcall(run, function(msg)
      message = msg
      trace = busted.getTrace(busted, busted.getFileName(element), 5)
    end)}

    if message then
      busted.publish({'error', descriptor}, element, busted.context.parent(element), message, trace)
    end

    busted.context.pop()
    return unpack(ret)
  end

  function busted.register(descriptor, executor)
    executors[descriptor] = executor
    local publisher = function(name, fn)
      if not fn and type(name) == 'function' then
        fn = name
        name = nil
      end
      local trace = busted.getTrace(busted, busted.getFileName(busted.context.get()), 3)
      busted.publish({'register', descriptor}, name, fn, trace)
    end
    busted.executors[descriptor] = publisher
    environment.set(descriptor, publisher)

    busted.subscribe({'register', descriptor}, function(name, fn, trace)
      local ctx = busted.context.get()
      local plugin = {descriptor = descriptor, name = name, run = fn, trace = trace}
      busted.context.attach(plugin)
      if not ctx[descriptor] then
        ctx[descriptor] = {plugin}
      else
        ctx[descriptor][#ctx[descriptor]+1] = plugin
      end
    end)
  end

  function busted.execute(current)
    if not current then current = busted.context.get() end
    for _, v in pairs(busted.context.children(current)) do
      local executor = executors[v.descriptor]
      if executor then
        busted.safe(v.descriptor, function() return executor(v) end, v)
      end
    end
  end

  return busted
end
