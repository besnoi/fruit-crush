PlayState=State()

RobotCursor.setSpeed(1,1)

function PlayState:enter(params)
	self.scoreBoard=params.scoreBoard
	self.board=params.board or Board(264,59)
	self.psystem=params.psystem or ParticleSystem()
	self.guiSystem=params.guiSystem
	self.lastTimeMousePressed=0
	self.justMousePressed=false
end

function PlayState:pause()
	gStateMachine:switch('pause',{
		board=self.board,
		scoreBoard=self.scoreBoard,
		psystem=self.psystem,
		guiSystem=self.guiSystem
	})
end

function PlayState:update(dt)
	RobotCursor.update(dt)  --*Always* update RobotCursor first!!
	Timer.update(dt)
	flux.update(dt)
	if not self.dontUpdateBoard then
		self.board:update(dt)
	end
	self.psystem:update(dt)
	self.guiSystem:update(dt)
	-- mouseX,mouseY=love.mouse.getPosition()
	self.lastTimeMousePressed=self.lastTimeMousePressed+dt
	if self.lastTimeMousePressed>5 and self.hintDisabled then
		local x,y,dir=self.board:getHints()
		x,y=self.board.x+(x-1)*64,self.board.y+(y-1)*64
		self.psystem:newHintParticle(x,y,dir)
		self.hintDisabled=false
	end
end

function PlayState:keyPressed(key)
	if key=='escape' then
		love.event.quit()
	elseif key=='a' then
		--TODO: Add Smart-Pilot Mode
		AI_MODE=not self.board.tweening and not AI_MODE
		RobotCursor.currentStage=0
		RobotCursor.newStage()
	end
end

function PlayState:mousePressed(...)
	self.guiSystem:mousePressed(...)
	if self.lastTimeMousePressed<0.5 then return end
	self.lastTimeMousePressed=0
	self.justMousePressed=true
	self.board:mousePressed(...)
	self.hintDisabled=not self.board.tweening	
end

function PlayState:mouseReleased(...)
	self.guiSystem:mouseReleased(...)
	if not self.board.tweening and euler.pointInRect(self.scoreBoard.x,self.scoreBoard.y-130,gImages.hintWindow:getWidth(),gImages.hintWindow:getHeight(),love.mouse.getPosition()) then
		if self.hintDisabled then
			local x,y,dir=self.board:getHints()
			x,y=self.board.x+(x-1)*64,self.board.y+(y-1)*64
			self.psystem:newHintParticle(x,y,dir)
			self.hintDisabled=false
		end
	end
	if not self.justMousePressed then return end
	self.board:mouseReleased(...)
	self.justMousePressed=false
end

function PlayState:mouseMoved(...)
	self.guiSystem:mouseMoved(...)
	self.board:mouseMoved(...)
end

function PlayState:render()
	love.graphics.draw(gImages.gameBackground)
	love.graphics.draw(background,245,40,0,.765,.76)
	self.board:draw()
	self.psystem:render()
	self.scoreBoard:render()
	self.guiSystem:render()
	-- love.graphics.draw(gImages['lemonWindow'],200,100,0,.5,.5)
end

--custom made RC function
function RobotCursor.newStage()
	local srcX,srcY,dir=self.board:getHints()
	local destX,destY=self.board.fruits[srcY][srcX]:getNeighbour(dir):getPosition()
	srcX,srcY=self.board:getFruitPosition(srcX,srcY,32)
	RobotCursor.setStages({
		{
			toX=srcX,toY=srcY,clickDelay=0,clickBtn=1,stageDelay=.4,speedX=1,speedY=1
		},
		{
			toX=destX+27,toY=destY+27,speedX=2,speedY=2,
			releaseBtn=1
		}
	})
	-- Timer.after(2,RobotCursor.newStage)
	
end

function PlayState:win()
	local board=self.board
	self.dontUpdateBoard=true
	board.tweening=true
	flux.tween(board,2,{
		op=0
	}):oncomplete(function()
		gStateMachine:switch('roundOver',{
			level=self.scoreBoard.level+1,
			target=self.scoreBoard.targetScore+100,
			time=(self.scoreBoard.level-.6)*100
		})
	end)
end

function PlayState:lose()
	local board=self.board
	self.dontUpdateBoard=true
	board.tweening=true
	flux.tween(board,2,{
		op=0
	}):oncomplete(function()
		gStateMachine:switch('roundOver',{
			level=self.scoreBoard.level,
			target=self.scoreBoard.targetScore,
			time=self.scoreBoard.initialScore
		})
	end)
end