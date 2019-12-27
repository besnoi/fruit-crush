--[[
	Iffy  : The SpriteSheet and Tileset helper library (handles Tilemaps as well)
	Author: Neer
	(https://github.com/YoungNeer/iffy)
]]

local iffy={
	images={},         --the images that form the spritesheets
	spritesheets={},   --the sprites themselves
	cache={},          --to increase performance and provide easy access to sprites
	tilesets={},       --contains only the tilewidth and tileheight information
	tilemaps={},       --the tilemaps that were created plus the width and height
	spritedata={},     --the data of sprites created so they could be exported
}

local function fileExists(url)
	return love.filesystem.getInfo(url) and
	       love.filesystem.getInfo(url).type=="file"
end

local function trim(s)
	return s:gsub("^%s*(.-)%s*$", "%1")
end

local function lastIndexOf(str,char)
	for i=str:len(),1,-1 do if str:sub(i,i)==char then return i end end
end

--removes the path and only gets the filename
function removePath(filename)
	local pos=1
	local i = string.find(filename,'[\\/]', pos)
	pos=i
	while i do
		i = string.find(filename,'[\\/]', pos)
		if i then
			pos = i + 1
		else i=pos break
		end
	end
	if i then filename=filename:sub(i) end
	return filename
end

--remove extension from a file as well as remove the path
local function removeExtension(filename,dontremovepath)
	if not dontremovepath then filename=removePath(filename) end
	return filename:sub(1,lastIndexOf(filename,".")-1)
end

local function getExtension(filename)
	return filename:sub((lastIndexOf(filename,".") or filename:len()) +1)
end

--[[
	The extensions supported by iffy. iffy supports only xml and csv format
	So the "" and ".txt" should map to either one of those.
]]
local metafileFormats={
	"",".txt",".xml",".csv"
}

-- takes asset url and returns corresponding meta file url (if it exists)
local function getmetafile(url)
	for i=1,#metafileFormats do
		local f=removeExtension(url,true)..metafileFormats[i]
		if fileExists(f) then
			return f
		end
	end
	error("Iffy Error! metafile doesn't exist for "..url)
end

--[[
	Makes a brand new sprite (image-quad) from given parameters.
	Arguments
		iname  : The name of the Image (needed to namespace the sprite)
		name   : The name of the Sprite (needed to locate the sprite)
		x,y    : The position of the sprite in the atlas
		width  : The width of the sprite
		height : The height of the sprite
		sw,sh  : Not needed if a reference (not url) to the image is provided
	Returns a Quad
	[Before calling this function makes sure you map iname with the image
	using newImage otherwise you couldn't render the sprite with iffy]
]]
function iffy.newSprite(iname,name,x,y,width,height,sw,sh)
	if not sw and not iffy.images[iname] then
		error("Iffy Error! "..
			"You must provide the size of the image in the last parameter "..
			"in the function 'newSprite'"
		)
	end
	if iffy.images[iname] and not sw then
		sw=iffy.images[iname]
	end
	if not sh then  -- user provided an image?	
		sw, sh = sw:getDimensions()
	end
	if not iffy.spritesheets[iname] then iffy.spritesheets[iname]={} end
	if not iffy.spritedata  [iname] then iffy.spritedata  [iname]={} end

	iffy.spritesheets[iname][name]=love.graphics.newQuad(x,y,width,height,sw,sh)
	table.insert(iffy.spritedata[iname],{name,x,y,width,height})
	return iffy.spritesheets[iname][name]
end

--[[
	Maps given image name with the provided image.
	Arguments:-
		iname  - The name of the image
		url    - The url or reference to the image
]]
function iffy.newImage(iname,url)
	if not url then url=iname iname=removeExtension(url) end
	iffy.images[iname] = type(url)=='string' and love.graphics.newImage(url) or url
end

--[[ 
	Makes a brand new spritesheet and returns a reference (of table of image-quads).
	NOTE:- only first arg is mandatory
	Args:-
		name     : The name you choose for the spritesheet
		url      : The URL or the reference to the image (which'll be used as atlas)
		metafile : The URL of the file which contains information about sprites
				   Mandatory if you pass in a reference of image and not url
		sw,sh    : The dimensions of the spritesheet (a sensible default is set if nil)
	Returns a hashtable of quads;
]]
function iffy.newAtlas(name,url,metafile,sw,sh)
	local t={}
	if name and url and not metafile then
		assert(fileExists(url),("Iffy Error! File '%s' doesn't exist"):format(url))
		url,metafile=name,url
		name=removeExtension(url)
	end
	if url then
		if type(url)~='string' then
			assert(metafile,
			   "Iffy Error! You must pass the URL of the metafile for"..name
			)
			iffy.images[name]=url
		else
			iffy.images[name]=love.graphics.newImage(url)
			if not metafile then 
				metafile=getmetafile(url)
			end
		end
	else
		assert(type(name)=='string',
			"Iffy Error! You must pass atleast one parameter -"..
			"the URL of the spritesheet"
		)
		url=name
		metafile=getmetafile(url)
		name=removeExtension(url)
		iffy.images[name]=love.graphics.newImage(url)		
	end
	
	sw,sh=sw or iffy.images[name]:getWidth(),sh or iffy.images[name]:getHeight()

	local i,sname,x,y,width,height=1

	if getExtension(metafile)=="xml" then
		--READ XML FILE ('i' means the line number)
		for line in love.filesystem.lines(metafile) do
			if i>1 and line:match('%a') and not line:match('<!') and line~="</TextureAtlas>" then
				_, sname = string.match(line, "name=([\"'])(.-)%1")

				assert(not t[sname],
					"Iffy Error!! Duplicate Sprite Names ("..sname..") for "..name
				)
				_, x = string.match(line, "x=([\"'])(.-)%1")
				_, y = string.match(line, "y=([\"'])(.-)%1")
				_, width = string.match(line, "width=([\"'])(.-)%1")
				_, height = string.match(line, "height=([\"'])(.-)%1")
				
				t[sname]=love.graphics.newQuad(x,y,width,height,sw,sh)
			end
			i=i+1
		end
	else
		--READ CSV FILE ('i' means record number)
		for line in love.filesystem.lines(metafile) do
			i=1
			for data in line:gmatch("[^,]+") do
				if i>5 then break end
				data=trim(data)
				if data:sub(1,1)=="#" then break end -- it's a comment!
				if i==1 then
					data=data:gsub('["\']','')  --remove the parentheses
					sname=data
					assert(not t[sname],
						"Iffy Error!! Duplicate Sprite Names for "..url
					)
					t[sname]={}
				else
					table.insert(t[sname],tonumber(data))
				end
				i=i+1
			end
			--If a valid line was read
			if type(t[sname])=='table' then
				x,y,width,height=unpack(t[sname])
				t[sname]=love.graphics.newQuad(x,y,width,height,sw,sh)
			end
		end
	end

	iffy.spritesheets[name]=t
	return t
end

--[[
	Unlike newAtlas which relies on an extra metafile, newTileset only needs the name
	of the tileset and/or the reference/url of the tileset. Only url is must - like
	newAtlas. But *note* that unlike newAtlas it doesn't use hashtable (a plus point)
	So basically it returns an array of quads which you'd access like quad[1],etc.
	Arguments
		name   - The name of the atlas
		url    - The URL or the reference to the image to use as atlas
		tw,th  - Each tile-width and tile-height  (32x32 by default)
		mx,my  - The margin for each tile (0,0 by default)
		sw,sh  - The dimensions of the tileset (a sensible default is set if nil)
	Returns an array of quad.
	[Note that the first tile's posiion is always at 0,0 no matter the margin]
]]
function iffy.newTileset(name,url,tw,th,mx,my,sw,sh)
	local t={}
	if type(url)=='number' or not url then
		tw,th,mx,my,sw,sh=url,tw,th,mx,my,sw
		url=name
		name=removeExtension(url)
		iffy.images[name]=love.graphics.newImage(url)
	else
		if type(url)=='table' then
			iffy.images[name]=url
		else
			iffy.images[name]=love.graphics.newImage(url)
		end
	end
	
	tw,th = tw or 32, th or 32
	mx,my = mx or 0 , my or 0
	sw,sh=sw or iffy.images[name]:getWidth(),sh or iffy.images[name]:getHeight()

	local tiles_w,tiles_h,current=math.floor(sw/tw),math.floor(sh/th)
	for i=1,tiles_h do
		for j=1,tiles_w do
			current=j+(i-1)*tiles_w
			t[current]=love.graphics.newQuad(
				(j-1)*th + (current==1 and 0 or mx),
				(i-1)*tw + (current==1 and 0 or my),
				tw,th,
				sw,sh
			)
		end
	end
	iffy.spritesheets[name]=t
	iffy.tilesets[name]={tw,th}
	return t
end

--[[
	Loads a tilemap from given url (must be in csv format) and returns
	a reference. If you have a table in the same format then you can simply pass
	that.
	Arguments:-
		name - the name of the tilemap (unnecessary if you provide url)
		url  - the url of the csv file or a reference to the table
	Returns a table if you passed in url
]]
function iffy.newTilemap(name,url)
	local t={}
	if not url then
		assert(name,
			"Iffy Error!! You must pass atleast one argument in 'newTilemap'!!"
		)
		url=name
		name=removeExtension(url)
	end
	if type(url)=='string' then
		assert(fileExists(url),"Iffy Error! The provided file '"..url.."' doesn't exist")
		for line in love.filesystem.lines(url) do
			local row={}
			i=1
			for tile_no in line:gmatch("[^,]+") do
				row[#row+1]=tonumber(tile_no)
				i=i+1
			end
			t[#t+1]=row
		end
		iffy.tilemaps[name]=t
		return t
	else
		iffy.tilemaps[name]=url		
	end
end

--[[
	Draws a given tilemap for a given tileset
	Arguments
		map_name      - The name of the tilemap
		tileset_name  - The name of the tileset
		offset        - Leave it to nil if you don't understand
		mx,my         - The margin from where to draw tiles (0,0 by default)
]]
function iffy.drawTilemap(map_name,tileset_name,offset,mx,my)
	offset = offset or 0
	mx, my = mx or 0, my or 0

	for i=1,#iffy.tilemaps[map_name][1] do
		for j=1,#iffy.tilemaps[map_name] do

			if not iffy.tilemaps[map_name][j] then break end

			if iffy.tilemaps[map_name][j][i]+offset>0 then
				iffy.draw(
					tileset_name,
					iffy.tilemaps[map_name][j][i]+offset,
					(i-1)*iffy.tilesets[tileset_name][1]+mx,
					(j-1)*iffy.tilesets[tileset_name][2]+my
				)
			end
		end
	end
end

--- Gets a reference of the image (useful if you loaded the image with url)
function iffy.getImage(name)
	return iffy.images[name]
end

--[[
	Gets a sprite (it's undefined for which atlas) keyed by sname.
	You don't need to specify the image name, iffy would automatically find
	which image the sprite is for!!
	Use when you know you don't have sprites with same names (for different atlases)
	Arguments:
		sname: The name of the sprite. 
	Returns the atlas (Drawable) of the sprite and the quad (Quad)
]]
function iffy.getSprite(sname)
	for i in pairs(iffy.spritesheets) do
		if iffy.spritesheets[i][sname] then
			return iffy.images[i],iffy.spritesheets[i][sname]
		end
	end
	error(("Iffy Error!! The Sprite '%s' doesn't exist!!"):format(sname))
end

--[[
	Gets a sprite (or should I say Quad) by the name `sname` from a particular atlas
	Arguments:
		aname - The name of the atlas
		sname - The name of the sprite
	Returns a Quad.
	[Since user'd know which atlas it'd be- it doesn't return the image like getSprite]
]]
function iffy.get(aname,sname)
	return iffy.spritesheets[aname][sname]
end

--[[
	Draws a sprite by the name `sname` (it's undefined from which atlas)
	Arguments:
		sname - The name of the sprite
		...   - Regular arguments like x,y,r,sx,sy...
]]
function iffy.drawSprite(sname,...)
	if not iffy.cache[sname] then
		iffy.cache[sname]={}
		iffy.cache[sname][1],iffy.cache[sname][2]=iffy.getSprite(sname)
	end
	love.graphics.draw(iffy.cache[sname][1],iffy.cache[sname][2],...)
end

--[[
	Draws a sprite by the name `sname` from a *particular* atlas
]]
function iffy.draw(aname,sname,...)
	assert(iffy.spritesheets[aname],
		"Iffy Error! The spritesheet by the name '"..aname.."' doesn't exist!"
	)
	love.graphics.draw(iffy.images[aname],iffy.spritesheets[aname][sname],...)
end

--[[
	What if you want more than one spritename perhaps for your own ease!
	duplicateSprite will basically make an alias of the sprite
	Arguments
		iname : The image the sprite belongs to
		oname : The original sprite name
		dname : The duplicate sprite name
]]
function iffy.duplicateSprite(iname,oname,dname)
	iffy.spritesheets[iname][dname]=iffy.spritesheets[iname][oname]
end


--[[
	Exports the Sprite-Data to CSV format so it could be -reused, -used elsewhere.
	Arguments
		iname    - The name of the images
		path     - Where should iffy save the metafile?
		filename - By what name should iffy store it?
]]
function iffy.exportCSV(iname,path,filename)
	path     = path and path..package.config:sub(1,1) or ""
	filename = filename or iname..".csv"
	if fileExists(path..filename) then
		print(string.format("Iffy Warning! File '%s' Already Exists!",path..filename))
	end
	local file = io.open(path..filename,'w')

	file:write(string.format("#This SpriteData is for '%s'\n\n",iname))
	for i=1,#iffy.spritedata[iname] do
		file:write('\t',table.concat(iffy.spritedata[iname][i],','),'\n')
	end
	file:close()
end

--[[
	Exports the Sprite-Data to CSV format so it could be -reused, -used elsewhere.
	Arguments - exactly same as exportCSV
]]
function iffy.exportXML(iname,path,filename)
	path     = path and path..package.config:sub(1,1) or ""
	filename = filename or iname..".xml"
	if fileExists(path..filename) then
		print(string.format("Iffy Warning! File '%s' Already Exists!",path..filename))
	end
	local file = io.open(path..filename,'w')

	local sname,x,y,width,height

	file:write(string.format('<TextureAtlas imageName="%s">\n',iname))
	for i=1,#iffy.spritedata[iname] do
		sname,x,y,width,height=unpack(iffy.spritedata[iname][i])
		file:write(
			string.format('\t<SubTexture name="%s" x="%s" y="%s" width="%s" height="%s"/>\n',
				sname,x,y,width,height
			)
		)
	end

	file:write("</TextureAtlas>")
	file:close()
end

--[[
	Just making some aliases here, cause different people like different names
	And I don't want to punish them by using the word that they don't like.
	So here are your options (ofcourse you could make your ones as well)
]]--
iffy.newSpritesheet = iffy.newAtlas
iffy.newSpriteSheet = iffy.newAtlas
iffy.newTileMap     = iffy.newTilemap
iffy.newTileSet     = iffy.newTileset


return iffy
