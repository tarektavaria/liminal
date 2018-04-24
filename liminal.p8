pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- liminal
-- by tarek

function _init()
 w = world()
 w:load_from_map(128, 128)
 
 w:add_entity(player(), 'player')
end

function _update()
 w:update()
end

function _draw()
 cls()
 
 -- draw all map tiles
 -- todo: draw only background tiles
 -- map()
 
 w:draw()
 
 -- draw foreground map tiles
 -- map(0, 0, 0, 0, 128, 64, 0x1)
 
 -- debug_draw()
end
-->8
-----------------------------
-- debugging and utilities --
-----------------------------

-- todo: create a debug mask?
show_colliders = true

show_cpu = true
show_fps = true

function debug_draw()
 color(7)
 
 if show_colliders then
  for e in all(w.entities) do
   local c = e:get_collider()
   
   c:draw(7)
  end
 end
 
 if (show_cpu) print('cpu: ' .. stat(1))
 if (show_fps) print('fps: ' .. stat(7))
end

----

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

function each(list, func)
 for _, v in pairs(list) do
  if (not func(v)) return false
 end
 
 return true
end

----

function is_number(var)
 return type(var) == 'number'
end

function is_table(var)
 return type(var) == 'table'
end

----

function to_seconds(ticks)
 return ticks / 30
end

function to_ticks(seconds)
 return seconds * 30
end
-->8
---------
-- oop --
---------

-- https://github.com/rxi/classic
object = {}
object.__index = object

function object:extend()
 local o = {}
 
 for k, v in pairs(self) do
  if sub(k, 1, 2) == '__' then
   o[k] = v
  end
 end
 
 o.__index = o
 o.super = self
 
 return setmetatable(o, self)
end

function object:is(obj)
 local mt = getmetatable(self)
 
 while mt do
  if (mt == obj) return true
  
  mt = getmetatable(mt)
 end
 
 return false
end

----

function object:new()
 -- empty
end

function object:str()
 return 'non-extended object'
end

----

function object:__call(...)
 local o = setmetatable({}, self)
 
 o:new(...)
 
 return o
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

----

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

----

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

--------------------
-- basic geometry --
--------------------

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

----

-- creates an array of 1x1 sprites from ids
function sprite.batch(...)
 local args = {...}
 
 assert(each(args, is_number))
 
 local sprites = {}
 
 -- use all() to preserve order
 for arg in all(args) do
  add(sprites, sprite(arg))
 end
 
 return sprites
end

---------------
-- animation --
---------------

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
 
----
 
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
 
----
 
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
----------------------------
-- tiles, map, and camera --
----------------------------

tile_types = {
 foreground = 0,
 solid      = 1
}

function is_tile_type(x, y, type)
 local mx, my = flr(x/8), flr(y/8)
 
 return fget(mget(mx, my), type)
end

function is_tile_solid(x, y)
 return is_tile_type(x, y, tile_types.solid)
end

-->8
--------------
-- entities --
--------------

world = object:extend()

function world:new()
 self.entities = {}
 
 self.named_entities = {} -- name / e
 self.tagged_entities = {} -- tag / {e1, e2, ..., en}
end

function world:update()
 for e in all(self.entities) do
  e:update()
 end

 -- todo collisions
 
 for e in all(self.entities) do
  if not e.alive then
   self:remove_entity(e)
  end
 end
end

function world:draw()
 for e in all(self.entities) do
  e:draw()
 end
end

----

function world:add_entity(e, name)
 add(self.entities, e)
 
 if name and not self.named_entities[name] then
  self.named_entities[name] = e
 end
 
 if e.tags then
  for t in all(e.tags) do
   if not self.tagged_entities[t] then
    self.tagged_entities[t] = {}
   end
   
   add(self.tagged_entities[t], e)   
  end
 end
end

function world:remove_entity(e)
 del(self.entities, e)
 del(self.named_entities, e)
 
 for t in all(self.tagged_entities) do
  del(self.tagged_entities[t], e)
 end
end

----

function world:get_named_entity(name)
 return self.named_entities[name]
end

function world:get_tagged_entities(tag)
 return self.tagged_entities[tag]
end

----

function world:load_from_map(w, h)
 for i = 1, w do
  for j = 1, h do
   local mx, my = i - 1, j - 1
   
   local tile_id = mget(mx, my)
   
   if fget(tile_id, tile_types.solid) then
    local e = entity(mx * 8, my * 8, sprite(tile_id))
	
	self:add_entity(e)
   end
  end
 end
end

----

function do_entity_collisions()
 for i = 1, #entities - 1 do
  for j = i + 1, #entities do
   local e1, e2 = entities[i], entities[j]
   
   if band(e1.collision_mask, e2.collision_mask) ~= 0 then
    local c1, c2 = e1:get_collider(), e2:get_collider()
	
	if (c1:intersects(c2)) e1:handle_collision(e2)
   end
  end
 end
end

----

entity = object:extend()

