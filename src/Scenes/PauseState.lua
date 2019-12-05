PauseState=State()

function PauseState:enter(params)
	self.guiSystem=params.guiSystem
	self.psystem=params.psystem
	self.board=params.board
	self.board.disabled=true
	self.scoreBoard=params.scoreBoard
	self.scoreBoard.disabled=true
	self.resumeBtn=lavis.imageButton(gImages.playBtn,330,100)
	self.resumeBtn:setShape('circle',90)
	self.resumeBtn:setImageOrigin(95,95)
	self.resumeBtn:setPosition(413,160)
	self.resumeBtn:setImagePosition(400,140)
	self.resumeBtn.onClick=function()
		self.scoreBoard.disabled=nil
		self.board.disabled=nil
		gStateMachine:switch('play',{
			board=self.board,
			scoreBoard=self.scoreBoard,
			guiSystem=self.guiSystem,
			psystem=self.psystem
		})
	end
	self.resumeBtn.onMouseEnter=function()
		self.resumeBtn:setSize(100)
	end
	self.resumeBtn.onMouseExit=function()
		self.resumeBtn:setSize(90)
	end
	self.audioBtn=lavis.imageButton(gImages.audioBtn,180,300)
	self.audioBtn:setSize(130,140)
	self.audioBtn:setImageOrigin(70,70)
	self.audioBtn.onClick=function()
		gSettings.playAudio=not gSettings.playAudio
		if not gSettings.playAudio then
			gSounds['music']:stop()
		else
			gSounds['music']:play()
		end
	end
	self.audioBtn.onMouseEnter=function()
		self.audioBtn:setSize(150,160)
	end
	self.audioBtn.onMouseExit=function()
		self.audioBtn:setSize(130,140)
	end
	self.exitBtn=lavis.imageButton(gImages.exitBtn,340,370)
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
	self.restartBtn=lavis.imageButton(gImages.restartBtn,500,300)
	self.restartBtn:setSize(140,140)
	self.restartBtn:setImageOrigin(70,70)
	self.restartBtn.onClick=function()
		gStateMachine:switch('play',{
			scoreBoard=ScoreBoard(
				self.scoreBoard.level,
				self.scoreBoard.targetScore,
				self.scoreBoard.initialTime
			),
			guiSystem=self.guiSystem,
			psystem=self.psystem
		})
	end
	self.restartBtn.onMouseEnter=function()
		self.restartBtn:setSize(160,160)
	end
	self.restartBtn.onMouseExit=function()
		self.restartBtn:setSize(140,140)
	end
end

function PauseState:update(dt)
	self.resumeBtn:update(dt)
	self.restartBtn:update(dt)
	self.exitBtn:update(dt)
	self.audioBtn:update(dt)
end

function PauseState:render()
	love.graphics.setColor(1,1,1,.5)
	love.graphics.draw(gImages.gameBackground)
	
	love.graphics.setColor(.3,.3,.3)
	love.graphics.draw(background,245,40,0,.765,.76)
	self.scoreBoard:render()
	self.board:draw()
	love.graphics.setColor(1,1,1)

	love.graphics.draw(gImages['lemonWindow'],400,300,0,.7,.7,581/2,584/2)
	self.resumeBtn:render()
	self.audioBtn:render()
	self.exitBtn:render()
	self.restartBtn:render()
end

function PauseState:mousePressed(...)
	self.resumeBtn:mousepressed(...)
	self.restartBtn:mousepressed(...)
	self.exitBtn:mousepressed(...)
	self.audioBtn:mousepressed(...)
end

function PauseState:mouseReleased(...)
	self.resumeBtn:mousereleased(...)
	self.restartBtn:mousereleased(...)
	self.exitBtn:mousereleased(...)
	self.audioBtn:mousereleased(...)
end

function PauseState:mouseMoved(...)
	self.resumeBtn:mousemoved(...)
	self.restartBtn:mousemoved(...)
	self.exitBtn:mousemoved(...)
	self.audioBtn:mousemoved(...)
end