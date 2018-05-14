pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- liminal
-- by tarek

function _init()
 w = world()
 w:load_from_map(1, 1, 128, 128)
 
 local e = w:create_entity('player')
 
 e:add_components(position(0, 0), velocity(0, 0), display(sprite(64)))
 
 local a = animator()
 a:add_animation('walk_r', animation(sprite.batch(112, 113, 114)))
 a:add_animation('walk_l', animation(sprite.batch(80, 81, 82)))
 a:add_animation('walk_d', animation(sprite.batch(64, 65)))
 a:add_animation('walk_u', animation(sprite.batch(96, 97, 98)))
 
 e:add_components(a)
end

function _update()
 w:update()
end

function _draw()
 cls()
 
 -- set camera
 -- draw background tiles
 
 w:draw()
 
 -- draw foreground tiles
 -- reset camera
end
-->8
-----------------------------
-- debugging and utilities --
-----------------------------

-- https://gist.github.com/tylerneylon/81333721109155b2d244
function clone(var, seen)
 if (not is_table(var)) return var
 if (seen and seen[var]) return seen[var]
 
 local s = seen or {}
 local result = setmetatable({}, getmetatable(var))
 
 s[var] = result
 
 for k, v in pairs(var) do
  result[clone(k, s)] = clone(v, s)
 end
 
 return result
end

function every(list, func)
 for _, v in pairs(list) do
  if (not func(v)) return false
 end
 
 return true
end

function index_add(table, index, element)
 if (not table[index]) table[index] = {}
 
 add(table[index], element)
end

function index_remove(table, index, element)
 if (table[index]) del(table[index], element)
end

function is_number(var)
 return type(var) == 'number'
end

function is_table(var)
 return type(var) == 'table'
end

function to_seconds(ticks)
 return ticks / 30
end

function to_ticks(seconds)
 return seconds * 30
end
-->8
-------------------
-- class objects --
-------------------

-- https://github.com/rxi/classic
object = {}
object.__index = object

function object:extend(name)
 local new_object = {}
 
 for k, v in pairs(self) do
  if (sub(k, 1, 2) == '__') new_object[k] = v
 end
 
 new_object.__index = new_object
 new_object.super = self
 
 new_object.name = name or 'object'
 
 return setmetatable(new_object, self)
end

function object:is(class)
 local metatable = getmetatable(self)
 
 while metatable do
  if (metatable == class) return true
  
  metatable = getmetatable(metatable)
 end
 
 return false
end

---

function object:new()
 -- empty
end

function object:to_string()
 return self.name
end

---

function object:__call(...)
 local new_object = setmetatable({}, self)
 
 new_object:new(...)
 
 return new_object
end
-->8
--------------------------
-- vectors and geometry --
--------------------------

vector = object:extend()

function vector:new(x, y)
 self.x = x
 self.y = y
end

function vector:str()
 return '[' .. self.x .. ', ' .. self.y .. ']'
end

---

function vector:dot(vec)
 return self.x * vec.x + self.y + vec.y
end

function vector:dist(vec)
 local dx = self.x - vec.x
 local dy = self.y - vec.y
 
 return sqrt(dx * dx + dy * dy)
end

