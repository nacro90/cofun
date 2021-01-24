# Cofun

A simple coroutine powered functional programming library for LuaJIT.

## Why

The cofun is aimed to be simple as anyone can contribute and learn something
about functional programming and maybe Lua coroutines. Also it is aimed to be
simplify the implementation of functional paradigms in any LuaJIT project.

## Usage

For ease of use require the library and localize its functions:

```lua
local cofun = require('cofun')
local map = cofun.map
local filter = cofun.filter
local collect = cofun.collect
-- ...
```

Get passed student grades

```lua
grades = iter{56, 88, 85, 44, 90}

function can_pass(grade) return grade > 60 end

filter(can_pass, grades) -- iter{88, 85, 90}
```

Do not process until an element contains the letter b and then take 5 uppercased elements.
```lua
function contains_b(str) return string.find(str, 'b') end

take(5, map(string.upper, dropwhile(negated(contains_b), iterator)))
```

Zip `n` iterators.

```lua
letters = iter{'a', 'b', 'c'}

for l, n in zip(letters, count()) do
  print(l, n) -- 'a', 1 | 'b', 2 | 'c', 3
end

for l, n in enumerate(letters) do
  print(l, n) -- 'a', 1 | 'b', 2 | 'c', 3
end

for l, n, f in zip(letters, count(), count(5)) do
  print(l, n, f) -- 'a', 1, 5 | 'b', 2, 6 | 'c', 3, 7
end
```

You can consume the values using reducing, iterating and collecting.

### Iterating

Iteration is the most efficientt way of consuming because of the absence of
table creation.

```lua
iterator = iter{1,7,8}
for i in iterator do
  -- Consume i
end
```

### Collecting

Consume the iterator and collect the iterations in a table.

```lua
collect(take(4, count(7)))
```

Provides `{7, 8, 9, 10}`

### Folding

Folding reduces the dimension of the iteration to single element using a binary
function.

```lua
-- Concat strings
foldfirst(function(left, right) return left .. right end, iterator)
-- Find max
foldfirst(function(left, right) return left < right and right or left end, iterator)
```

Some reduction shortcuts are implemented too and more can be added in the
future:

```lua
sum(iterator)
max(iterator)
min(iterator)
```

## Installation

Just copy `cofun.lua` and you are good to go. Don't forget the licence.

## TODO

- [X] Write initial code
- [ ] Add docstrings
- [ ] Write unit tests
- [ ] Publish to luarocks

## See also

- [Lua Fun](https://github.com/luafun/luafun)
- [Python `itertools`](https://docs.python.org/3/library/itertools.html)
