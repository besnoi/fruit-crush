RoundOverState=State()

function RoundOverState:enter(params)
	self.guiSystem=params.guiSystem or GUISystem()
	self.scoreBoard=params.scoreBoard or ScoreBoard(params.level,params.time,params.target)
	self.scoreBoard.showRound=false
	self.text="Round: "..self.scoreBoard.level
	self.fontWidth=greenFont:getWidth(self.text)
	self.fontHeight=greenFont:getHeight()
	self.scale={s=.8,s2=.5,op=1}
	self:tween()
	self.tweenTimes=1
end

function RoundOverState:tween()
	if self.tweenTimes==4 then
		flux.tween(self.scale,1,{
			s=(self.scale.s==1 and .8 or 1),
			op=0,
			s2=0,
		}):ease('circinout'):oncomplete(function()
			self.scoreBoard.showRound=true
			gStateMachine:switch('play',{
				guiSystem=self.guiSystem,
				scoreBoard=self.scoreBoard
			})
		end)
		return
	end
	flux.tween(self.scale,1,{
		s=(self.scale.s==1 and .8 or 1),
		s2=(self.scale.s2==.8 and .5 or .8)
	}):ease('linear'):oncomplete(function()
		self.tweenTimes=self.tweenTimes+1
		self:tween()
	end)
end

function RoundOverState:update(dt)
	flux.update(dt)
end

function RoundOverState:render()
	love.graphics.draw(gImages.gameBackground)
	love.graphics.draw(background,245,40,0,.765,.76)
	self.scoreBoard:render()
	love.graphics.setFont(greenFont)
	-- love.graphics.print("Round:",424,259)
	love.graphics.draw(gImages['roundCompleteBack'],504,289,0,self.scale.s2,self.scale.s2,685/2,176/2)

	love.graphics.setColor(1,1,1,self.scale.op)
	love.graphics.printf(
		self.text,384,290,500,'center',0,
		self.scale.s,self.scale.s,
		self.fontWidth/2*self.scale.s,self.fontHeight/2*self.scale.s
	)
	love.graphics.setColor(1,1,1)
	self.guiSystem:render()
end