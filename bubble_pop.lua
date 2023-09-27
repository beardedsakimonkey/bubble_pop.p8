Black,DarkBlue,DarkPurple,DarkGreen,Brown,DarkGray,LightGray,White,Red,Orange,
Yellow,Green,Blue,Indigo,Pink,Peach = 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

bbls={}
prts={}
prt_themes = {}
f=0
cartdata('tubeman_bubble_pop')
score=dget(0) or 0
BG=Brown

function _init()
	poke(0X5f5d, 8) -- key repeat delay
	poke(0x5f2e, 1) -- hidden palette
	music(0)
	init_particle_themes()
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
		local x = rnd(64)\1 + rnd(64)\1
		local bbl= {
			x=x<64 and 64-x or 64-(x-64)+64, y=130,
			dx=nil, dy=nil,
			r=0, max_r=rnd(4)\1,
			t=0,
			fake=true,
			p=rnd(), -- phase offset
		}
		add(bbls, bbl, 1)
	end

	if f%flr(sqrt(num_real)*2)==0 then
		add(bbls, {
			x=64+flr(rnd(64))-32, y=130,
			dx=nil, dy=nil,
			r=0, max_r=999,
			t=0,
			fake=false,
			p=rnd(),
			dead_t=nil,
		})
	end
end

function update_bubbles()
	for bbl in all(bbls) do
		if (bbl.dead_t) bbl.dead_t+=1
		local t = bbl.fake and bbl.t/4 or bbl.t
		local slow = bbl.fake and 8-bbl.max_r or 2
		bbl.dx = cos(bbl.p+t/360*4) * sin(bbl.p+t/360) / slow
		bbl.dy = (cos(bbl.p+t/180*4) * sin(bbl.p+t/180))/4 - 2*bbl.p / slow
		if (not bbl.fake) bbl.dy = min(-0.2, bbl.dy)
		bbl.x += bbl.dx
		bbl.y += bbl.dy
		local v = bbl.fake and 125 or 130
		bbl.r = mid(
			(v - min(v, bbl.y))\8,
			0, bbl.max_r)
		bbl.t += 1
		local top = not bbl.fake and 0
		            or flr(bbl.x<64 and bbl.x*2 or 128-((bbl.x-64)*2))
		if bbl.y+bbl.r < top then
			del(bbls, bbl)
		end
	end
end

function draw_fake_bubble(bbl)
	circfill(bbl.x, bbl.y, bbl.r, BG)
	circ(bbl.x, bbl.y, bbl.r, DarkBlue)
end

function draw_real_bubble(bbl)
	local r = bbl.r-(bbl.dead_t or 0)
	fillp(▒)
	circfill(bbl.x, bbl.y, r, DarkBlue)
	fillp(0)
	circ(bbl.x, bbl.y, r, bbl.dead_t and White or Blue)
	-- sparkle
	if r>3 then
		local sr = mid(r\6, 0, 1)
		circ(flr(bbl.x)+r/2,
		     ceil(bbl.y)-r/2,
		     sr, LightGray)
	end
end

function draw_bubbles()
	for bbl in all(bbls) do
		if bbl.fake then
			draw_fake_bubble(bbl)
		else
			draw_real_bubble(bbl)
		end
	end
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
		for _=1,3 do
			add(theme, DarkBlue)
		end
		add(prt_themes, theme)
	end
end

function spawn_particles(bbl)
	local theme = prt_themes[score % #prt_themes + 1]
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
			max_t=5+rnd(20)\1,
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
		if (bbl.fake or bbl.dead_t) return
		if not highest or bbl.y<highest.y then
			highest = bbl
		end
	end)
	return highest
end

function pop_bubble()
	local bbl = highest_bubble()
	if bbl then
		score+=1
		bbl.dead_t=0
		sfx(3)
		dset(0, score)
	end
end

function _update()
	for bbl in all(bbls) do
		if bbl.dead_t==4 then
			spawn_particles(bbl)
			del(bbls, bbl)
		end
	end
	if (btnp(🅾️)) pop_bubble()
	if (btnp(❎)) pop_bubble()
	spawn_bubbles()
	update_bubbles()
	update_particles()
	f+=1
end

function _draw()
	pal(BG, 129, 1)
	cls(BG)
	draw_bubbles()
	draw_particles()
	print(score, 127-(#tostring(score)*4), 2, DarkBlue)
end
