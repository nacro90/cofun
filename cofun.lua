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

function cofun.skip(n, iterator)
   return coroutine.wrap(function()
      local counter = 1
      local iteration = iterator()
      while iterator and counter <= n do
         iteration = iterator()
         counter = counter + 1
      end
      while iterator do
         coroutine.yield(iteration)
         iteration = iterator()
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

function cofun.recurwith(iteration_fun)
   return coroutine.wrap(function()
      while true do coroutine.yield(iteration_fun()) end
   end)
end

function cofun.enumerate(iterator) return cofun.zip(cofun.count(), iterator) end

function cofun.iter(iterable)
   return coroutine.wrap(function()
      if type(iterable) == 'table' then
         for _, iteration in pairs(iterable) do
            coroutine.yield(iteration)
         end
      elseif type(iterable) == 'string' then
         for i = 1, #iterable do coroutine.yield(iterable:sub(i, i)) end
      else
         error('Expected string or table')
      end
   end)
end

function cofun.consume(iterator) for _ in iterator do end end

function cofun.chain(...)
   local iterators = {...}
   return coroutine.wrap(function()
      for _, iterator in ipairs(iterators) do
         for iteration in iterator do coroutine.yield(iteration) end
      end
   end)
end

function cofun.prepend(...)
   local args = {...}
   local iterator = args[#args]
   args[#args] = nil
   return cofun.chain(cofun.iter(args), iterator)
end

function cofun.append(...)
   local args = {...}
   local iterator = args[#args]
   args[#args] = nil
   return cofun.chain(iterator, cofun.iter(args))
end

function cofun.cycle(iterator)
   return coroutine.wrap(function()
      local collection = {}
      for iteration in iterator do
         coroutine.yield(iteration)
         collection[#collection + 1] = iteration
      end
      if #collection > 0 then
         while true do
            for _, v in ipairs(collection) do coroutine.yield(v) end
         end
      end
   end)
end

function cofun.nwise(n, iterator)
   return coroutine.wrap(function()
      local iterations = {}
      local iteration
      for i = 1, n do
         iteration = iterator()
         if not iteration then return end
         iterations[i] = iteration
      end
      repeat
         coroutine.yield(unpack(iterations))
         iteration = iterator()
         for i = 1, n - 1 do iterations[i] = iterations[i + 1] end
         iterations[n] = iteration
      until not iteration
   end)
end

function cofun.pairwise(iterator) return cofun.nwise(2, iterator) end

function cofun.collect(iterator)
   local collection = {}
   for iteration in iterator do collection[#collection + 1] = iteration end
   return collection
end

function cofun.collect_n(n, iterator)
   return cofun.collect(cofun.take(n, iterator))
end

function cofun.collectmap(iterator, key_fun, val_fun)
   local map = {}
   for iteration in iterator do map[key_fun(iteration)] = val_fun(iteration) end
   return map
end

function cofun.fold(bi_fun, init_val, iterator)
   local folded = init_val
   if folded then
      for iteration in iterator do folded = bi_fun(folded, iteration) end
   end
   return folded
end

function cofun.foldfirst(bi_fun, iterator)
   return cofun.fold(bi_fun, iterator(), iterator)
end

function cofun.any(iterator)
   for iteration in iterator do if iteration then return true end end
   return false
end

function cofun.all(iterator)
   for iteration in iterator do if not iteration then return false end end
   return true
end

function cofun.len(iterator)
   local counter = 0
   for _ in iterator do counter = counter + 1 end
   return counter
end

function cofun.interleave(iterator_1, iterator_2)
   return coroutine.wrap(function()
      local iteration_1 = iterator_1()
      local iteration_2 = iterator_2()
      while iteration_1 and iteration_2 do
         coroutine.yield(iteration_1)
         coroutine.yield(iteration_2)
         iteration_1 = iterator_1()
         iteration_2 = iterator_2()
      end
      while iteration_1 do
         coroutine.yield(iteration_1)
         iteration_1 = iterator_1()
      end
      while iteration_2 do
         coroutine.yield(iteration_2)
         iteration_2 = iterator_2()
      end
   end)
end

function cofun.intersperse(element, iterator)
   return coroutine.wrap(function()
      local iteration = iterator()
      if not iteration then return end
      coroutine.yield(iteration)
      iteration = iterator()
      while iteration do
         coroutine.yield(element)
         coroutine.yield(iteration)
         iteration = iterator()
      end
   end)
end

function cofun.chunks(length, iterator)
   return coroutine.wrap(function()
      local chunk = {}
      local counter = 1
      local iteration = iterator()
      while iteration do
         if counter <= length then
            chunk[counter] = iteration
            counter = counter + 1
            iteration = iterator()
         else
            coroutine.yield(chunk)
            counter = 1
         end
      end
      if counter > 1 then
         for i = counter, length do chunk[i] = nil end
         coroutine.yield(chunk)
      end
   end)
end

function cofun.find(predicate, iterator)
   return cofun.first(cofun.filter(predicate, iterator))
end

function cofun.locate(element, iterator)
   for i, iteration in cofun.enumerate(iterator) do
      if iteration == element then return i end
   end
end

function cofun.locateby(locator, iterator)
   for i, iteration in cofun.enumerate(iterator) do
      if locator(iteration) then return i end
   end
end

function cofun.allequal(iterator)
   local previous = iterator()
   if not previous then return true end
   for iteration in iterator do
      if previous ~= iteration then return false end
      previous = iteration
   end
   return true
end

function cofun.sum(iterator)
   local sum_fun = function(left, right) return left + right end
   return cofun.reduce(sum_fun, iterator, 0)
end

function cofun.max(iterator)
   local max_fun = function(left, right)
      if left > right then
         return left
      else
         return right
      end
   end
   return cofun.reduce(max_fun, iterator)
end

function cofun.min(iterator)
   local max_fun = function(left, right)
      if left < right then
         return left
      else
         return right
      end
   end
   return cofun.reduce(max_fun, iterator)
end

function cofun.join(separator, iterator)
   assert(type(separator) == 'string', 'Separator must be a string')
   return table.concat(cofun.collect(cofun.intersperse(separator, iterator)))
end

function cofun.first(iterator) return iterator() end

function cofun.nth(n, iterator) return cofun.first(cofun.skip(n - 1, iterator)) end

function cofun.once(iterator) return cofun.take(1, iterator) end

function cofun.oncewith(mapper, iterator)
   return cofun.map(mapper, cofun.once(iterator))
end

function cofun.last(iterator)
   local previous = iterator()
   if not previous then return end
   local iteration = iterator()
   while iteration do
      previous = iteration
      iteration = iterator()
   end
   return previous
end

function cofun.negated(func) return function(...) return not func(...) end end

return cofun
