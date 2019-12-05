Fruit=Class()

local function getFruitScore(n)
	if n==7 then return 10
	else return 10+math.floor(n*2.5)
	end
end


function Fruit:init(tx,ty,x,y,n)
	self.tx,self.ty=tx,ty
	self.x,self.y=x,y
	self.img=tostring(n)
	-- Currently the powerups have some bugs so...	
	-- self.img=love.math.random(1,20)==1 and '9' or tostring(n)
	if self:getFruit()>7 then
		self.glowR=0
		Timer.every(.1,function()
			self.glowR=self.glowR+.1
		end)
		if getFruitName(self)=='time' then
			self.timeValue=love.math.random(1,20)
		end
	end
	self.score=getFruitScore(n)
	self.sx,self.sy=1,1
end

function Fruit:isHovered(mx,my)
	return euler.pointInRect(self.x,self.y,64,64,mx,my)
end

function Fruit:mousePressed(mouseX,mouseY,btn)
	if btn~=1 or self.dragging then return end
	if self:isHovered(mouseX,mouseY) then
		self.dragging=true
		self.pmouseX,self.pmouseY=self.x+32,self.y+32
	end
end

function oppositeDir(dir)
	if dir=='left' then return 'right'
	elseif dir=='right' then return 'left'
	elseif dir=='up' then return 'down'
	elseif dir=='down' then return 'up'
	else print('what the heck')
	end
end

function getFruitName(fruit)
	if fruit==nil then return end
	local id=fruit:getFruit()
	if id==1 then return 'apple'
	elseif id==2 then return 'guava'
	elseif id==3 then return 'orange'
	elseif id==4 then return 'pineapple'
	elseif id==5 then return 'grapes'
	elseif id==6 then return 'banana'
	elseif id==7 then return 'chocopie'
	elseif id==8 then return 'jam'
	elseif id==9 then return 'milkshake'
	elseif id==10 then return 'time'
	end
end

function Fruit:getPosition() return self.x,self.y end

function Fruit:getNeighbour(dir)
	local board=gStateMachine.current.board
	if dir=='left' or dir=='right' then
		if (dir=='left' and self.tx==1) or (dir=='right' and self.tx==8) then return end
		return board.fruits[self.ty][self.tx+(dir=='left' and -1 or 1)]
	elseif dir=='up' or dir=='down' then
		if (dir=='up' and self.ty==1) or (dir=='down' and self.ty==8) then return end
		return board.fruits[self.ty+(dir=='up' and -1 or 1)][self.tx]
	end
end

function Fruit:isNeighbour(fruit)
	return (
		(getFruitName(self:getNeighbour('left'))==fruit and self:getNeighbour('left')) or
		(getFruitName(self:getNeighbour('right'))==fruit and self:getNeighbour('right')) or
		(getFruitName(self:getNeighbour('up'))==fruit and self:getNeighbour('up')) or
		(getFruitName(self:getNeighbour('down'))==fruit and self:getNeighbour('down'))
	)
end

function Fruit:mouseMoved(mouseX,mouseY)
	local board=gStateMachine.current.board
	if not self.dragging then return end
	
	if euler.dif(mouseX,self.pmouseX)>32 then
		self.dragging=false
		if mouseX<self.pmouseX and self.tx>1  then	
			board:swapFruit(self,'left')
		elseif mouseX>self.pmouseX and self.tx<8 then
			board:swapFruit(self,'right')
		end

	elseif euler.dif(mouseY,self.pmouseY)>64 then
		self.dragging=false			
		if mouseY<self.pmouseY and self.ty>1  then	
			board:swapFruit(self,'up')
		elseif mouseY>self.pmouseY and self.ty<8 then
			board:swapFruit(self,'down')
		end
	end
	if not self.dragging then 
		playSound('exchange')
	end
end

function Fruit:mouseEnter()
	self.hoverTimer=0
	self.entered=true
end

function Fruit:mouseExit()
	self.hoverTimer=nil
	self.entered=false
end

function Fruit:whileHovered(dt)
	if not self.hoverTimer then return end
	self.hoverTimer=self.hoverTimer+dt
	if self.hoverTimer>2 then
		self:bounce()
		self.hoverTimer=0
	end
end

function Fruit:bounce()
	flux.to(self,.5,{
		sx=1.1,sy=.8
	})
	:ease('sinein')
	:after(self,.5,{
		sx=1,sy=1
	})
end

function Fruit:swap()
	local board=gStateMachine.current.board
	if not self.other then return end
	if not board:calculateMatches() then
		playSound('exchange')
		board:swapFruit(self,self.other)
		Timer.after(.2,function()
			self:bounce()
			self:getNeighbour(self.other):bounce()
			self.other=nil
		end)	
	else
		playSound('chew_'..random(1,4))			
		board:removeMatches()
		board:moveDownFruits()
	end
end

function Fruit:mouseReleased()
	self.dragging=false
	Timer.after(.2,function()
		self:swap()
	end)
end

function Fruit:getFruit()
	return tonumber(self.img)
end

function Fruit:render(disabled)
	local op=gStateMachine.current.board.op
	if self:getFruit()>7 then
		iffy.draw('atlas','glow',self.x+27,self.y+27,self.glowR,1,1,55,55)
		love.graphics.setColor(1,1,1,op-.1)
	end
	if disabled then love.graphics.setColor(.3,.3,.3) end
	iffy.draw('atlas',self.img,self.x+32,self.y+64,0,self.sx,self.sy,32,64)
	love.graphics.setColor(1,1,1,op)
end