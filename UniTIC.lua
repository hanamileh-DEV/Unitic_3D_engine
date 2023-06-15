-- title:  UniTIC (3D Engine)
-- author: HanamileH
-- desc:   version 1.3.1
-- By HanamileH | hanamileh@gmail.com | discord: HanamileH#8604
-- script: lua

--we kindly ask you to specify the name of this engine if you use it for your projects

--[[
license:

Copyright 2022-2023 HanamileH
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files
(the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
]]

--[[
The approximate algorithm of the engine:

during initialization:
	saving some necessary variables (math functions, constants, engine settings, etc.)
	saving all data about objects and models in the 'draw' table

during code execution:
	executing 'unitic.render()' (which then executes the necessary functions)

during the execution of 'unitic.render()':
	executing 'unitic.update()' (which performs most of the math calculations)
	drawing the sky and the ground
	executing 'unitic.draw()' (which draws polygons and does some calculations)

during the execution of 'unitic.update()':
	copying all vertices and polygons from 'draw.world' to 'unitic.poly' without changes
	copying vertices from 'draw.objects' to local variables
	doing the necessary calculations and vertex transformations
	saving the processed vertices in 'unitic.poly'
	copying polygons from 'draw.objects' to 'unitic.poly' taking into account the shifted vertex indexes
	rotating all the points in 'unitic.poly' in the right direction (in other words, calculating the rotation of the camera)
	converting the 3d coordinates of the points into 2d

during the execution of 'unitic.draw()':
	copying the necessary values to local variables
	calculating the actual normal of the polygon
	making sure that the polygon should be drawn
	drawing a polygon if it meets the conditions above
]]

local F,min,max = math.floor,math.min,math.max
local pi  = math.pi
local pi2 = math.pi/2
local rad = math.pi*2

-- Functions that may be useful
local function clamp(val, min_val, max_val) return val<min_val and min_val or val>max_val and max_val or val end
local function AABB_coll(x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4) return x1 < x4 and x2 > x3 and y1 < y4 and y2 > y3 and z1 < z4 and z2 > z3 end --AABB collision
-- Camera
local cam = {
	x = 0, y = 128, z = -256, --camera position
	tx = 0, --turning the camera up and down
	ty = pi --turning the camera left and right
}

-- Engine settings:
local unitic = {
	version = "1.3.2",    -- Engine version
	focal_length = 120,   -- Lens distance to camera (the higher the value, the fewer objects fit into the frame)
	draw_wareframe =true, -- Note that this may be slower
	-- Particles
	draw_particles = true,
	particles_type = 1,
	-- If 1, then the particles will be in the form of a circle
	-- If 2, then the particles will be in the form of a square
	-- (does not affect particles with uv)

	-- Background
	sky_color = 11,
	ground_color = 6,
	-- System tables (processed data is stored here)
	poly={}
}

--[[
all polygons are saved here
and by default this table not change

save in the World elements
that will not change

save in Object elements
that will move or rotate

to move or rotate these objects,
change their coordinate values in table

the names are not used by the engine by default 
and are needed for simplified object management

pay attention to how the object models are saved
]]

local draw={
	objects={
		{
		name="UniTIC logo",--object name, not used by the engine
		x=0,y=0,z=0, --object coordinates
		tx=0,ty=0,tz=0, --angle of rotation around the axes
		px=0,py=0,pz=0, --the point of rotation of the object
		draw=true, --whether to display the model
		scale=0.5, --model size
		model={
			v={ --vertexes
				{-64,128,-64}, --X Y Z coordinates
				{-64,0,-64},
				{-64,21,-44},
				{64,128,-64},
				{64,0,-64},
				{64,128,-44},
				{-64,0,-44},
				{-64,127,64},
				{47,128,-44},
				{-64,21,47},
				{64,128,63},
				{-64,0,63},
				{-64,128,47},
				{47,128,47},
				{47,128,-44},
				{47,128,47},
				{-64,128,47},
			},
			f={ --polygons (faces)
				{1,5,2, --vertex id
				uv={ --uv coordinates for textures
					{0,0}, --X Y of the first point
					{0,1},
					{1,0},
					-1}, --background color
					f=3}, --polygon normal
					--[[
						f=0 - polygon is not displayed
						f=1 - standard normal
						f=2 - reverse normal
						f=3 - both sides of the polygon are drawn
					]]
	
				{10,7 ,12,uv={{0,0},{0,1},{1,0},-1},f=3},
				{14,6 ,9 ,uv={{0,0},{0,1},{1,0},-1},f=3},
				{8 ,14,13,uv={{0,0},{0,1},{1,0},-1},f=3},
				{8 ,11,14,uv={{0,0},{0,1},{1,0},-1},f=3},
				{12,8 ,10,uv={{0,0},{0,1},{1,0},-1},f=3},
				{8 ,13,10,uv={{0,0},{0,1},{1,0},-1},f=3},
				{14,15,16,uv={{0,0},{0,1},{1,0},-1},f=3},
				{1 ,4 ,5 ,uv={{0,0},{0,1},{1,0},-1},f=3},
				{10,3 ,7 ,uv={{0,0},{0,1},{1,0},-1},f=3},
				{14,11,6 ,uv={{0,0},{0,1},{1,0},-1},f=3},
				{14,9 ,15,uv={{0,0},{0,1},{1,0},-1},f=3},
			}
			}
		},
		{
			name="UniTIC logo",
			x=0,y=0,z=0,
			tx=0,ty=0,tz=0,
			px=0,py=0,pz=0,
			draw=true,
			scale=1,
			model={
				v={
					{0  ,0   ,0    },
					{0  ,0   ,25.2 },
					{22 ,0   ,12.4 },
					{22 ,0   ,-12.8},
					{0  ,0   ,-25.2},
					{-22,0   ,-12.8},
					{-22,0   ,12.4 },
					{0  ,77.2,0    },
				},
				f={
					{1,2,3,uv={{1,0},{1,1},{2,0},-1},f=2},
					{2,8,3,uv={{1,0},{1,1},{2,0},-1},f=2},
					{1,3,4,uv={{1,0},{1,1},{2,0},-1},f=2},
					{3,8,4,uv={{1,0},{1,1},{2,0},-1},f=2},
					{1,4,5,uv={{1,0},{1,1},{2,0},-1},f=2},
					{4,8,5,uv={{1,0},{1,1},{2,0},-1},f=2},
					{1,5,6,uv={{1,0},{1,1},{2,0},-1},f=2},
					{5,8,6,uv={{1,0},{1,1},{2,0},-1},f=2},
					{1,6,7,uv={{1,0},{1,1},{2,0},-1},f=2},
					{6,8,7,uv={{1,0},{1,1},{2,0},-1},f=2},
					{1,7,2,uv={{1,0},{1,1},{2,0},-1},f=2},
					{7,8,2,uv={{1,0},{1,1},{2,0},-1},f=2},
				}}
		}
	},
	world={
		v={},f={}
	},
	particles = {
	}
}

function unitic.addparticle(x, y, z, vx, vy, vz, ax, ay, az, color_or_uv, size, lifetime)
	--[[
		x, y, z  - particle coordinates
		vx,vy,vz - particle velocity
		ax,ay,az - particle acceleration
		
		color_or_uv - if integer, its used as the color id of the particle
			(the particle is drawn in the form of a circle or rectangle)
			if a table, its used according to the template:
			{{x1,y1},{x2,y2},bg_color} where x1,y1 is the upper left points; x2,y2 is the lower right point

		size - the number or table {height,width} responsible for the size of the particle

		lifetime - the lifetime of the particle in ticks (1/60 sec) after which the particle is removed
	]]

	local particle = {
		cord = {x,y,z},
		vel  = {vx,vy,vz},
		acel = {ax,ay,az},
		p2d  = {-1,0,0},
		size = size,
		lifetime = lifetime,
	}

	if     type(color_or_uv) == "number" then particle.color = color_or_uv
	elseif type(color_or_uv) == "table"  then particle.uv    = color_or_uv end

	table.insert(draw.particles,particle)
end

function unitic.update() -- This is where rotation, scaling and other operations take place
	-- We write all vertices and polygons in the system table
	unitic.poly = {v={},f={}}

	-- First we take vertices and polygons from the draw.world table, simply duplicating the values
	for ind = 1,#draw.world.v do -- Vertices
		unitic.poly.v[ind]={draw.world.v[ind][1],draw.world.v[ind][2],draw.world.v[ind][3]}
	end

	for ind = 1,#draw.world.f do -- Polygons (faces)
		unitic.poly.f[ind]={draw.world.f[ind][1],draw.world.f[ind][2],draw.world.f[ind][3],f=draw.world.f[ind].f,uv=draw.world.f[ind].uv}
	end

	-- We do the same with draw.objects, but before that we rotate, move and scale the objects
	for ind1 = 1,#draw.objects do  --the first loop responsible for the index of the object
		if draw.objects[ind1].draw then --if the object needs to be drawn..
			local vt = #unitic.poly.v --index of the last vertex, its necessary that vertices with the save index for different

			--(so as not to recalculate it again)
			local txsin = math.sin(draw.objects[ind1].tx)
			local txcos = math.cos(draw.objects[ind1].tx)
			local tysin = math.sin(-draw.objects[ind1].ty)
			local tycos = math.cos(-draw.objects[ind1].ty)
			local tzsin = math.sin(draw.objects[ind1].tz)
			local tzcos = math.cos(draw.objects[ind1].tz)

			for ind2 = 1,#draw.objects[ind1].model.v do --the second loop, responsible for the index of the vertex of a particular model

				--vertex coordinates
				local px = draw.objects[ind1].model.v[ind2][1]
				local py = draw.objects[ind1].model.v[ind2][2]
				local pz = draw.objects[ind1].model.v[ind2][3]

				--here there is a rotation (on each plane in turn)

				--temporarily subtract the coordinates of the pivot point so that the model rotates around it
				local a1 = px-draw.objects[ind1].px
				local b1 = py-draw.objects[ind1].py
				local c1 = pz-draw.objects[ind1].pz
				--rotation in the XY plane
				local a2 = a1*tzcos-b1*tzsin
				local b2 = a1*tzsin+b1*tzcos
				local c2 = c1
				--rotation in the XZ plane
				local c3 = c2*tycos-a2*tysin
				local a3 = c2*tysin+a2*tycos
				local b3 = b2
				--rotation in the YZ plane
				px = a3
				py = b3*txcos-c3*txsin
				pz = b3*txsin+c3*txcos
				--scaling and moving the model to the specified location
				px = px*draw.objects[ind1].scale+draw.objects[ind1].px+draw.objects[ind1].x
				py = py*draw.objects[ind1].scale+draw.objects[ind1].py+draw.objects[ind1].y
				pz = pz*draw.objects[ind1].scale+draw.objects[ind1].pz+draw.objects[ind1].z
				--writing down the vertex
				unitic.poly.v[#unitic.poly.v+1] = {px,py,pz}
			end
			--copying the polygons of the objects
			for ind2=1,#draw.objects[ind1].model.f do
			unitic.poly.f[#unitic.poly.f+1] = {
				draw.objects[ind1].model.f[ind2][1]+vt, --don't forget about the offset index of vertices
				draw.objects[ind1].model.f[ind2][2]+vt,
				draw.objects[ind1].model.f[ind2][3]+vt,
				f=draw.objects[ind1].model.f[ind2].f,
				uv=draw.objects[ind1].model.f[ind2].uv}
			end
		end
	end
	
	-- Now rotate the vertices around the camera

	-- A little calculation in advance
	local txsin = math.sin(cam.tx)
	local txcos = math.cos(cam.tx)
	local tysin = math.sin(-cam.ty)
	local tycos = math.cos(-cam.ty)
	
	for ind=1,#unitic.poly.v do
		--[[
			we rotate objects using the same method as above
			but without rotation along the XY plane and with fewer calculation
		]]
		local a1 = unitic.poly.v[ind][1]-cam.x
		local b1 = unitic.poly.v[ind][2]-cam.y
		local c1 = unitic.poly.v[ind][3]-cam.z

		local c2 = c1*tycos-a1*tysin -- Intermediate value (so as not to count twice)

		local a3 = c1*tysin+a1*tycos
		local b3 = b1*txcos-c2*txsin
		local c3 = b1*txsin+c2*txcos

		-- Convert 3D to 2D
		local c4 = min(c3, -0.001) --because dividing by 0 is not the best idea

		local x0 = unitic.focal_length * a3 / c4 + 120
		local y0 = unitic.focal_length * b3 / c4 + 68

		unitic.poly.v[ind] = {x0, y0, -c4, c3<0}
	end
end

function unitic.particle_update() -- All things with particles
	if #draw.particles == 0 then return end
	local i = 1
	
	local txsin = math.sin(cam.tx)
	local txcos = math.cos(cam.tx)
	local tysin = math.sin(-cam.ty)
	local tycos = math.cos(-cam.ty)
	repeat
		local cur_part = draw.particles[i] -- Current particle

		-- Lifetime
		cur_part.lifetime = cur_part.lifetime - 1

		if cur_part.lifetime <=0 then table.remove(draw.particles,i) else
			-- Coordinates update
			cur_part.cord[1] = cur_part.cord[1] + cur_part.vel[1]
			cur_part.cord[2] = cur_part.cord[2] + cur_part.vel[2]
			cur_part.cord[3] = cur_part.cord[3] + cur_part.vel[3]
			
			cur_part.vel[1] = cur_part.vel[1] + cur_part.acel[1]
			cur_part.vel[2] = cur_part.vel[2] + cur_part.acel[2]
			cur_part.vel[3] = cur_part.vel[3] + cur_part.acel[3]

			-- Convert 3D to 2D
			
			local a1 = cur_part.cord[1] - cam.x
			local b1 = cur_part.cord[2] - cam.y
			local c1 = cur_part.cord[3] - cam.z

			local c2 = c1*tycos-a1*tysin -- Intermediate value (so as not to count twice)

			local a3 = c1*tysin+a1*tycos
			local b3 = b1*txcos-c2*txsin
			local c3 = b1*txsin+c2*txcos

			local c4 = min(c3, -0.001) --because dividing by 0 is not the best idea

			local x0 = unitic.focal_length * a3 / c4 + 120
			local y0 = unitic.focal_length * b3 / c4 + 68

			cur_part.p2d = {x0, y0, -c4, c3<0}
			--
			i = i + 1
		end
	until i>=#draw.particles
end

function unitic.draw() --polygons are drawn here
	for i = 1,#unitic.poly.f do --the loop responsible for the polygon index
		local poly = unitic.poly.f[i]

		local v_ind = {poly[1],poly[2],poly[3]} --index of the vertices of this polygon

		local v ={unitic.poly.v[v_ind[1]], unitic.poly.v[v_ind[2]], unitic.poly.v[v_ind[3]]} -- vertexes
		--coordinates of polygon points
		local px = {v[1][1],v[2][1],v[3][1]}
		local py = {v[1][2],v[2][2],v[3][2]}
		local pz = {v[1][3],v[2][3],v[3][3]}
		local pz2= {v[1][4],v[2][4],v[3][4]}

		-- UV textures
		local uv = poly.uv

		-- Are the points of the triangle clockwise or counterclockwise
		local tri_points=(px[2]-px[1])*(py[3]-py[1])-(px[3]-px[1])*(py[2]-py[1])>0

		local draw_tri = (poly.f==3) or (tri_points == (poly.f==1)) -- A little pinch of magic

		-- We exclude polygons that should not be visible
		if draw_tri and
			(pz2[1] or pz2[2] or pz2[3]) and -- Checking if all Z coordinates are behind the screen
			(px[1]>0   or px[2]>0   or px[3]>0)and
			(py[1]>0   or py[2]>0   or py[3]>0) and
			(px[1]<240 or px[2]<240 or px[3]<240) and
			(py[1]<136 or py[2]<136 or py[3]<136)
		then
			ttri(
				px[1],py[1],
				px[2],py[2],
				px[3],py[3],

				uv[1][1],uv[1][2],
				uv[2][1],uv[2][2],
				uv[3][1],uv[3][2],
				0,uv[4],
				pz[1],pz[2],pz[3])
		end
	end

	-- Duplicate the code above in order to draw all this on top
	if unitic.draw_wareframe then
		for i = 1,#unitic.poly.f do
			local poly = unitic.poly.f[i]
			local v_ind = {poly[1],poly[2],poly[3]}
			local v = {unitic.poly.v[v_ind[1]], unitic.poly.v[v_ind[2]], unitic.poly.v[v_ind[3]]}

			local px = {v[1][1],v[2][1],v[3][1]}
			local py = {v[1][2],v[2][2],v[3][2]}
	
			trib(
				px[1],py[1],
				px[2],py[2],
				px[3],py[3],0)
		end
	end

	-- Drawing particles
	if not unitic.draw_particles then return end
	for i = 1,#draw.particles do
		local part = draw.particles[i]
		local x,y,z = F(part.p2d[1]), F(part.p2d[2]),part.p2d[3]

		if part.p2d[4] and x>-1 and y>-1 and x<240 and y<136 then
			if part.color then
				--[[
					Quite a trick way to determine whether a particle
					should be drawnm or whether its on the back Z layer.
				]]
				local color_1 = peek4(x+y*240)
				local color_2 = peek4(0x04000)
				poke4(0x04000, color_1%16 + 1)
				ttri(
					x  ,y  ,
					x+1,y  ,
					x  ,y+1,
					0,0,
					1,0,
					0,1,
					0, -1,
					z,z,z
				)

				if peek4(x+y*240) ~= color_1 then
					local size_coef = 128 / z

					if unitic.particles_type == 1 then -- circle or ellipse
						if type(part.size)=="table" then
							elli(x,y,part.size[1]*size_coef,part.size[2]*size_coef,part.color)
						else
							circ(x,y, part.size*size_coef, part.color)
						end
					elseif unitic.partilces_type == 2 then --rect or square
						local size = type(part.size)=="table" and part.size or {part.size,part.size}

						rect(x-size[1]//2, y-size[2]//2, size[1]*size_coef, size[2]*size_coef, part.color)
					end
				end

				poke4(0x04000,color_2)
			elseif part.uv then
				-- todo
			end
		end
	end
end

function unitic.render()
	--updating objects
	unitic.update()
	unitic.particle_update()
	--sky display (optional)
	cls(unitic.sky_color)
	--this complicated math just makes the height of the ground proportionally equal to the angle of rotation of the camera
	local ground_height = min(max(68.5-134*cam.tx,0),136)
	rect(0,ground_height,240,137-ground_height,unitic.ground_color)
	--drawing triangles and particles
	unitic.draw()
end


-- Demoscene

local speed = 4 --player speed

function TIC()
	poke(0x7FC3F,1,1)
	--an example of how to make the camera move
	--(many elements are not perfect)
	local mx,my=mouse()
	--W A S D
	if key(23) then cam.z=cam.z-math.cos(cam.ty)*speed     cam.x=cam.x-math.sin(cam.ty)*speed     end
	if key(19) then cam.z=cam.z+math.cos(cam.ty)*speed     cam.x=cam.x+math.sin(cam.ty)*speed     end
	if key(1)  then cam.z=cam.z-math.cos(cam.ty-pi2)*speed cam.x=cam.x-math.sin(cam.ty-pi2)*speed end
	if key(4)  then cam.z=cam.z+math.cos(cam.ty-pi2)*speed cam.x=cam.x+math.sin(cam.ty-pi2)*speed end
	if key(64) then speed=16 else speed=4 end
	if key(48) then cam.y=cam.y+speed end
	if key(63) then cam.y=cam.y-speed end
	-- Camera stuff
	cam.tx=cam.tx+my/50
	cam.ty=cam.ty+mx/50


	cam.y = max(cam.y,128)
	-- Camera rotation restriction
	cam.ty = cam.ty % rad
	cam.tx = clamp(cam.tx, -pi2, pi2)
	-- Object update
	draw.objects[1].y = 86 + math.sin(time()/250)*24
	draw.objects[1].ty = time()/250

	--unitic.addparticle(0,0,0,math.random()*2-1, math.random()*5, math.random()*2-1, 0,0,0, 2, 5, 50)
	-- Render
	unitic.render()
	-- Debug text
	local debug_text = {
		string.format("UniTIC v %s",tostring(unitic.version)),
		string.format("v: %i f: %i", #unitic.poly.v, #unitic.poly.f),
		string.format("X: %0.1f Y: %0.1f Z: %0.1f", cam.x, cam.y, cam.z),
		string.format("Camera: %0.1f %0.1f",math.deg(cam.tx), math.deg(cam.ty)),
	}

	for i = 1,#debug_text do
		local text = debug_text[i]
		local text_len = print(text, 240, 0)
		rect(0,(i-1)*8,text_len+1,8,15)
		print(text,1,(i-1)*8+2,0)
		print(text,1,(i-1)*8+1,12)
	end

end
-- <TILES>
-- 000:ef1122330011223344556677445566778899aabb8899aabbccddeeffccddeeff
-- 010:1111111111111111111111111111111111111111111111111111111111111111
-- 011:1111111111111111111111111111111111111111111111111111111111111111
-- 012:11111111111111111111111111111111111111ee1111eeee11eeeeeeeeeeeeee
-- 013:11111111111111111111111111111111ee111111eeee1111eeeeee11eeeeeeee
-- 014:1111111111111111111111111111111111111111111111111111111111111111
-- 015:1111111111111111111111111111111111111111111111111111111111111111
-- 016:1111111171117171717171717171711771171717171711711717171111777171
-- 026:1111111111111111111111111111111111111111111111111111111111111111
-- 027:111111ee1111eeee111eeeee1111eeeeee1111e1eeee1111eeeeee11eeeeeeee
-- 028:eeeeee11eeee1111ee111111e111111111111111111111111111111111111111
-- 029:11eeeeee1111eeee111111ee1111111111111111111111111111111111111111
-- 030:ee111111eeee1111eeeeee11eeeeeeee11eeeeee1111eeee1111eeee1111eeee
-- 031:1111111111111111111111111111111111111111111111111111111111111111
-- 042:1111111111111111111111111111111111111111111111111111111111111111
-- 043:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 044:ee111111eeee1111eeeeee11eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 045:1111111111111111111111111111111111111111111111111111111111111111
-- 046:1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee
-- 047:1111111111111111111111111111111111111111111111111111111111111111
-- 058:1111111111111111111111111111111111111111111111111111111111111111
-- 059:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 060:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 061:1111111111111111111111111111111111111111111111111111111111111111
-- 062:1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee1111eeee11eeeeee
-- 063:1111111111111111111111111111111111111111111111111111111111111111
-- 074:1111111111111111111111111111111111111111111111111111111111111111
-- 075:eeeeeeee11eeeeee1111eeee111111ee11111111111111111111111111111111
-- 076:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee11eeeeee1111eeee111111ee
-- 077:11111111111111ee1111eeee11eeeeee11eeeeee11eeee1111ee111111111111
-- 078:eeeeeeeeeeeeee11eeee1111ee11111111111111111111111111111111111111
-- 079:1111111111111111111111111111111111111111111111111111111111111111
-- 090:1111111111111111111111111111111111111111111111111111111111111111
-- 091:1111111111cc1cc111cc1cc111cc1cc111cc1cc1110ccc011110001111111111
-- 092:11111111111111cccccc1100cc0cc1cccc1cc1cccc1cc1cc0010010011111111
-- 093:111111111cccc1cc10cc010c11cc111c11cc111c11cc11cc1100110011111111
-- 094:11111111cc11ccc1c01cc00cc11cc110c11cc11ccc10ccc00011000111111111
-- 095:1111111111111111111111111111111111111111111111111111111111111111
-- 123:eeeeeee1eccccceeecc000eeecccceeeecc00eeeeccccceee00000eeffffffff
-- 124:11111111eceeeeeee0ecceececec0ce0ecececeeecececeee0e0e0eeffffffff
-- 125:11111111ceeeeeeecceeccecc0ec0cecceecc0ec0ce0ccece0ee00e0ffffffff
-- 126:11111111eeeeeeeeceeeccee0cec0cecc0ececec0ce0cce0e0ee00eeffffffff
-- 127:11111111eeeeceeeccecccee00e0c0eeeeeeceeeccee0cee00eee0eeffffffff
-- </TILES>

-- <SCREEN>
-- 000:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 001:2222222222222222222222222222222222222222222222222222222222222ccc222ccc22cc22c2ccccc2cccc222222222cccc2cc2cc22ccc222cccc2ccccc22222222cccc22ccc22cc22c2ccccc2cccc222222222cc2222c2222222222222222222222222222222222222222222222222222222222222222
-- 002:222222222222222222222222222222222222222222222222222222222222cc22c2cc22c2cc22c2cc2222cc22c222222222cc22ccccc2cc22c2cc2222cc2222222222ccc222cc22c2cc22c2cc2222cc22c22222222cc22222c222222222222222222222222222222222222222222222222222222222222222
-- 003:222222222222222222222222222222222222222222222222222222222222cc2222cc22c2cc22c2cccc22cc22c222222222cc22ccccc2cc22c2cc2cc2cccc222222222ccc22cc22c2cc22c2cccc22cc22c222222222222222c222222222222222222222222222222222222222222222222222222222222222
-- 004:222222222222222222222222222222222222222222222222222222222222cc22c2cc22c22ccc22cc2222cccc2222222222cc22c2c2c2ccccc2cc22c2cc222222222222ccc2ccccc22ccc22cc2222cc22c22222222cc22222c222222222222222222222222222222222222222222222222222222222222222
-- 005:2222222222222222222222222222222222222222222222222222222222222ccc222ccc2222c222ccccc2cc22c22222222cccc2c222c2cc22c22cccc2ccccc2222222cccc22cc22c222c222ccccc2cccc222222222cc2222c2222222222222222222222222222222222222222222222222222222222222222
-- 006:222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
-- 007:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 008:fffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 009:fffffffccfffffccccffcccccfffffffcccfccfffffccccffffccffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 010:fccffcfccfffff000ccfcc000ffffffcc00fccfffff000ccffcccffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 011:fccffcf00ffffffccc0fccccffffffcccccf00ffffffccc0fcc0cffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 012:f0ccc0fccfffffcc00ff000ccfffff0cc00fccfffffcc00ffcccccfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 013:ff0c0ffccfffffcccccfcccc0ffffffccfffccfffffcccccf000c0fbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 014:fff0fff00fffff00000f0000fffffff00fff00fffff00000ffff0ffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 015:fffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 016:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 017:fccffcfccffffffcccffffffcccffffffccfcfccffffffccffccccfffcccffffffcccffffffcccccfccfffffffffccccffcccccffcccffffffcccffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 018:fccffcfccfffffcc0ccffffcc0ccfffffccfcfccfffffcccff000ccfcc00cffffcc0ccfffff00cc0fccfffffffff000ccfcc000fcc00fffffcc0ccfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 019:f0ccc0f00fffffccc0cffffccc0cfffffccccf00fffff0ccfffccc0f0ccc0ffffccc0cffffffcc0ff00fffffcccffccc0fccccffccccfffffccc0cfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 020:fcc00cfccfffffcc0fcfccfcc0fcfffff0cc0fccffffffccffcc00ffcc00cfccfcc0fcfffffcc0fffccfffff000fcc00ff000ccfcc00cfccfcc0fcfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 021:fccffcfccfffff0ccc0fccf0ccc0ffffffccffccfffffccccfcccccf0ccc0fccf0ccc0fffffcccccfccfffffffffcccccfcccc0f0ccc0fccf0ccc0fbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 022:f00ff0f00ffffff000ff00ff000fffffff00ff00fffff0000f00000ff000ff00ff000ffffff00000f00fffffffff00000f0000fff000ff00ff000ffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 023:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 024:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 025:ffcccffffffffffffffffffffffffffffffffccffffffcccffffffcccfffffffccfffcccfffcccffffffcccffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 026:fcc00cffccccfccfcfffcccffccccfffccccfccfffffcc0ccffffcc0ccfffffcccffcc00cfcc0ccffffcc0ccfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 027:fccff0fc00ccfcccccfcc0ccfcc00cfc00ccf00fffffccc0cffffccc0cfffff0ccff0ccc0fccc0cffffccc0cfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 028:fccffcfcffccfc0c0cfccc00fccff0fcffccfccfffffcc0fcfccfcc0fcffffffccffcc00cfcc0fcfccfcc0fcfbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 029:f0ccc0f0ccccfcfcfcf0cccffccffff0ccccfccfffff0ccc0fccf0ccc0fffffccccf0ccc0f0ccc0fccf0ccc0fbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 030:ff000fff0000f0f0f0ff000ff00fffff0000f00ffffff000ff00ff000ffffff0000ff000fff000ff00ff000ffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 031:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 032:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 033:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 034:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 035:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 036:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 037:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 038:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 039:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 040:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 041:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 042:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 043:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 044:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 045:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 046:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 047:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 048:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 049:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 050:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 051:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 052:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 053:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 054:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 055:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 056:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 057:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 058:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 059:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 060:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 061:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00eeeeeeeeeeeeee00000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 062:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0e0eeeeeeee0000000000000000000ee0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 063:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0ee0eeeeeee00eeeeeeeeeeeeeeeeeee0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 064:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0ee0eeeeeee00eeeeeeeeeeeeeeeeeee0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 065:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0eee0eeeeee00eeeeeeeeeeeeeeeeeee0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 066:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0eeee0eeeee00eeeeeeeeeeeeeeeeeee0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 067:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0eeeee0eeee00eeeeeeeeeeeeeeeeeee0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 068:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeee0eee00eeeeeeeeeeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 069:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeee0ee00eeeeeeeeeeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 070:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeee0e00eeeeeeeeeeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 071:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeeee000eeeeeeeeeeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 072:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeeeee00eeeeeeeeeeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 073:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeeeee00eeeeeeeeeeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 074:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeeeee000eeeeeeeeeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 075:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeeeee000eeeeeeeeeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 076:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeeeee00e0eeeeeeeeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 077:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeeeee00ee0eeeeeeeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 078:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeeeee00eee0eeeeeeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 079:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeeeee00eeee0eeeeeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 080:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeeeee00eeeee0eeeeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 081:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeeeee00eeeeee0eeeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 082:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeeeee00eeeeeee0eeeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 083:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeeeee00eeeeeeee0eeeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 084:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeeeeee0000eeeeeeeee0eeeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 085:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660eeeee0000000eeeeeeeeee0eeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 086:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660ee000ee0eee0eeeeeeeeee0eeeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 087:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660e0eeee0eeee0eeeeeeeeeee0eeeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 088:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660e0eee0eeee00eeeeeeeeeeee0eeeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 089:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660e0ee0ee000eeeeeeeeeeeeeee0eeeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 090:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660e0e0e00eeeeeeeeeeeeeeeeeee0eeee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 091:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660e0000eeeeeeeeeeeeeee0eeeeee0eee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 092:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660e0eeeeeeeeeeeeeeeee00eeeeeee0ee0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 093:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660000000000eeeeeeeeee00eeeeeeee0e0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 094:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660000000000000eeeeeeee00666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 095:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660f000000000000666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 096:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660f006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 097:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660f006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 098:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600f000666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 099:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660ff0f0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 100:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660ff0f0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 101:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660ff0f0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 102:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660fff0ff066666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 103:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660fff0ff066666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 104:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660fff0ff066666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 105:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600fff0ff006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 106:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660ffff0fff06666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 107:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660ffff0fff06666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 108:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600ffff0fff00666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 109:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600ffff0fff00666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 110:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660fffff0ffff0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 111:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660fffff0ffff0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 112:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600fffff0ffff0066666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 113:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660ffffff0fffff066666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 114:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660ffffff0fffff066666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 115:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600ffffff0fffff006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 116:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600ffffff0fffff006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 117:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660fffffff0ffffff06666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 118:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660fffffff0ffffff06666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 119:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600fffffff0ffffff00666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 120:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660ffffffff0fffffff0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 121:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660ffffffff0fffffff0666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 122:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600fffffff000ffffff0066666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 123:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600fff0000f0f0000ff0066666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 124:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600000fffff0fffff000066666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 125:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666000fffffff0fffffff0066666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 126:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600ff0000fff0fff0000f006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 127:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666600ffffff0000000fffff006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 128:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660fffffff0000000ffffff06666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 129:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660fff0000fff0fff000fff06666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 130:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660000fffffff0ffffff00006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 131:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666000ffffffff0ffffffff006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 132:6666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666000fffff0ffff0000666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 133:66666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660000f0f0006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 134:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666660006666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- 135:666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666666
-- </SCREEN>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

