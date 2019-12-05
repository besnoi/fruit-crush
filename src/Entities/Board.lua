Board=Class{
	x,y,        --Board's position
	matches,    --All the matches in a table
	fruits,     --All the 64 fruits in a table
	tweening,   --Do not listen for events when you are tweening
}
local push=table.insert
local random=love.math.random

function Board:init(x,y)
	self.op=1
	self.x,self.y=x,y
	self:initFruits(1)
end

function Board:getFruitPosition(tx,ty,offset)
	offset=offset or 0
	return self.x+(tx-1)*64+offset,self.y+(ty-1)*64+offset
end

function Board:initFruits(depth)
	self.fruits={}
	for y=1,8 do
		self.fruits[y]={}
		for x=1,8 do
			self.fruits[y][x]=Fruit(x,y,self.x+(x-1)*64,-64*(8-y),random(7))
			while self:checkMatch(x,y) do
				self.fruits[y][x]=Fruit(x,y,self.x+(x-1)*64,-64*(8-y),random(7))
			end
			local fruit=self.fruits[y][x]
			flux.to(fruit,.01+1/8*(8-y),{y=self.y+(y-1)*64}):ease('linear')
				:onupdate(function() self.tweening=true end)
				:oncomplete(function()
					playSound('drop_'..math.ceil(random(1,300)/300))
				end)
				:after(.3,{
					sx=1.2,sy=.8
				})
				:ease('sinein')
				:after(.3,{
					sx=1,sy=1
				})
				:oncomplete(function()
					self.tweening=false
				end)
		end
	end
	if depth>10 then print("oh boy!!") return end
end

function Board:update(dt)
	for i=1,8 do
		for j=1,8 do
			local fruit=self.fruits[i][j]
			if fruit:isHovered(love.mouse.getPosition()) then
				if not fruit.entered then
					fruit:mouseEnter()
				end
				fruit:whileHovered(dt)
			else
				if fruit.entered then
					fruit:mouseExit()
				end
			end
		end
	end
end

function Board:mousePressed(...)
	--Do not listen for events when you are tweening
	if self.tweening then return end
	for i=1,8 do
		for j=1,8 do
			self.fruits[i][j]:mousePressed(...)
		end
	end
end

function Board:mouseReleased(...)
	if self.tweening then return end
	for i=1,8 do
		for j=1,8 do
			self.fruits[i][j]:mouseReleased(...)
		end
	end
end

function Board:mouseMoved(...)
	if self.tweening then return end
	for i=1,8 do
		for j=1,8 do
			self.fruits[i][j]:mouseMoved(...)
		end
	end
end

function Board:draw()
	love.graphics.setColor(1,1,1,self.op)
	for i=1,8 do
		for j=1,8 do
			self.fruits[i][j]:render(self.disabled)
		end
	end
	love.graphics.setColor(1,1,1)
end

function Board:swapFruit(fruit,dir)
	if self.tweening then return end
	if (fruit.x-self.x)%64~=0 or (fruit.y-self.y)%64~=0 then
		error('boy something is wrong')
		--Boy something is going wrong, return immediately!!
		return
	end
	
	local other,sign
	local tweenX,tweenY=0,0

	if dir=='left' or dir=='right' then
		sign = dir=='left' and -1 or 1
		other=self.fruits[fruit.ty][fruit.tx+sign*1]
		tweenX=sign*64
	elseif dir=='up' or dir=='down' then
		sign = dir=='up' and -1 or 1
		other=self.fruits[fruit.ty+sign*1][fruit.tx]
		tweenY=sign*64
	end
	if not other then
		error("Oops! Something went wrong!!")
	end
	self.fruits[fruit.ty][fruit.tx],self.fruits[other.ty][other.tx]=self.fruits[other.ty][other.tx],self.fruits[fruit.ty][fruit.tx]

	flux.to(fruit,.2,{x=fruit.x+tweenX,y=fruit.y+tweenY})
	flux.to(other,.2,{x=fruit.x,y=fruit.y})
	
	fruit.tx,other.tx=other.tx,fruit.tx
	fruit.ty,other.ty=other.ty,fruit.ty
	
	fruit.other=oppositeDir(dir)
end

