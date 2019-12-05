--[[
	Clove  : A generous LÖVE library using which you can easily (super-easily) loads huge amount of assets.
	Author: Neer
	(https://github.com/YoungNeer/clove)
]]

local clove={debug=false}
local delim=package.config:sub(1,1) --path delimiter: '/' or '\'

local imgExt={"png","jpg","gif","jpeg","tga","bmp"}
local fontExt={"ttf","otf"}
local audioExt={"mp3","wav","midi","ogg"}
local vidExt={"vid"} --since ogg is reserved for audio

local allExt={"png","jpg","ttf","ogg","mp3","wav","otf","midi","jpeg","bmp","gif","vid"}

local function isAFile(url)
	return love.filesystem.getInfo(url) and love.filesystem.getInfo(url).type=="file"
end

local function lastIndexOf(str,char)
	for i=str:len(),1,-1 do if str:sub(i,i)==char then return i end end
	return str:len()+1
end

local function removeExtension(filename)
	return filename:sub(1,lastIndexOf(filename,".")-1)
end

local function getWord(filename)
	return string.match(filename:gsub(' ','_'),"[_%w]+")
end

local function getExtension(filename)
	return filename:sub((lastIndexOf(filename,".") or filename:len()) +1)
end

--[[ the next two functions borrowed from itable library's
     table.join and table.exist with some slight modification
]]
local function mergeTables(tbl1,...)
	for _,i in ipairs({...}) do
		for k,j in pairs(i) do tbl1[k]=j end
	end
end

local function existsInList(tbl,element)
	for i,el in ipairs(tbl) do if el==element then return true end end
	return false
end

--[[
	clove.loadAsset:-
	    Description: Loads an asset automatically. You specify the URL and it would detect
	    what type of asset it is and then return it after loading

	    Parameters:
		  url         - the URL of the asset (string)
]]
function clove.loadAsset(url,...)

	assert(url,"Clove can't load the Asset! It is nil")
	local filetype=getExtension(url)

	if existsInList(imgExt,filetype) then
		return love.graphics.newImage(url,...)
		
	elseif existsInList(audioExt,filetype) then
		return love.audio.newSource(url,... or 'static')

	elseif existsInList(fontExt,filetype) then
		return love.graphics.newFont(url,...)

	
	elseif existsInList(vidExt,filetype) then
		return love.graphics.newVideo(url,...)

	else
		--[[
			Here clove will try to help the programmer if he forgets the extension- eg. "hello" 
			- if it doesn't exist - will be mapped to hello.png - if hello.png exists.
			And BTW this has no effect if you are using clove.load since the flow would
			never reach here (cause the file will exist).
		]]
		for i=1,#allExt do
			if love.filesystem.getInfo(url..'.'..allExt[i]) then
				if love.filesystem.getInfo(url..'.'..allExt[i]).type=="file" then
					return clove.loadAsset(url..'.'..allExt[i],...)
				end
			end
		end

		-- a message just to inform the programmer
		print("Sorry, Clove couldn't load the asset :(")
	end
end

--[[clove.requireLib:- (The Master Function for requiring modules)
	
	    Description: Loads all the libraries in the path (except those defined by `except`) 
					 and if it is returning-library then adds it to a hashtable (which it returns) 
					 with the filenames as the key (custom key could be used with the help of `rename`)
					 or simply requires the library thus avoiding allocation of any extra memory

	    Parameters:
	      path         - the directory to look up for modules (with .lua extension) (string)
		  recurse      - whether to keep looking for modules in the sub-directories (bool)
		  tbl          - The table to merge the modules with
	      rename       - a function which takes in a filename and returns the key string
	      except       - a function which takes in a filename and returns a boolean
						 for whether the asset should be added or not

	    Please note that only the path argument is mandatory- and please check
	    if filenames are not same when recursively adding files.
	    See ReadMe.md for more info on the possible problems with recurse
]]

function clove.requireLib(path,recurse,tbl,rename,except,isPackage,debugTab)

	assert(love.filesystem.getInfo(path),"Clove Error! Directory '"..path.."' doesn't exist!")

	local libTbl=tbl or {}

	local dir,libName=love.filesystem.getDirectoryItems(path)

	rename=rename or (tbl and getWord or removeExtension)
	except=except or function() return false end
	debugTab=debugTab or ''
	if debugTab=='' and clove.debug then
		print("----------DEBUG INFORMATION----------")
	end

	for _,file in ipairs(dir) do
		if isAFile(path..delim..file) then
			libName=rename(file)
			if getExtension(file)=="lua" and file~="init.lua" and not except(file) then
				file=removeExtension(file)
				if type(require(path..delim..file))~='boolean' then
					libTbl[libName]=require(path..delim..file)
					if clove.debug then
						print(debugTab.."Loaded module "..libName..' ('..path..delim..file..') ...')
					end
				else
					require(path..delim..file)
					if clove.debug then
						print(debugTab..'[NOTE: '..path..delim..file..' is a non-returning library]')
					end
				end
			end
		else
			if isPackage then
				if isAFile(path..delim..file..delim..'init.lua') and not except(file) then
					if type(require(path..delim..file))~='boolean' then
						libTbl[rename(file)]=require(path..delim..file)
						if clove.debug then
							print(debugTab.."Loaded package "..path..delim..file..'...')
						end
					else
						require(path..delim..file)
						if clove.debug then print(debugTab..'[NOTE: '..path..delim..file..' is a non-returning package]') end
					end
				end
			else
				if recurse then
					if isAFile(path..delim..file..delim..'init.lua') then
						if clove.debug then print(debugTab.."[NOTE: '"..path..delim..file.."' is ignored (as it's a package)]") end
					else
						if clove.debug then print(debugTab..'[+] Recursing.. '..path..delim..file) end
							mergeTables(
								libTbl,
								clove.requireLib(path..delim..file,recurse,tbl,rename,except,isPackage,debugTab..'\t')
							)
					end
				end
			end
		end
	end
	return libTbl
end

function clove.requirePackage(path,tbl,except)
	return clove.requireLib(path,false,tbl,nil,except,true)	
end

function clove.require(path,recurse,tbl,except)
	local tbl1=clove.requireLib(path,recurse,tbl,nil,except,false)
	local tbl2=clove.requireLib(path,false,tbl,nil,except,true)
	return mergeTables(tbl1,tbl2)
end

function clove.requireAll(path,recurse)
	clove.require(path,recurse,_G)
end

--[[
	clove.load:- (The Master Function for importing assets)
	
	    Description: Loads all the assets in the path (except those defined by `except`) 
	    			 and adds it to a hashtable (which it returns) with the filenames 
	    			 as the key (custom key could be used with the help of `rename`).

	    Parameters:
	      assetType    - a table which consists of the filetype of the asset to load
	    				 (eg. {'png','jpg'} for images and {'mp3'} for audio you could possibly
	    				 even mix assets like {'ttf','ogg'})
		  path         - the directory to look up for images (string)
		  tbl          - The table to merge with ({} by default)
	      recurse      - whether to keep looking for images in the sub-directories (bool)
	      rename       - a function which takes in a filename and returns the key string
	      except       - a function which takes in a filename and returns a boolean
						 for whether the asset should be added or not
		  param        - An function to pass in parameters for asset-loading (eg. loading fonts with size 18,etc)

	    Please note that only the type & path argument is mandatory- and please check
	    if filenames are not same when recursively adding files.
	    See ReadMe.md for more info on the possible problems with recurse
]]
function clove.load(assetType,path,recurse,tbl,rename,except,param)

	assert(love.filesystem.getInfo(path),"Clove Error! Directory '"..path.."' doesn't exist!")

	tbl=tbl
	recurse=recurse or false
	rename=rename or (tbl and getWord or removeExtension)
	except=except or function() return false end
	param=param or function() end
	local libName
	
	local dir,assetTbl=love.filesystem.getDirectoryItems(path),tbl or {}

	for i=1,#dir do
		if isAFile(path..delim..dir[i]) then
			libName=rename(dir[i])
			if not except(dir[i]) and existsInList(assetType,getExtension(dir[i])) then
				if libName and not assetTbl[libName] then
					assetTbl[libName]=clove.loadAsset(path..delim..dir[i],param(dir[i]))
				else
					if clove.debug then
						print('[WARNING! Key '..name..' already exists for '..dir[i]..']')
					end
				end
			end
			
		else
			if recurse then
				mergeTables(
					assetTbl,
					clove.load(assetType,path..delim..dir[i],recurse,tbl,rename,except,param)
				)
			end
		end
	end

	return assetTbl
end

function clove.loadFonts(...) return clove.load(fontExt,...) end

function clove.loadSounds(...) return clove.load(audioExt,...) end

function clove.loadImages(...) return clove.load(imgExt,...) end

function clove.loadVideos(...) return clove.load(vidExt,...) end

function clove.loadAll(...)
	local tbl={}
	mergeTables(
		tbl,
		clove.loadFonts(...),
		clove.loadSounds(...),
		clove.loadImages(...),
		clove.loadVideos(...)
	)
	return tbl
end


clove.import=clove.load
clove.importAsset=clove.loadAsset
clove.importAll=clove.loadAll
clove.importFonts=clove.loadFonts
clove.importGraphics=clove.loadImages
clove.importAudio=clove.loadSounds
clove.importVideo=clove.loadVideos
clove.loadAudio=clove.loadSounds
clove.loadSprites=clove.loadImages

return clove
