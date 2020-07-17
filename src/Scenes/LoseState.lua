LoseState=State()

function LoseState:enter(params)
	self.guiSystem=params.guiSystem
	self.psystem=params.psystem
	self.board=params.board
	self.board.disabled=true
	self.scoreBoard=params.scoreBoard
	self.scoreBoard.disabled=true
	
	self.restartBtn=lavis.imageButton(gImages.restartBtn,180+50,350)
	self.restartBtn:setSize(130,140)
	self.restartBtn:setImageOrigin(70,70)
	self.restartBtn.onClick=function()
		gStateMachine:change('roundOver',{
			level=1,
			target=100,
			time=60
		})
	end
	self.restartBtn.onMouseEnter=function()
		self.restartBtn:setSize(160,160)
	end
	self.restartBtn.onMouseExit=function()
		self.restartBtn:setSize(140,140)
	end
	
	self.exitBtn=lavis.imageButton(gImages.exitBtn,500-50,350)
	self.exitBtn:setSize(145,140)
	self.exitBtn:setImageOrigin(70,70)
	
	self.exitBtn.onClick=function()
		gStateMachine:change('mainMenu')
	end
	self.exitBtn.onMouseEnter=function()
		self.exitBtn:setSize(160,155)
	end
	self.exitBtn.onMouseExit=function()
		self.exitBtn:setSize(145,140)
	end
end

function LoseState:update(dt)
	self.restartBtn:update(dt)
	self.exitBtn:update(dt)
end

function LoseState:render()
	love.graphics.setColor(1,1,1,.5)
	love.graphics.draw(gImages.gameBackground)
	
	love.graphics.setColor(.3,.3,.3)
	love.graphics.draw(background,245,40,0,.765,.76)
	self.scoreBoard:render()
	-- self.board:draw()
	love.graphics.setColor(1,1,1)

	love.graphics.draw(gImages['lemonWindow'],400,300,0,.7,.7,581/2,584/2)
	self.exitBtn:render()
	self.restartBtn:render()

	love.graphics.setFont(whiteFont)
	love.graphics.push()
	love.graphics.scale(1.4,1.4)
	love.graphics.setColor(.9,.9,.9)
	love.graphics.print("You Lose!!",177,133)
	love.graphics.pop()
	love.graphics.setColor(1,1,1)
	love.graphics.setFont(defaultFont)
end

function LoseState:mousePressed(...)
	self.restartBtn:mousepressed(...)
	self.exitBtn:mousepressed(...)
end

function LoseState:mouseReleased(...)
	self.restartBtn:mousereleased(...)
	self.exitBtn:mousereleased(...)
end

function LoseState:mouseMoved(...)
	self.restartBtn:mousemoved(...)
	self.exitBtn:mousemoved(...)
end