function Board:calculateMatches()
	self.matches={}
	self:calculateMatchesHor()
	self:calculateMatchesVer()
	return #self.matches>0 and self.matches	
end

function Board:removeMatches()
	local psystem=gStateMachine.current.psystem
	local scoreBoard=gStateMachine.current.scoreBoard
	self.tweening=true
	for i=1,#self.matches do
		--This spacing for the horizontal score
		local spacing,dSpacing=0,0
		if (self.matches[i][1].ty==self.matches[i][2].ty) then
			dSpacing=32
		end
		for i,tile in ipairs(self.matches[i]) do
			local fruit=self.fruits[tile.ty][tile.tx]
			if fruit then
				if euler.inRange(fruit:getFruit(),1,6) then
					psystem:newFruitParticle(fruit.img,fruit.x,fruit.y)
				end
				scoreBoard:addScore(fruit.score)
				psystem:newScoreParticle(fruit.score,fruit.x-spacing,fruit.y)
			end
			self.fruits[tile.ty][tile.tx]=nil
			spacing=spacing+dSpacing			
		end
	end
	-- self.matches=nil
end

function Board:moveDownFruits()
	self.tweening=true
	for x=1,8 do
		local spaceY,lastTileWasEmpty
		local y=8
		while y>0 do
			local fruit=self.fruits[y][x]
			-- If current tile is not empty but the previous tile was empty!
			if fruit then
				if lastTileWasEmpty then
					flux.to(fruit,.4,{y=self.y+(spaceY-1)*64}):ease('linear')
						:onupdate(function() self.tweening=true end)
						:after(.3,{
							sx=1.2,sy=.8
						})
						:ease('sinein')						
						:after(.3,{
							sx=1,sy=1
						})
						-- :ease('sinein')												
						:oncomplete(function() self.tweening=false end)
					fruit.ty=spaceY
					self.fruits[spaceY][x]=fruit
					self.fruits[y][x]=nil
					y=spaceY
					spaceY=nil
					lastTileWasEmpty=nil
				end
			else
				lastTileWasEmpty=true
				if spaceY==nil then spaceY=y end
			end
			y=y-1
		end
	end
	
	self:throwFruitsFromCeiling()
	
end

function Board:throwFruitsFromCeiling()
	for x=1,8 do
		for y=8,1,-1 do
			if not self.fruits[y][x] then
				local fruit=Fruit(x,y,self.x+(x-1)*64,-64,random(7))
				self.fruits[y][x]=fruit
				while self:checkMatch(x,y) do
					fruit=Fruit(x,y,self.x+(x-1)*64,-64,random(7))
					self.fruits[y][x]=fruit
				end
				flux.to(fruit,.4,{y=self.y+(y-1)*64}):ease('linear')
					:onupdate(function() self.tweening=true end)
					:after(.3,{
						sx=1.2,sy=.8
					})
					:ease('sinein')						
					:after(.3,{
						sx=1,sy=1
					})
					:oncomplete(function()self.tweening=false end)
			end
		end
	end
end

--returns tx,ty and dir as hint!
function Board:getHints()

	for x=1,8 do
		for y=1,8 do
			if self:sameFruit(y,x,y+1,x, y+3,x) then
				return x,y+3,'up'
			elseif self:sameFruit(y,x,y+2,x, y+3,x) then		
				return x,y,'down'
			elseif self:sameFruit(y,x,y+2,x, y+1,x-1) then
				return x-1,y+1,'right'
			elseif self:sameFruit(y,x,y+2,x, y+1,x+1) then
				return x+1,y+1,'left'
			elseif self:sameFruit(y,x,y+1,x, y+2,x-1) then
				return x-1,y+2,'right'
			elseif self:sameFruit(y,x,y+1,x, y-1,x-1) then
				return x-1,y-1,'right'
			elseif self:sameFruit(y,x,y+1,x, y+2,x+1) then
				return x+1,y+2,'left'
			elseif self:sameFruit(y,x,y+1,x, y-1,x+1) then
				return x+1,y-1,'left'
			end
		end
	end
	for y=1,8 do
		for x=1,8 do
			if self:sameFruit(y,x,y,x+1, y,x+3) then
				return x+3,y,'left'
			elseif self:sameFruit(y,x,y,x+2, y,x+3) then
				return x,y,'right'
			elseif self:sameFruit(y,x,y,x+2, y+1,x+1) then
				return x+1,y+1,'up'
			elseif self:sameFruit(y,x,y,x+2, y-1,x+1) then
				return x+1,y-1,'down'
			elseif self:sameFruit(y,x,y,x+1, y+1,x+2) then
				return x+2,y+1,'up'
			elseif self:sameFruit(y,x,y,x+1, y+1,x-1) then
				return x-1,y+1,'up'
			elseif self:sameFruit(y,x,y,x+1, y-1,x+2) then
				 return x+2,y-1,'down'
			elseif self:sameFruit(y,x,y,x+1, y-1,x-1) then
				return x-1,y-1,'down'
			end
		end
	end

	-- Oops no more matches (possibly), restart
	self:init()
