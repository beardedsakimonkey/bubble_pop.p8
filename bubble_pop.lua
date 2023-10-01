Black,DarkBlue,DarkPurple,DarkGreen,Brown,DarkGray,LightGray,White,Red,Orange,
Yellow,Green,Blue,Indigo,Pink,Peach = 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
BG=Brown

function _init()
	cartdata('tubeman_bubble_pop')
	poke(0X5f5d, 8) -- key repeat delay
	poke(0x5f2e, 1) -- hidden palette
	music(0)

	bbls={}
	prts={}
	prt_themes=init_particle_themes()
	t=0
	score=dget(0) or 0
	multipop,speedup=1,2
	ctrls={
		[multipop]={spr=1, v=0},
		[speedup]={spr=0, v=0},
	}
	sel=1
end

-- bubbles ---------------------------------------------------------------------

function count_bubbles()
	local fake,real = 0,0
	foreach(bbls, function(bbl)
		if (bbl.dead_t) return
		if bbl.fake then
			fake+=1
		else
			real+=1
		end
	end)
	return fake,real
end

function spawn_bubbles()
	local num_fake,num_real = count_bubbles()
	while num_fake<44 do
		num_fake+=1
		local x = rnd(64)\1 + rnd(64)\1
		local bbl= {
			x=x<64 and 64-x or 64-(x-64)+64, y=130,
			dx=nil, dy=nil,
			r=0, max_r=rnd(4)\1,
			t=0,
			fake=true,
			p=rnd(), -- phase offset
			draw=draw_fake_bubble,
		}
		add(bbls, bbl, 1)
	end

	if t%(sqrt(num_real)*2\(ctrls[speedup].v+1))==0 then
		add(bbls, {
			x=64+flr(rnd(64))-32, y=130,
			dx=nil, dy=nil,
			r=0, max_r=999,
			t=0,
			fake=false,
			p=rnd(),
			dead_t=nil,
			draw=draw_real_bubble,
		})
	end
end

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

function pop_bubbles()
	for _=1,1<<ctrls[multipop].v do
		local bbl = highest_bubble()
		if bbl then
			score+=1
			bbl.dead_t=0
			sfx(3)
			dset(0, score)
		end
	end
end

function update_bubble(bbl)
	if (bbl.dead_t) bbl.dead_t+=1
	local t = bbl.fake and bbl.t/4 or bbl.t
	local slow = bbl.fake and 8-bbl.max_r or 4>>>ctrls[speedup].v
	bbl.dx = cos(bbl.p+t/360*4) * sin(bbl.p+t/360) / slow
	bbl.dy = (cos(bbl.p+t/180*4) * sin(bbl.p+t/180))/4 - 2*bbl.p / slow
	if (not bbl.fake) bbl.dy = min(-0.4, bbl.dy)
	bbl.x += bbl.dx
	bbl.y += bbl.dy
	local v = bbl.fake and 125 or 130
	bbl.r = mid((v - min(v, bbl.y))\8, 0, bbl.max_r)
	bbl.t += 1
	local top = bbl.fake and flr(bbl.x<64 and bbl.x*2 or 128-((bbl.x-64)*2))
	            or 0
	if bbl.y+bbl.r < top then
		del(bbls, bbl)
	end
end

function update_bubbles()
	if (btnp(🅾️)) pop_bubbles()
	if (btnp(❎)) pop_bubbles()
	foreach(bbls, update_bubble)
	spawn_bubbles()
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
		circ(flr(bbl.x)+r/2,
		     ceil(bbl.y)-r/2,
		     mid(r\8, 0, 1),
			 LightGray)
	end
end

function draw_bubbles()
	for bbl in all(bbls) do
		bbl:draw()
	end
end

-- particles -------------------------------------------------------------------

function init_particle_themes()
	local themes = {}
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
				if (i%3==0) add(theme, White)
			end
		end
		for _=1,3 do
			add(theme, DarkBlue)
		end
		add(themes, theme)
	end
	return themes
end

function spawn_particle(bbl)
	if (bbl.dead_t~=4) return
	del(bbls, bbl)
	local i = ctrls[multipop].v==0 and (score%#prt_themes) or rnd(#prt_themes)\1
	local theme = prt_themes[i+1]
	for _=1, max(8, bbl.r*3) do
		local v = rnd()
		local xoff = cos(v)*bbl.r
		local yoff = sin(v)*bbl.r
		local r = rnd(2)\1
		add(prts, {
			x=bbl.x+xoff,
			y=bbl.y+yoff,
			dx=max(0.4,rnd(bbl.r/8)) * (2-r+1)/2 * (xoff>0 and 1 or -1),
			dy=max(0.4,rnd(bbl.r/8)) * (2-r+1)/2 * (yoff>0 and 1 or -1),
			r=r,
			c=nil,
			theme=theme,
			t=0,
			max_t=5+rnd(20)\1,
		})
	end
end

function update_particle(prt)
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

function update_particles()
	foreach(prts, update_particle)
	foreach(bbls, spawn_particle)
end

function draw_particles()
	for prt in all(prts) do
		circfill(prt.x, prt.y, prt.r, prt.c)
	end
end

-- controls --------------------------------------------------------------------

function update_controls()
	if (btnp(➡️)) ctrls[sel].v=min(ctrls[sel].v+1, 3)
	if (btnp(⬅️)) ctrls[sel].v=max(ctrls[sel].v-1, 0)
	if (btnp(⬆️)) sel=max(sel-1, 1)
	if (btnp(⬇️)) sel=min(sel+1, #ctrls)
end

function draw_control(i, _x, _y)
	if (i~=sel) pal({[LightGray]=DarkBlue, [Green]=DarkGray})
	local x,y = _x,_y
	print('◀', x+(i==sel and btn(⬅️) and -1 or 0), y, LightGray); x+=8
	spr(ctrls[i].spr, x, y-1); x+=11
	print('▶', x+(i==sel and btn(➡️) and 1 or 0), y, LightGray)
	x,y=_x+4,_y+7
	local v = ctrls[i].v
	for j=1,3 do
		local x = x+(j-1)*5
		line(x, y, x+3, y, v>=j and Green or DarkBlue)
	end
	pal(0)
end

function draw_controls()
	for i=1,#ctrls do
		draw_control(i, 2, 3+14*(i-1))
	end
end

--------------------------------------------------------------------------------

function _update()
	t+=1
	update_controls()
	update_bubbles()
	update_particles()
end

function _draw()
	pal(BG, 129, 1)
	cls(BG)
	draw_bubbles()
	draw_controls()
	print(score, 127-(#tostring(score)*4), 2, DarkBlue)
	draw_particles()
end
