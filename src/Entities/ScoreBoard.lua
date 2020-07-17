ScoreBoard=Class()

function ScoreBoard:init(level,time,target)
	if not level then return end
	self.x,self.y=15,260
	self.maxScoreQuads=euler.constrain(level*20,10,50)
	self.maxTimeQuads=euler.constrain(time,10,100)

	self.showRound=true
	self.level=level
	self.targetScore=target
	self.currentScore=0
	self.initialTime=time
	self.time=time

	self.scoreQuad=self:initProgressBar(self.maxScoreQuads)
	self.timeQuad=self:initProgressBar(self.maxTimeQuads)

	Timer.every(1,function() self:update() end)
end

function ScoreBoard:initProgressBar(n)
	--Make pieces (quads) of the progress bar
	local sw,sh=gImages.progressBarBlue:getDimensions()	
	local tbl={}
	for i=1,n do
		table.insert(
			tbl,
			love.graphics.newQuad(
				0,0,
				i==n and sw or euler.constrain((i-1)*sw/n,0,sw-1),
				sh,sw,sh
			)
		)
	end
	return tbl
end

function ScoreBoard:addScore(score)
	local Game=gStateMachine.current
	self.currentScore=euler.constrain(self.currentScore+score,0,self.targetScore)
	if self.currentScore==self.targetScore then
		if Game.win then Game:win() end
	end
end

function ScoreBoard:update()
	local Game=gStateMachine.current
	self.time=self.time-1
	if self.time<=0 then
		if Game.lose then Game:lose() end
	end
end

function ScoreBoard:renderProgressBar()
	love.graphics.draw(gImages['progressBar'],self.x+24,self.y+140)
	love.graphics.draw(
		gImages['progressBarBlue'],
		self.scoreQuad[
			euler.constrain(
				math.floor(
					euler.map(
						self.currentScore,0,self.targetScore,1,self.maxScoreQuads
					)
				),
				1,
				self.maxScoreQuads
			)
		],
		self.x+24,self.y+140
	)
	love.graphics.draw(gImages['progressBar'],self.x+24,self.y+240)
	love.graphics.draw(
		gImages['progressBarGreen'],
		self.timeQuad[
			euler.constrain(self.time,1,self.maxTimeQuads)
		],
		self.x+24,self.y+240
	)
end

function ScoreBoard:renderSeperators()
	if self.disabled then
		love.graphics.setColor(.3,.3,.3)
	else
		love.graphics.setColor(.85,.65,.35)
	end
	love.graphics.line(self.x+10,self.y+84,self.x+220,self.y+84)
	love.graphics.line(self.x+10,self.y+184,self.x+220,self.y+184)
	love.graphics.setColor(1,1,1)
end

function ScoreBoard:renderScoreText()
	love.graphics.push()
	love.graphics.setFont(whiteFont)
	love.graphics.scale(.5,.5)
	love.graphics.printf(
		self.currentScore..'/'..self.targetScore,
		self.x,self.y+745,650,'center'
	)
	love.graphics.setColor(1,1,1)	
	love.graphics.pop()	
end

function ScoreBoard:renderText()
	love.graphics.setFont(greenFont)
	love.graphics.push()
	love.graphics.scale(.8,.8)
	love.graphics.print("Hint",self.x+95,self.y-75)
	if self.showRound then
		love.graphics.print("Round:",self.x+55,self.y+100)
		love.graphics.print(self.level,self.x+225,self.y+100)
	end

	love.graphics.print("Score:",self.x+85,self.y+180)
	love.graphics.print("Time:",self.x+85,self.y+305)

	self:renderScoreText()
	love.graphics.pop()
	love.graphics.setFont(defaultFont)
end

function ScoreBoard:render()
	if not self.disabled and euler.pointInRect(self.x,self.y-130,gImages.hintWindow:getWidth(),gImages.hintWindow:getHeight(),love.mouse.getPosition()) then
		love.graphics.setColor(.8,.8,.8)
	end
	love.graphics.draw(gImages.hintWindow,self.x,self.y-130)
	if not self.disabled then
		love.graphics.setColor(1,1,1)
	end
	love.graphics.draw(gImages.scoreWindow,self.x,self.y)

	self:renderProgressBar()
	self:renderText()
	self:renderSeperators()	
end