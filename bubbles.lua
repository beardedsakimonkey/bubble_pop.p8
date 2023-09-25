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

MAX_FAKES=35
DEBUG_FAKES=false
local fake_bbl_colors = {DarkBlue,DarkGray}
local prt_colors = {White,Red,White,Pink,White,Orange,White,Yellow,White,
					Green,White,Blue,Blue,Indigo,DarkBlue,DarkBlue}

function dbg(msg)
	add(dbg_msgs, msg)
end

function _init()
	-- poke(0X5f5c, 255) -- disable key repeat
	poke(0X5f5d, 3) -- key repeat delay
	poke(0x5f2e, 1) -- hidden palette
end

function rnd_fake_color()
	local c = fake_bbl_colors[flr(rnd(#fake_bbl_colors))+1]
	if c==DarkGray and rnd()<0.8 then -- avoid gray
		c = fake_bbl_colors[flr(rnd(#fake_bbl_colors))+1]
	end
	return c
end

function is_fake_with_bg(bbl)
	return bbl.fake and bbl.c==DarkBlue and bbl.max_r>=5
end

function calc_bbl_top(bbl)
	if not bbl.fake then
		return 0
	else
		return 30 + flr(bbl.x<64 and bbl.x*2 or 128-((bbl.x-64)*2))
	end
end

function add_bubbles()
	local num_fakes = 0
	foreach(bbls, function(bbl)
		if bbl.fake then num_fakes += 1 end
	end)
	-- add fakes first for draw order
	if f%30==0 and num_fakes<MAX_FAKES then
		local x = rnd(64)\1 + rnd(64)\1
		if x < 64 then
			x = 64-x
		else
			x = 64-(x-64)+64
		end
		local c = rnd_fake_color()
		local bbl= {
			x=x, y=130,
			dx=nil, dy=nil,
			r=0,
			a=0,
			c=c,
			p=rnd(), -- period offset
			fake=true,
			max_r=c==DarkGray and 1 or (rnd()<0.8 and 8 or 2),
			top=nil,
		}
		bbl.top = calc_bbl_top(bbl)
		-- add bg fakes first
		add(bbls, bbl, is_fake_with_bg(bbl) and 1 or #bbls+1)
	end
	if f%5==0 and rnd()<0.9 then
		add(bbls, {
			x=64+flr(rnd(64))-32,
			y=130,
			dx=nil, dy=nil,
			r=0,
			a=0,
			c=Blue,
			p=rnd(),
			fake=false,
			max_r=999,
			top=0,
		})
	end
end

function clamp(v, a, b)
	return min(max(a, v), b)
end

function update_bubbles()
	for i,bbl in ipairs(bbls) do
		local a = bbl.fake and bbl.a/4 or bbl.a
		bbl.dx = cos(a/360*4) * sin(a/360)
		bbl.dy = (cos(bbl.p + a/180*4) * sin(bbl.p + a/180))/4 - 2*bbl.p
		if bbl.fake then
			bbl.dx /= DEBUG_FAKES and 1 or 8
			bbl.dy /= DEBUG_FAKES and 1 or 8
		end
		bbl.x += bbl.dx
		bbl.y += bbl.dy
		local v = bbl.fake and 125 or 130
		local ro = bbl.c==DarkGray and -1 or
					is_fake_with_bg(bbl) and 0 or 0
		bbl.r = clamp((v-min(v,bbl.y))/8 + ro, 0, bbl.max_r)
		bbl.a += 1
		bbl.top = calc_bbl_top(bbl)
		if bbl.y+bbl.r < bbl.top then
			del(bbls, bbl)
		end
	end
end

function add_particles(bbl)
	for i=1,bbl.r*4 do
		local r = rnd()
		local xoff = cos(r) * bbl.r
		local yoff = sin(r) * bbl.r
		add(prts, {
			x=bbl.x+xoff,
			y=bbl.y+yoff,
			dx=(xoff>0 and 1 or -1) * rnd(bbl.r/4),
			dy=(yoff>0 and 1 or -1) * rnd(bbl.r/4),
			c=12,
			a=1,
			max_a=10+rnd(4),
		})
	end
end

function update_particles()
	for prt in all(prts) do
		prt.x += prt.dx
		prt.y += prt.dy
		prt.a += 1
		if prt.a >= prt.max_a then
			del(prts, prt)
		else
			prt.c = prt_colors[1+ flr(prt.a/prt.max_a * #prt_colors)]
		end
	end
end

function highest_bubble()
	local highest = nil
	foreach(bbls, function(bbl)
		if bbl.fake then return end
		if not highest or bbl.y<highest.y then
			highest = bbl
		end
	end)
	return highest
end

function _update()
	dbg_msgs={}
	if btnp(🅾️) and #bbls>0 then -- pop bubble
		local bbl = highest_bubble()
		if bbl then
			add_particles(bbl)
			del(bbls, bbl)
		end
	end
	add_bubbles()
	update_bubbles()
	update_particles()
	f+=1
end

function draw_bubbles()
	foreach(bbls, function(bbl)
		if DEBUG_FAKES and not bbl.fake then return end
		local fake_with_bg = is_fake_with_bg(bbl)
		if DEBUG_FAKES and bbl.fake then
			pset(bbl.x, bbl.top, Green)
		end
		if not bbl.fake or fake_with_bg then -- draw fill
			if bbl.r<=2 then -- avoid flicker
				circ(bbl.x, bbl.y, bbl.r, bbl.c)
			else
				fillp(▒)
				circfill(bbl.x, bbl.y, bbl.r, bbl.fake and bbl.c or DarkBlue)
				fillp(0)
			end
		end
		if not fake_with_bg then -- draw outline
			circ(bbl.x, bbl.y, bbl.r, bbl.c)
		else
			circ(bbl.x, bbl.y, bbl.r+1, DarkPurple)
		end
		-- sparkle
		if bbl.r>3 and not bbl.fake then
			local r = min(1, bbl.r/6)
			circ(
				flr(bbl.x)+flr(bbl.r)/2,
				ceil(bbl.y)-flr(bbl.r)/2,
				r, 7)
		end
		pal(0)
		fillp(0)
	end)
end

function draw_particles()
	for prt in all(prts) do
		pset(prt.x, prt.y, prt.c)
	end
end

function _draw()
	pal(DarkPurple, 129, 1)
	cls(DarkPurple)
	draw_bubbles()
	draw_particles()
	cursor(0, 0, 9); for msg in all(dbg_msgs) do print(msg) end
end
