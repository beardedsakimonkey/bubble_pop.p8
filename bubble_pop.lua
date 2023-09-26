-- TODO:
-- - big particles
-- - unique particle color per bubble
-- - slow start bubble spawning
-- - white bubble outline on pop

Black      = 0
DarkBlue   = 1
DarkPurple = 2
DarkGreen  = 3
Brown      = 4
DarkGray   = 5
LightGray  = 6
White      = 7
Red        = 8
Orange     = 9
Yellow     = 10
Green      = 11
Blue       = 12
Indigo     = 13
Pink       = 14
Peach      = 15

bbls={}
prts={}
f=0

max_fake=44
min_top=0
prt_colors = {White,Red,White,Pink,White,Orange,White,Yellow,White,
              Green,White,Blue,Blue,Indigo,DarkBlue,DarkBlue}

function dbg(msg)
	add(dbg_msgs, msg)
end

function _init()
	poke(0X5f5d, 3) -- key repeat delay
	poke(0x5f2e, 1) -- hidden palette
end

function calc_top(bbl)
	return not bbl.fake and 0 or
	       min_top + flr(bbl.x<64 and bbl.x*2 or 128-((bbl.x-64)*2))
end

function gen_fake_x()
	local x = rnd(64)\1 + rnd(64)\1
	return x<64 and 64-x or 64-(x-64)+64
end

function count_bubbles()
	local fake, real = 0, 0
	foreach(bbls, function(bbl)
		if bbl.fake then
			fake+=1
		else
			real+=1
		end
	end)
	return fake, real
end

-- bubbles ---------------------------------------------------------------------

function spawn_bubbles()
	local num_fake, num_real = count_bubbles()
	while num_fake<max_fake do
		num_fake += 1
		local bbl= {
			x=gen_fake_x(), y=130,
			dx=nil, dy=nil,
			r=0, max_r=rnd(4)\1,
			t=0,
			c=DarkBlue,
			fake=true,
			p=rnd(), -- phase offset
			top=nil,
		}
		add(bbls, bbl, 1)
	end

	if f%(5+flr(sqrt(num_real)*2))==0 then
		add(bbls, {
			x=64+flr(rnd(64))-32, y=130,
			dx=nil, dy=nil,
			r=0, max_r=999,
			t=0,
			c=Blue,
			fake=false,
			p=rnd(),
			top=0,
		})
	end
end

function update_bubbles()
	for bbl in all(bbls) do
		local t = bbl.fake and bbl.t/4 or bbl.t
		local slow = bbl.fake and 8-bbl.max_r or 2
		bbl.dx = cos(bbl.p+t/360*4) * sin(bbl.p+t/360) / slow
		bbl.dy = (cos(bbl.p+t/180*4) * sin(bbl.p+t/180))/4 - 2*bbl.p / slow
		bbl.x += bbl.dx
		bbl.y += bbl.dy
		local v = bbl.fake and 125 or 130
		bbl.r = mid(
			(v - min(v, bbl.y))\8,
			0, bbl.max_r)
		bbl.t += 1
		bbl.top = calc_top(bbl)
		if bbl.y+bbl.r < bbl.top then
			del(bbls, bbl)
		end
	end
end

-- particles -------------------------------------------------------------------

function spawn_particles(bbl)
	for _=1, bbl.r*4 do
		local v = rnd()
		local xoff = cos(v)*bbl.r
		local yoff = sin(v)*bbl.r
		add(prts, {
			x=bbl.x+xoff,
			y=bbl.y+yoff,
			dx=(xoff>0 and 1 or -1) * rnd(bbl.r/4),
			dy=(yoff>0 and 1 or -1) * rnd(bbl.r/4),
			c=nil,
			t=0,
			max_a=10+rnd(4),
		})
	end
end

function update_particles()
	for prt in all(prts) do
		prt.x += prt.dx
		prt.y += prt.dy
		prt.t += 1
		prt.c = prt_colors[flr(prt.t/prt.max_a * #prt_colors)+1]
		if prt.t >= prt.max_a then
			del(prts, prt)
		end
	end
end

--------------------------------------------------------------------------------

function highest_bubble()
	local highest
	foreach(bbls, function(bbl)
		if bbl.fake then return end
		if not highest or bbl.y<highest.y then
			highest = bbl
		end
	end)
	return highest
end

function pop_bubble()
	local bbl = highest_bubble()
	if bbl then
		spawn_particles(bbl)
		del(bbls, bbl)
	end
end

function _update()
	dbg_msgs={}
	if btnp(🅾️) then
		pop_bubble()
	end
	spawn_bubbles()
	update_bubbles()
	update_particles()
	f+=1
end

function draw_fake_bubble(bbl)
	circfill(bbl.x, bbl.y, bbl.r, bbl.c)
end

function draw_real_bubble(bbl)
	if bbl.r>2 then -- avoid flicker
		fillp(▒)
		circfill(bbl.x, bbl.y, bbl.r, DarkBlue)
		fillp(0)
	end
	circ(bbl.x, bbl.y, bbl.r, bbl.c)
	-- sparkle
	if not bbl.fake and bbl.r>3 then
		local r = mid(bbl.r\6, 0, 1)
		circ(flr(bbl.x)+bbl.r/2,
		ceil(bbl.y)-bbl.r/2,
		r, LightGray)
	end
end

function draw_bubbles()
	foreach(bbls, function(bbl)
		if bbl.fake then
			draw_fake_bubble(bbl)
		else
			draw_real_bubble(bbl)
		end
	end)
end

function draw_particles()
	for prt in all(prts) do
		pset(prt.x, prt.y, prt.c)
	end
end

function _draw()
	pal(Brown, 129, 1)
	cls(Brown)
	draw_bubbles()
	draw_particles()
	cursor(0, 0, 9); for msg in all(dbg_msgs) do print(msg) end
end