function entity:new(x, y, base_sprite, ...)
 self.alive = true
 
 self.position = vector(x or 0, y or 0)
 self.velocity = vector(0, 0)
 
 self.visible = true
 self.base_sprite = base_sprite or sprite(0)
 
 self.collision_mask = 0x1
 self.collider = box(0, 0, 8, 8)
 
 self.tags = {...}
end

function entity:update()
 -- self:do_map_collision()
 self:move()
 
 local a = self:get_animation()
 
 if (a) a:update()
end

function entity:draw()
 if (not self.visible) return
 
 local a = self:get_animation()
 local s = self.base_sprite
 
 if (a) s = a:get_sprite()
 
 s:draw(self.position:unpack())
end

----

function entity:add_animation(name, a)
 if not self.animations then
  self.animations = {}
  self.current_animation = name
 end
  
 self.animations[name] = a
end
 
-- returns name or current_animation
function entity:get_animation(name)
 if (not self.animations) return
 if (name) assert(self.animations[name])
  
 return self.animations[name or self.current_animation]
end
 
function entity:set_animation(name)
 if (self.current_animation == name) return
  
 self.current_animation = name
 self:get_animation():restart()
end
 
----

-- fixme: 8x8 colliders 'skip' on dx, dy > 0
function entity:do_map_collision()
 if (band(self.collision_mask, 0x1) == 0) return
 
 local c = self:get_collider()
 
 local x, y = c.x, c.y
 local w, h = c.w, c.h
 
 local dx, dy = self.velocity:unpack()
 
 local tx, ty = x + dx, y + dy
 
 local mx, my = flr(tx / 8) * 8, flr(ty / 8) * 8
 
 if dx < 0 then
  if is_tile_solid(tx, y) or is_tile_solid(tx, y + h - 1) then
   dx = mx + 8 - x
  end
 elseif dx > 0 then
  if is_tile_solid(tx + w - 1, y) or is_tile_solid(tx + w - 1, y + h - 1) then
   dx = mx - (x - w)
  end
 end
 
 if dy < 0 then
  if is_tile_solid(x, ty) or is_tile_solid(x + w - 1, ty) then
   dy = my + 8 - y
  end
 elseif dy > 0 then
  if is_tile_solid(x, ty + h - 1) or is_tile_solid(x + w - 1, ty + h - 1) then
   dy = my - (y - h)
  end
 end
 
 self.velocity = vector(dx, dy)
end

-- todo: either consolidate map/entity collision or refine
function entity:handle_collision(e)
 local c1 = self:get_collider()
 local c2 = e:get_collider()
 
 local x1, y1 = c1.x, c1.y
 local w1, h1 = c1.w, c1.h
 
 local dx, dy = self.velocity:unpack()
 
 local x2, y2 = c2.x, c2.y
 local w2, h2 = c2.w, c2.h
 
 local tx, ty = self.position:unpack()
 
 if dx < 0 then
  tx = x2 + w2 - (x1 - tx)
 elseif dx > 0 then
  tx = x2 - w1 - (x1 - tx)
 end
 
 if dy < 0 then
  ty = y2 + h2 - (y1 - ty)
 elseif dy > 0 then
  ty = y2 - h1 - (y1 - ty)
 end
 
 -- self:place(tx - (tx - x), ty - (ty - y))
 self:place(tx, ty)
end

----

-- get a properly offset collider
function entity:get_collider()
 local c = self.collider
 
 local x, y = self.position:unpack()
 
 return box(c.x + x, c.y + y, c.w, c.h)
end
 
----

function entity:move()
 -- if (not self.dynamic) return

 self.position += self.velocity
end
 
function entity:place(x, y)
 self.position = vector(x, y)
end
-->8
------------
-- player --
------------

player = entity:extend()

function player:new()
 player.super.new(self, 0, 0, sprite(64))
 
 self:add_animation('idle',   animation(sprite.batch(64, 66, 67, 68), 0.5, false))
 self:add_animation('walk_d', animation(sprite.batch(64, 65)))
 self:add_animation('walk_l', animation(sprite.batch(80, 81, 82)))
 self:add_animation('walk_u', animation(sprite.batch(96, 97, 98)))
 self:add_animation('walk_r', animation(sprite.batch(112, 113, 114)))
 
 self:set_animation('walk_d')
 
 self.idle_threshold = 120
 self.idle_ticks = 0
 
 self.collider = box(2, 4, 4, 4)
end

function player:update()
 local xin = btn(➡️) and 1 or btn(⬅️) and -1 or 0
 local yin = btn(⬇️) and 1 or btn(⬆️) and -1 or 0
 
 if xin ~= 0 or yin ~= 0 then
  self.idle_ticks = 0
  self:get_animation():resume()
  
  if xin > 0 then
   self:set_animation('walk_r')
  elseif xin < 0 then
   self:set_animation('walk_l')
  end
  
  if yin > 0 then
   self:set_animation('walk_d')
  elseif yin < 0 then
   self:set_animation('walk_u')
  end
 else
  self.idle_ticks += 1
  
  if self.idle_ticks >= self.idle_threshold then
   self:set_animation('idle')
  else
   self:get_animation():pause()
  end
 end
 
 self.velocity = vector(xin, yin)

 self.super.update(self)
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
