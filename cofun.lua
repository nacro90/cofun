local cofun = {}

function cofun.count(start)
   start = start or 1
   return coroutine.wrap(function()
      local counter = start
      while true do
         coroutine.yield(counter)
         counter = counter + 1
      end
   end)
end

function cofun.take(n, iterator)
   return coroutine.wrap(function()
      local counter = 1
      local iteration = iterator()
      while iteration and counter <= n do
         coroutine.yield(iteration)
         iteration = iterator()
         counter = counter + 1
      end
   end)
end

function cofun.map(mapper, iterator)
   return coroutine.wrap(function()
      for iteration in iterator do coroutine.yield(mapper(iteration)) end
   end)
end

function cofun.filter(predicate, iterator)
   return coroutine.wrap(function()
      local iteration = iterator()
      while iteration do
         if type(predicate) == 'function' then
            if predicate(iteration) then coroutine.yield(iteration) end
         else
            if predicate ~= iteration then coroutine.yield(iteration) end
         end
         iteration = iterator()
      end
   end)
end

function cofun.zip(...)
   local iterators = {...}
   return coroutine.wrap(function()
      local iterations = {}
      local iterate = function()
         for i, co in ipairs(iterators) do iterations[i] = co() end
      end
      iterate()
      while cofun.all(cofun.iter(iterations)) do
         coroutine.yield(unpack(iterations))
         iterate()
      end
   end)
end

function cofun.takewhile(predicate, iterator)
   return coroutine.wrap(function()
      local iteration = iterator()
      while iteration and predicate(iteration) do
         coroutine.yield(iteration)
         iteration = iterator()
      end
   end)
end

function cofun.dropwhile(predicate, iterator)
   return coroutine.wrap(function()
      local iteration
      repeat iteration = iterator() until not iteration or predicate(iteration)
      while iteration do
         coroutine.yield(iteration)
         iteration = iterator()
      end
   end)
end

function cofun.recur(iteration)
   return coroutine.wrap(function()
      while true do coroutine.yield(iteration) end
   end)
end

function cofun.enumerate(iterator) return cofun.zip(cofun.count(), iterator) end

function cofun.iter(tbl)
   return coroutine.wrap(function()
      for _, iteration in pairs(tbl) do coroutine.yield(iteration) end
   end)
end

function cofun.collect(iterator)
   local collection = {}
   for iteration in iterator do collection[#collection + 1] = iteration end
   return collection
end

function cofun.collectmap(iterator, key_fun, val_fun)
   local map = {}
   for iteration in iterator do map[key_fun(iteration)] = val_fun(iteration) end
   return map
end

function cofun.reduce(bi_fun, iterator, init_val)
   local reduced = init_val or iterator()
   if reduced then
      for iteration in iterator do reduced = bi_fun(reduced, iteration) end
   end
   return reduced
end

function cofun.any(iterator)
   for iteration in iterator do if iteration then return true end end
   return false
end

function cofun.all(iterator)
   for iteration in iterator do if not iteration then return false end end
   return true
end

function cofun.sum(iterator)
   return cofun.reduce(function(left, right) return left + right end, iterator, 0)
end

function cofun.negated(func) return function(...) return not func(...) end end

return cofun