end

function Board:getFruit(ty,tx)
	return self.fruits[ty] and self.fruits[ty][tx]
end

function Board:sameFruit(ty1,tx1,ty2,tx2,ty3,tx3)
	if ty3 then return self:sameFruit(ty1,tx1,ty2,tx2) and self:sameFruit(ty1,tx1,ty3,tx3) end
	return self:getFruit(ty1,tx1) and self:getFruit(ty2,tx2) and
		self.fruits[ty1][tx1].img==self.fruits[ty2][tx2].img
end

local checker={-2,-1,0,1,2}

-- The only point of this function is to check for match while initing!
function Board:checkMatch(tx,ty)
	for i=1,3 do
		if self:sameFruit(ty+checker[i],tx,  ty+checker[i+1],tx) and 
			self:sameFruit(ty+checker[i+1],tx, ty+checker[i+2],tx) then
			return true
		elseif self:sameFruit(ty,tx+checker[i],ty,  tx+checker[i+1]) and 
			self:sameFruit(ty,tx+checker[i+1],ty, tx+checker[i+2]) then
			return true
		end
	end
end


function Board:calculateMatchesHor()
	local scoreBoard=gStateMachine.current.scoreBoard
	local match
	local fruitToMatch,matchNum
	for y=1,8 do
		if not self.fruits[y][1] then break end
		fruitToMatch=self.fruits[y][1].img
		matchNum=1
		for x=2,8 do
			if not self.fruits[y][x] then break end
			if self.fruits[y][x].img==fruitToMatch then
				matchNum=matchNum+1
			else
				if matchNum>=3 then
					match={}
					for i=1,matchNum do
						local fruit=self.fruits[y][x-i]
						--if there is a neighbour push it (or push nil)
						local neighbour=fruit:isNeighbour('time') or 
							fruit:isNeighbour('milkshake') or
							fruit:isNeighbour('jam')

						if neighbour then

							print('this is working')
							if getFruitName(neighbour)=='time' then
								push(match,neighbour)
								scoreBoard.time=scoreBoard.time+neighbour.timeValue
							elseif getFruitName(neighbour)=='milkshake' then
								for i=1,8 do
									print(self.fruits[neighbour.ty][i])
									push(match,self.fruits[neighbour.ty][i])
								end
							end
						end
						push(match,fruit)
					end
					push(self.matches,match)
				end
				fruitToMatch=self.fruits[y][x].img
				matchNum=1
				if x>=7 then break end
			end
		end
		if matchNum>=3 then
			matches={}
			for i=1,matchNum do push(matches,self.fruits[y][9-i]) end
			push(self.matches,matches)
		end
	end
end


function Board:calculateMatchesVer()
	local match
	local fruitToMatch,matchNum
	for x=1,8 do
		if not self.fruits[1][x] then break end
		fruitToMatch=self.fruits[1][x].img
		matchNum=1
		for y=2,8 do
			if not self.fruits[y][x] then break end
			if self.fruits[y][x].img==fruitToMatch then
				matchNum=matchNum+1
			else
				if matchNum>=3 then
					match={}
					for i=1,matchNum do push(match,self.fruits[y-i][x]) end
					push(self.matches,match)
				end
				fruitToMatch=self.fruits[y][x].img
				matchNum=1
				if y>=7 then break end				
			end
		end
		if matchNum>=3 then
			matches={}
			for i=1,matchNum do push(matches,self.fruits[9-i][x]) end
			push(self.matches,matches)
		end
	end
end