function vector:length()
 return sqrt(#self)
end

function vector:normalize()
 return self / self:length()
end

function vector:unpack()
 return self.x, self.y
end

---

function vector:__add(vec)
 return vector(self.x + vec.x, self.y + vec.y)
end

function vector:__sub(vec)
 return vector(self.x - vec.x, self.y - vec.y)
end

function vector:__mul(scalar)
 return vector(self.x * scalar, self.y * scalar)
end

function vector:__div(scalar)
 return vector(self.x / scalar, self.y / scalar)
end

function vector:__unm()
 return vector(-self.x, -self.y)
end

--//--

box = object:extend()

function box:new(x, y, w, h)
 self.x = x
 self.y = y
 self.w = w
 self.h = h
end

function box:draw(color, is_filled)
 local draw_func = rect
 
 if (is_filled) draw_func = rectfill
 
 draw_func(self.x, self.y, self.x + self.w - 1, self.y + self.h - 1, color)
end

function box:intersects(b)
 return (self.x < b.x + b.w and self.x + self.w > b.x and
         self.y < b.y + b.h and self.y + self.h > b.y) 
end
-->8
---------------------------
-- sprites and animation --
---------------------------

sprite = object:extend()

-- w/h, width/height in tiles
function sprite:new(id, w, h)
 self.id = id
 
 self.w = w or 1
 self.h = h or 1
end

function sprite:draw(x, y)
 spr(self.id, x, y, self.w, self.h)
end

---

-- creates an array of 1x1 sprites from ids
function sprite.batch(...)
 local args = {...}
 
 assert(every(args, is_number))
 
 local sprites = {}
 
 -- use all() to preserve order
 for arg in all(args) do
  add(sprites, sprite(arg))
 end
 
 return sprites
end

--//--

animation = object:extend()
 
-- sprites, an array of sprite objects
-- delay, time between frames in seconds
function animation:new(sprites, delay, is_looped)
 self.state = 'playing'
  
 self.sprites = sprites
 self.current_sprite = 1
  
 self.delay = delay or 0.5
 self.ticks = to_ticks(self.delay)
  
 self.is_looped = (is_looped == nil) and true or is_looped
end
 
---
 
function animation:update()
 if (self.state ~= 'playing') return
  
 self.ticks -= 1
  
 if self.ticks <= 0 then
  if self.current_sprite >= #self.sprites then
   if not self.is_looped then
    self.state = 'finished'
   else
	self:restart()
   end
  else
   self.current_sprite += 1
   self.ticks = to_ticks(self.delay)
  end
 end
end
 
---
 
-- returns frame or current_sprite if nil
function animation:get_sprite(frame)
 if (frame) assert(frame >= 1 and frame <= #self.sprites)
  
 return self.sprites[frame or self.current_sprite]
end
 
function animation:pause()
 if (self.state == 'playing') self.state = 'paused'
end
 
-- paused, pause after restart
function animation:restart(paused)
 self.current_sprite = 1
 self.ticks = to_ticks(self.delay)
  
 self.state = paused and 'paused' or 'playing'
end

function animation:resume()
 if (self.state == 'paused') self.state = 'playing'
end
-->8
---------------------------------------
-- entities, components, and systems --
---------------------------------------

entity = object:extend()

function entity:new(world)
 self.world = world
 
 self.alive = true
 self.tags = {}
end

---

function entity:add_components(...)
 local components = {...}
 
 for _, component in pairs(components) do
  self[component.name] = component
  self.world:tag_entity(component.name, self)
 end
end

function entity:remove_component(...)
 local components = {...}
 
 for _, component in pairs(components) do
  self[component.name] = nil
  self.world:untag_entity(component.name, self)
 end
end

---

function entity:set_name(name)
 self.world:name_entity(name, self)
end

---

function entity:add_tags(...)
 local tags = {...}
 
 for _, tag in pairs(tags) do
  add(self.tags, tag)
  self.world:tag_entity(tag, self)
 end
end

function entity:remove_tags(...)
 local tags = {...}
 
 for _, tag in pairs(tags) do
  del(self.tags, tag)
  self.world:untag_entity(tag, self)
 end
end

--//--

animator = object:extend('animator')

function animator:new()
 self.animations = {}
end

function animator:add_animation(name, animation)
 if (not self.current_animation) self.current_animation = name
 
 self.animations[name] = animation
end

function animator:get_animation(name)
 return self.animations[name or self.current_animation]
end

function animator:set_animation(name)
 if (self.current_animation == name) return
 
 self.current_animation = name
 self:get_animation():restart()
end

---

collider = object:extend('collider')

function collider:new(box, mask) 
 self.box  = box
 self.mask = mask or 0x01
end

---

display = object:extend('display')

function display:new(sprite, layer)
 self.visible = true
 
 self.sprite = sprite
 self.layer  = layer or 1
end

---

-- player_input = object:extend('player_input')
-- player_input.acceleration = 1.0

---

position = vector:extend('position')

---

velocity = vector:extend('velocity')

--//--

function handle_movement(world)
 local entities = world:get_entities_tagged_with('position', 'velocity')
 
 foreach(entities, function(e) e.position += e.velocity end)
end

function handle_animation(world)
 local entities = world:get_entities_tagged_with('animator')
 
 for _, e in pairs(entities) do
  e.animator:get_animation():update()
  
  if e.display then
   e.display.sprite = e.animator:get_animation():get_sprite()
  end
 end
end

function handle_player_input(world)
 if (not world.entities_named['player']) return
 
 local player = world.entities_named['player']

 local xin = btn(➡️) and 1 or btn(⬅️) and -1 or 0
 local yin = btn(⬇️) and 1 or btn(⬆️) and -1 or 0
 
 if xin ~= 0 or yin ~= 0 then
  player.animator:get_animation():resume()
  
  if xin > 0 then
   player.animator:set_animation('walk_r')
  elseif xin < 0 then
   player.animator:set_animation('walk_l')
  end
  
  if yin > 0 then
   player.animator:set_animation('walk_d')
  elseif yin < 0 then
   player.animator:set_animation('walk_u')
  end
 else
  player.animator:get_animation():pause()
 end
 
 player.velocity = velocity(xin, yin)
end

--//--

world = object:extend()

function world:new()
 self.entities = {}
 
 self.entities_named = {}  -- name / e
 self.entities_tagged = {} -- tag / {e1, e2, ..., en}
end

function world:update()
 -- update systems
 handle_player_input(self)

 handle_movement(self)
 handle_animation(self)
 
 self:clean_up()
end

function world:draw()
 local drawables = {}
 
 for _, e in pairs(self:get_entities_tagged_with('display', 'position')) do
  index_add(drawables, e.display.layer, e)
 end
 
 for layer = 1, 16 do
  if drawables[layer] then
   for _, e in pairs(drawables[layer]) do
    if (e.display.visible) e.display.sprite:draw(e.position:unpack())
   end
  end
 end
end

---

function world:clean_up()
 for _, e in pairs(self.entities) do
  if (not e.alive) self:destroy_entity(e)
 end
end

---

function world:create_entity(name, ...)
 local e = entity(self)
 
 add(self.entities, e)
 
 e:set_name(name)
 e:add_tags(...)
 
 return e
end

function world:destroy_entity(entity)
 del(self.entities, entity)
 
 for name, e in pairs(self.entities_named) do
  if (e == entity) self.entities_named[name] = nil
 end
 
 for tag, _ in pairs(self.entities_tagged) do
  del(self.entities_tagged[tag], entity)
 end
end

---

function world:name_entity(name, entity)
 if (name and not self.entities_named[name]) self.entities_named[name] = entity
end

function world:tag_entity(tag, entity)
 index_add(self.entities_tagged, tag, entity)
end

function world:untag_entity(tag, entity)
 index_remove(self.entities_tagged, tag, entity)
end

---

-- fixme: runtime error if trying to pull from nil bucket
function world:get_entities_tagged_with(...) 
 local function intersection(s1, s2)
  local result = {}
  
  for _, v1 in pairs(s1) do
   for _, v2 in pairs(s2) do
    if (v1 == v2) add(result, v1)
   end
  end
  
  return result
 end
 
 local tags = {...}
 local tagged = {}
 
 for index, tag in pairs(tags) do
  if (index == 1) tagged = self.entities_tagged[tag]
  
  if index + 1 <= #tags then
   local next_tag = tags[index + 1]
   
   tagged = intersection(tagged, self.entities_tagged[next_tag])
  end
 end
 
 return tagged
end

---

function world:load_from_map(start_x, start_y, end_x, end_y)
 for i = start_x, end_x do
  for j = start_y, end_y do
   local mx, my = i - 1, j - 1
   local tile_id = mget(mx, my)
   
   if tile_id ~= 0 then
    local e = self:create_entity()
   
    e:add_components(position(mx * 8, my * 8))
    e:add_components(display(sprite(tile_id)))
   end
  end
 end
end
__gfx__
0000000006d666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066d66600303003006d00060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070006d66d6000300800066d1d60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000166666d100808a8076666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770001dddddd108a838307dddddd7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007001d1dd1d1038003007d7dd7d7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111111110030000077777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dddddddd0000000000770070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000990000009900000099000000000000000000000000000eee00eee000000000000000000000000000000000000000000000000000000000000000000000000
00affa0000affa0000999900000990000009900000000000ee0440ee000000000000000000000000000000000000000000000000000000000000000000000000
009ff900009ff90000affa000099990000affa0000000000ee0440ee000000000000000000000000000000000000000000000000000000000000000000000000
00444400004444000094490000affa00009ff90000000000eeddddee000000000000000000000000000000000000000000000000000000000000000000000000
00dddd0000dddd0000dddd00009449000044440000000000ee7777ee000000000000000000000000000000000000000000000000000000000000000000000000
00dd1d0000dcdd0000dd1d0000dddd0000dddd0000000000ee7776ee000000000000000000000000000000000000000000000000000000000000000000000000
00d1cd0000d1cd0000dfcd0000f1cd0000f1cf0000000000ee7765ee000000000000000000000000000000000000000000000000000000000000000000000000
00dc1d0000dc1d0000dc1d000d1c1d000d1c1cd000000000ee7656ee000000000000000000000000000000000000000000000000000000000000000000000000
00999000009990000099900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00faaa0000faaa0000faaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ff990000ff990000ff990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00449900004499000044990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ddd90000dd990000dd990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001ddd0000ddd900001dd90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cddd0000cddd0000cddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001dddd0001dddd0001dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000990000009900000099000000000000000000000000000eee00eee000000000000000000000000000000000000000000000000000000000000000000000000
00aaaa0000aaaa0000aaaa00000000000000000000000000ee0000ee000000000000000000000000000000000000000000000000000000000000000000000000
009999000099990000999900000000000000000000000000ee0000ee000000000000000000000000000000000000000000000000000000000000000000000000
009999000099990000999900000000000000000000000000eeddddee000000000000000000000000000000000000000000000000000000000000000000000000
009999000099990000999900000000000000000000000000eedd77ee000000000000000000000000000000000000000000000000000000000000000000000000
00dd990000d99d000099dd00000000000000000000000000eedd77ee000000000000000000000000000000000000000000000000000000000000000000000000
00dddd0000dddd0000dddd00000000000000000000000000eedd77ee000000000000000000000000000000000000000000000000000000000000000000000000
00dddd0000dddd0000dddd00000000000000000000000000ee7d77ee000000000000000000000000000000000000000000000000000000000000000000000000
00099900000999000009990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aaaf0000aaaf0000aaaf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0099ff000099ff000099ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00994400009944000099440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0099dd000099dd00009ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009ddd00009ddc0000dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ddd10000ddd10000ddd10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ddddc000ddddc000ddddc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0002000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002030000020200000203000002030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002020000020300000202000002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002020000020200000202000002020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002030000020200000202000003020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000201010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000102020100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000201010200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
