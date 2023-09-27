Black,DarkBlue,DarkPurple,DarkGreen,Brown,DarkGray,LightGray,White,Red,Orange,
Yellow,Green,Blue,Indigo,Pink,Peach = 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

bbls={}
prts={}
prt_themes = {}
f=0
popped=0
BG=Brown

function dbg(msg)
	add(dbg_msgs, msg)
end

function _init()
	poke(0X5f5d, 8) -- key repeat delay
	poke(0x5f2e, 1) -- hidden palette
	music(0)
	init_particle_themes()
end

function calc_top(bbl)
	return not bbl.fake and 0 or
	       flr(bbl.x<64 and bbl.x*2 or 128-((bbl.x-64)*2))
end

function gen_fake_x()
	local x = rnd(64)\1 + rnd(64)\1
	return x<64 and 64-x or 64-(x-64)+64
end

function count_bubbles()
	local fake, real = 0, 0
	foreach(bbls, function(bbl)
		if bbl.dead_t then return end
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
	while num_fake<44 do
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
			dead_t=nil,
		})
	end
end

function update_bubbles()
	for bbl in all(bbls) do
		if bbl.dead_t then bbl.dead_t+=1 end
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

function draw_fake_bubble(bbl)
	circfill(bbl.x, bbl.y, bbl.r, BG)
	circ(bbl.x, bbl.y, bbl.r, bbl.c)
end

function draw_real_bubble(bbl)
	local r = bbl.r-(bbl.dead_t or 0)
	if r>2 then -- avoid flicker
		fillp(▒)
		circfill(bbl.x, bbl.y, r, DarkBlue)
		fillp(0)
	end
	circ(bbl.x, bbl.y, r, bbl.dead_t and White or bbl.c)
	-- sparkle
	if r>3 then
		local sr = mid(r\6, 0, 1)
		circ(flr(bbl.x)+r/2,
		     ceil(bbl.y)-r/2,
		     sr, LightGray)
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

-- particles -------------------------------------------------------------------

function init_particle_themes()
	local theme_cores = {
		{Red,Pink,Orange},
		{Yellow,Green,DarkGreen},
		{Blue,Indigo,Peach},
	}
	for theme_core in all(theme_cores) do
		local theme = {}
		for _=1,3 do
			for i,c in ipairs(theme_core) do
				add(theme, c)
				if i%3==0 then
					add(theme, White)
				end
			end
		end
		for _=1,8 do
			add(theme, DarkBlue)
		end
		add(prt_themes, theme)
	end
end

function spawn_particles(bbl)
	local theme = prt_themes[popped % #prt_themes + 1]
	for _=1, max(5, bbl.r*3) do
		local v = rnd()
		local xoff = cos(v)*bbl.r
		local yoff = sin(v)*bbl.r
		local r = rnd(2)\1
		add(prts, {
			x=bbl.x+xoff,
			y=bbl.y+yoff,
			dx=rnd(bbl.r/8) * (2-r+1)/2 * (xoff>0 and 1 or -1),
			dy=rnd(bbl.r/8) * (2-r+1)/2 * (yoff>0 and 1 or -1),
			r=r,
			c=nil,
			theme=theme,
			t=0,
			max_t=20+rnd(10)\1,
		})
	end
end

function update_particles()
	for prt in all(prts) do
		prt.x += prt.dx
		prt.y += prt.dy
		prt.t += 1
		prt.c = prt.theme[flr(prt.t/prt.max_t * #prt.theme)+1]
		if prt.r==1 and (prt.t/prt.max_t)>0.4 then
			prt.r = 0
		end
		if prt.t >= prt.max_t then
			del(prts, prt)
		end
	end
end

function draw_particles()
	for prt in all(prts) do
		circfill(prt.x, prt.y, prt.r, prt.c)
	end
end

--------------------------------------------------------------------------------

function highest_bubble()
	local highest
	foreach(bbls, function(bbl)
		if bbl.fake or bbl.dead_t then return end
		if not highest or bbl.y<highest.y then
			highest = bbl
		end
	end)
	return highest
end

function pop_bubble()
	local bbl = highest_bubble()
	if bbl then
		popped+=1
		bbl.dead_t=0
		sfx(3)
	end
end

function _update()
	dbg_msgs={}
	for bbl in all(bbls) do
		if bbl.dead_t==4 then
			spawn_particles(bbl)
			del(bbls, bbl)
		end
	end
	if btnp(🅾️) or btnp(❎) then
		pop_bubble()
	end
	spawn_bubbles()
	update_bubbles()
	update_particles()
	f+=1
end

function draw_plants()
	local w, h, scale = 25, 30, 1.4
	sspr(8, 0, w, h, 94, 128-flr(h*scale), w*scale, h*scale, true)
	sspr(8, 0, w, h, 0, 128-h, w, h)
end

function _draw()
	pal(BG, 129, 1)
	cls(BG)
	draw_bubbles()
	draw_particles()
	draw_plants()
	print(popped, 127-(#tostring(popped)*4), 2, DarkBlue)
	cursor(0, 0, 9); for msg in all(dbg_msgs) do print(msg) end
end
