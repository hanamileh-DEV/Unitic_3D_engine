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
	x = 28, y = 128, z = -128, --camera position
	tx = 0, --turning the camera up and down
	ty = pi --turning the camera left and right
}

-- Engine settings:
local unitic = {
	version = "1.3.1",    -- Engine version
	focal_length = 120,   -- Lens distance to camera (the higher the value, the fewer objects fit into the frame)
	draw_wareframe =true, -- Note that this may be slower
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
		scale=0.3, --model size
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
	}
}

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
end

function unitic.render()
	--updating objects
	unitic.update()
	--sky display (optional)
	cls(unitic.sky_color)
	--this complicated math just makes the height of the ground proportionally equal to the angle of rotation of the camera
	local ground_height = min(max(68.5-134*cam.tx,0),136)
	rect(0,ground_height,240,137-ground_height,unitic.ground_color)
	--drawing triangles
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
	-- Render
	unitic.render()
	-- Debug text
	local debug_text = {
		string.format("Unitic v %s",tostring(unitic.version)),
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
-- 000:ed000000ed000000000000000000000000000000000000000000000000000000
-- </TILES>

-- <SCREEN>
-- 000:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 001:fffcccfffffffffffffccffffffffffccfffcccfffcccfffcccfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 002:ffcc00fccccfffccccfccfffffffffcccffcc0ccfcc0ccfcc0ccffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 003:fcccccfcc00cfccc00f00fffffffff0ccffccc0cfccc0cfccc0cffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 004:f0cc00fccffcf00cccfccffffffffffccffcc0fcfcc0fcfcc0fcffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 005:ffccfffcccc0fcccc0fccfffffffffccccf0ccc0f0ccc0f0ccc0ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 006:ff00fffcc00ff0000ff00fffffffff0000ff000fff000fff000fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 007:fffffff00fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff777667777fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 008:fffcccfffffffffffffffffffffffffccffccffffffcccfffffffffffffffffffffffffffffffffffffffffffffffffffffffff7766666ccccc66666666667777fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 009:ffcc00fccccfffccccfccfcfffcccffccfcccfffffcc0ccfffffccfcfffccccfffffffffffffffffffffffffffffffffff77666666666666666cc66666666666666666667777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 010:fcccccfcc00cfc00ccfcccccfcc0ccf00f0ccfffffccc0cfffffcccccfccc00fffffffffffffffffffffffffffff777666666666666666666666666666666666666666666666666666667777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 011:f0cc00fccff0fcffccfc0c0cfccc00fccffccffccfcc0fcfffffc0c0cf00cccfccfffffffffffffffffffff77766666666666666666666666666666666666666666666666666666666666666666666677777ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 012:ffccfffccffff0ccccfcfcfcf0cccffccfccccfccf0ccc0fffffcfcfcfcccc0fccffffffffffffffff7776666666666666666666666666666666666666666666666666666666666666666666666666666666667778ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 013:ff00fff00fffff0000f0f0f0ff000ff00f0000f00ff000ffffff0f0f0f0000ff00fffffffffff776666666666666666666666666666666666666666666666666666666666666666666666666666666666666777888ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 014:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff77766666666666666666666666666666666666666666666666666666666666666666666666666666666666666666777888fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 015:fffffffccffffffcccffffffffcccfccffccffccccffffffffffffffffffffffff7776666665555556666666666666666666666666666666666666666666666666666666666666666666666666666666677788889fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 016:fccffcfccfffffcc00cffffffcc00fccfcccff000ccffffffffffffffffff777666666555666666655565555566666666666666666666666666666666666666666666666666666666666666666666667778888998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 017:fccffcf00fffff0ccc0fffffcccccf00f0ccfffccc0fffffffffffffff111777776666666665556655555666555566666666666666666666666666666666666666666666666666666666666666666777888889998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 018:f0ccc0fccfffffcc00cfffff0cc00fccffccffcc00ffffffffffffffff111111117777766666555556665566555555666655556666666666666666666666666666666666666666666666666666677778888999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 019:ff0c0ffccfffff0ccc0ffffffccfffccfccccfcccccffffffffffffffff1111111111117777766666556666555566666665556655666666666666666666666666666666666666666666666666777788889999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 020:fff0fff00ffffff000fffffff00fff00f0000f00000ffffffffffffffff1221111111111111177777666666666666655556666666666666666666666666666666666666666666666666666667778888899999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 021:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1122222111111111111111777777666665566666666666666666666666666666666666666666666666666666666777888889999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 022:fccffcfccffffffccfffcccfffcccffffffccfcfccffffffccfffcccffffcc222222ccccc1cc111111cc117cc77ccccc666666666666666666666666666666666666666666666666666677778888899999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 023:fccffcfccfffffcccffcc00ffcc00cfffffccfcfccfffffcccffcc00fffccc22222200cc02cc11111ccc11ccc11cc000766666666666666666666666666666666666666666666666667777888889999999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 024:f0ccc0f00fffff0ccffccccff0ccccfffffccccf00fffff0ccffccccffcc0c2cc2cc2cc02200222220cc110cc11cccc177777776666666666666666666666666666666666666666677778888899999999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 025:fcc00cfccffffffccffcc00cff000cfffff0cc0fccffffffccffcc00cfccccccc2cccc0222cc222222cc211cc11000cc11111177777766666666666666666666666666666666667777888888999999999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 026:fccffcfccfffffccccf0ccc0ffccc0ffffffccffccfffffccccf0ccc0f000c02c22cccccc2cc22222cccc2cccc1cccc011111111111777777666666666666666666666666666777778888899999999999999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 027:f00ff0f00fffff0000ff000fff000fffffff00ff00fffff0000ff000fffff022c22c000002002222200002000020000111111111111111117777777666666666666666666667777888889999999999999999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 028:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff112cc2cc222c222222222222222222222222221111111111111111117777777666666666666677778888889999999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 029:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11222ccc222cc22222222222222222222222222222211111111111111111177777776666667777888888999999999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 030:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222cc22222c22222222222222222222222222222222222111111111111111111777777777778888889999999999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 031:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222cc222ccc22222222222222222222222222222222222222221111111111111111117777888888999999999999999999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 032:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff112cc2222ccccc222222222222222222222222222222222222222222111111111111111118888899999999999999999999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 033:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff12cc2cc22ccccc2222222222222222222222222222222222222222222222111111111111888899999999999999999999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 034:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122c22c222cc2c22222222222222222222222222222222222222222222222222211111118899999c9999999999999999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 035:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122c22c2222c222222222222222222222222222222222222222222222222222222221111899999cc9999999999999999999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 036:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff112cc2cc222cc222222222222222222222222222222222222222222222222222222211118999cccc99c9999999999999999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 037:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff12222cc2222222222222222222222222222222222222222222222222222222222221111899cccc999c9999999999999999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 038:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff12222222222222222222222222222222222222222222222222222222222222222221111899cccc999cc99999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 039:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11222222222222222222222222222222222222222222222222222222222222222221118899cc9c99ccc99999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 040:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11222222222222222222222222222222222222222222222222222222222222222221118899999c9ccc999999999999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 041:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122222222222222222222222222222222222222222222222222222222222222222111889999999ccc999999999999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 042:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122222222222222222222222222222222222222222222222222222222222222222111889999999ccc999999999999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 043:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11222222222222222222222222222222222222222222222222222222222222222211188999c9999c999999999999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 044:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222222222222222222222222222222222222222222222222222222222222222211188999c9999c999999999999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 045:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222222222222222222222222222222222222222222222222222222222222222211188999c99999999999999999999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 046:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222222222222222222222222222222222222222222222222222222222222222211188999999999999999999999999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 047:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff112222222222222222222222222222222222222222222222222222222222222221118899c99999999999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 048:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222222222222222222222222222222222222222222222222222222222222221111899c99c999999999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 049:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222222222222222222222222222222222222222222222222222222222222221111899c9cc999999999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 050:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222222222222222222222222222222222222222222222222222222222222221111899cccc999999999999999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 051:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1122222222222222222222222222222222222222222222222222222222222221111899ccc9999999999999999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 052:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122222222222222222222222222222222222222222222222222222222222221118899cc9999999999999999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 053:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122222222222222222222222222222222222222222222222222222222222221118899999999999999999999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 054:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff112222222222222222222222222222222222222222222222222222222222221118899999999999999999999999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 055:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff12222222222222222222222222222222222222222222222222222222222221118899999999999999999999999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 056:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff12222222222222222222222222222222222222222222222222222222222221118899999999999999999999999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 057:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222222222222222222222222222222222222222222222222222222222222111889999999999999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 058:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1122222222222222222222222222222222222222222222222222222222222111889999999999999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 059:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122222222222222222222222222222222222222222222222222222222222111889999999999999999999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 060:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122222222222222222222222222222222222222222222222222222222222111899999999999999999999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 061:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff12222222222222222222222222222222222222222222222222222222222211189999999999999999999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 062:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11222222222222222222222222222222222222222222222222222222222211189999999999999999999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 063:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222222222222222222222222222222222222222222222222222222222211189999999999999999999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 064:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222222222222222222222222222222222222222222222222222222222211189999999999999999999999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 065:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222222222222222222222222222222222222222222222222222222222111189999999999999999999999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 066:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff12222222222222222222222222222222222222222222222222222222211188999999999999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 067:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff12222222222222222222222222222222222222222222222222222222211188999999999999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 068:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff12222222222222222222222222222222222222222222222222222222211188999999999999999999999999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 069:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff12222222222222222222222222222222222222222222222222222222211188999999999999999999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 070:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222222222222222222222222222222222222222222222222222222211188999999999999999999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 071:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122222222222222222222222222222222222222222222222222222221118899999999999999999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 072:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122222222222222222222222222222222222222222222222222222221118999999999999999999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 073:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff112222222222222222222222222222222222222222222222222222221118999999999999999999999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 074:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff12cc222222222222222222222222222222222222222222222222222111899999999999999999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 075:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122ccc222222222222222222222222222222222222222222222222211189999999999999999999999fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 076:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222cc2c2222222222222222222222222222222222222222222222211189999999999999999999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 077:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122c222cc2222222222222222222222222222222222222222222221118999999999999999999998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 078:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122c222cccc2222222222222222222222222222222222222222222111899999999999999b99998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 079:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122cc22c22c2c2222222222222222222222222222222222222222211889999999999999b99999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 080:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222c22cc2222c222222222222222222222222222222222222222211889999999999999b99998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 081:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff122c222ccc22c22c22222222222222222222222222222222222221188999999999999bb9998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 082:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1222222c2cc2c22c2222222222222222222222222222222222222118899999999999b9b999ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 083:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff112222c22222c2cc2cc22222222222222222222222222222222111889999999999999b998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 084:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1122ccc22c2ccc2cccc22222222222222222222222222222211189999999999b999998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 085:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11122cc22cc22222ccc2222222222222222222222222222211189999999999bb9998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 086:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1112222c222222ccc2222222222222222222222222222211189999999999999b98ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 087:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11222c22c222cc222222222222222222222222222222111899999999bbbb998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 088:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff112222c222cc22222222222222222222222222222211189999999b9bbb98ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 089:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11122cc22cc22222222222222222222222222222211189999999b999b9fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 090:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11122222c2222222222222222222222222222221118999999b99b998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 091:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff112222c222222222222222222222222222222111899999b9b9b98ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 092:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11222222222222222222222222222222222111899999b9b9b8fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 093:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff112222222222222222222222222222222118899999bb9998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 094:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111222222222222222222222222222221188999b9b9b98ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 095:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111222222222222222222222222222118899b99bb98fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 096:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff112222222222222222222222222211899bb99bb98fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 097:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1122222222222222222222222211899bb99b98ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 098:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11122222222222222222222221189b9b9998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 099:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1112222222222222222222211899b99b9ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 100:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11122222222222222222111899b9998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 101:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff112222222222222222111899b998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 102:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11122222222222222111899b98ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 103:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111222222222222111899b98ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 104:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111222222222211189998fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 105:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111222222221118998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 106:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1122222221188998ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 107:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11122222118898fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 108:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11122211898ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 109:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11121188fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 110:fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff111188fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 111:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1118ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 112:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 113:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 114:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 115:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 116:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 117:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 118:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 119:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 120:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 121:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 122:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 123:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 124:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 125:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 126:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 127:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 128:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 129:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 130:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 131:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 132:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 133:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 134:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 135:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- </SCREEN>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffbe75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

